import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/auth/domain/me_result.dart';
import 'package:gym_app/features/auth/domain/staff_permissions.dart';

MeResult _withAssignments(List<MeAssignment> assignments) => MeResult(
      id: 1,
      fullName: 'Test',
      phone: '+905550000000',
      email: null,
      preferredLanguage: 'tr',
      isAccountFrozen: false,
      assignments: assignments,
      packageAssignments: const [],
    );

const _gymAdminA = MeAssignment(id: 1, companyId: 1, companyName: 'A', branchId: null, role: 'GymAdmin');
const _branchManagerB = MeAssignment(id: 2, companyId: 2, companyName: 'B', branchId: 9, role: 'BranchManager');
const _superAdmin = MeAssignment(id: 3, companyId: null, companyName: null, branchId: null, role: 'SuperAdmin');
const _trainerA = MeAssignment(id: 4, companyId: 1, companyName: 'A', branchId: 3, role: 'Trainer');

void _expectNoGymOperations(StaffPermissions permissions) {
  expect(permissions.hasManagementRole, isFalse);
  expect(permissions.canViewBranches, isFalse);
  expect(permissions.canManageStaff, isFalse);
  expect(permissions.canManagePackages, isFalse);
  expect(permissions.canCreateClassSession, isFalse);
  expect(permissions.canManageDoorAccess, isFalse);
  expect(permissions.canViewGymReports, isFalse);
  expect(permissions.canUploadContent, isFalse);
}

void main() {
  test('GymAdmin aktif görevde tüm personel yetkilerine sahip', () {
    final permissions = StaffPermissions.of(_withAssignments([_gymAdminA]), null);

    expect(permissions.isGymAdmin, isTrue);
    expect(permissions.canViewBranches, isTrue);
    expect(permissions.canManageBranches, isTrue);
    expect(permissions.canManageStaff, isTrue);
    expect(permissions.canAssignBranchManager, isTrue);
    expect(permissions.canManagePackages, isTrue);
    expect(permissions.canCreateClassSession, isTrue);
    expect(permissions.canManageDoorAccess, isTrue);
    expect(permissions.canViewGymReports, isTrue);
    expect(permissions.canUploadContent, isTrue);
    expect(permissions.canManageCompanies, isFalse);
    expect(permissions.canViewTrainerSchedule, isFalse);
  });

  test('BranchManager kapı erişimi, şube yönetimi ve şube müdürü atamasını göremez', () {
    final permissions = StaffPermissions.of(_withAssignments([_branchManagerB]), null);

    expect(permissions.isBranchManager, isTrue);
    expect(permissions.canViewBranches, isTrue);
    expect(permissions.canManageBranches, isFalse);
    expect(permissions.canManageStaff, isTrue);
    expect(permissions.canAssignBranchManager, isFalse);
    expect(permissions.canManagePackages, isTrue);
    expect(permissions.canCreateClassSession, isTrue);
    expect(permissions.canManageDoorAccess, isFalse);
    expect(permissions.canViewGymReports, isTrue);
    expect(permissions.canUploadContent, isTrue);
    expect(permissions.canViewTrainerSchedule, isFalse);
  });

  // Aktif görev Trainer iken backend yönetim uçlarında 403 döner.
  test('aktif görev Trainer ise sadece antrenör programı açılır', () {
    final permissions = StaffPermissions.of(_withAssignments([_trainerA]), null);

    expect(permissions.isTrainer, isTrue);
    expect(permissions.canViewTrainerSchedule, isTrue);
    expect(permissions.canManageCompanies, isFalse);
    _expectNoGymOperations(permissions);
  });

  test('antrenör programı sadece aktif görev Trainer iken görünür', () {
    final me = _withAssignments([_gymAdminA, _trainerA]);

    // Varsayılan GymAdmin - başka bir görevdeki antrenörlük programı açmaz.
    expect(StaffPermissions.of(me, null).canViewTrainerSchedule, isFalse);
    expect(StaffPermissions.of(me, _trainerA.id).canViewTrainerSchedule, isTrue);
    expect(StaffPermissions.of(me, _trainerA.id).canManagePackages, isFalse);
  });

  test('personel ataması olmayan SuperAdmin sadece firma yönetimini görür', () {
    final permissions = StaffPermissions.of(_withAssignments([_superAdmin]), null);

    expect(permissions.isSuperAdmin, isTrue);
    expect(permissions.canManageCompanies, isTrue);
    expect(permissions.canViewTrainerSchedule, isFalse);
    _expectNoGymOperations(permissions);
  });

  test('SuperAdmin + GymAdmin: varsayılan Sistem Sahibi, GymAdmin seçilince sadece o firmanın yetkileri', () {
    final me = _withAssignments([_superAdmin, _gymAdminA]);

    final asSystemOwner = StaffPermissions.of(me, null);
    expect(asSystemOwner.canManageCompanies, isTrue);
    _expectNoGymOperations(asSystemOwner);

    final asGymAdmin = StaffPermissions.of(me, _gymAdminA.id);
    expect(asGymAdmin.canManageCompanies, isFalse);
    expect(asGymAdmin.isSuperAdmin, isFalse);
    expect(asGymAdmin.canManagePackages, isTrue);
    expect(asGymAdmin.canManageDoorAccess, isTrue);

    expect(StaffPermissions.of(me, _superAdmin.id).canManageCompanies, isTrue);
  });

  test('rolsüz üye hiçbir personel yetkisine sahip değil', () {
    final permissions = StaffPermissions.of(_withAssignments(const []), null);

    expect(permissions.activeAssignment, isNull);
    expect(permissions.canManageCompanies, isFalse);
    expect(permissions.canViewTrainerSchedule, isFalse);
    _expectNoGymOperations(permissions);
  });

  test('kullanıcı henüz yüklenmediyse hiçbir yetki yok', () {
    final permissions = StaffPermissions.of(null, null);

    expect(permissions.hasManagementRole, isFalse);
    expect(permissions.canManageCompanies, isFalse);
  });

  test('yetkiler seçili göreve göre belirlenir', () {
    final me = _withAssignments([_gymAdminA, _branchManagerB]);

    expect(StaffPermissions.of(me, _gymAdminA.id).canManageDoorAccess, isTrue);
    expect(StaffPermissions.of(me, _branchManagerB.id).canManageDoorAccess, isFalse);
    expect(StaffPermissions.of(me, _branchManagerB.id).isBranchManager, isTrue);
  });

  test('seçili görev geçersizse varsayılan kurala döner', () {
    final permissions = StaffPermissions.of(_withAssignments([_trainerA, _branchManagerB]), 999);

    expect(permissions.activeAssignment, same(_branchManagerB));
  });

  test('GymAdmin firmadaki her şubeyi, BranchManager ve Trainer sadece kendi şubesini görür', () {
    final gymAdmin = StaffPermissions.of(_withAssignments([_gymAdminA]), null);
    final branchManager = StaffPermissions.of(_withAssignments([_branchManagerB]), null);
    final trainer = StaffPermissions.of(_withAssignments([_trainerA]), null);
    final member = StaffPermissions.of(_withAssignments(const []), null);

    expect(gymAdmin.canSeeBranch(3), isTrue);
    expect(gymAdmin.canSeeBranch(9), isTrue);
    expect(branchManager.canSeeBranch(9), isTrue);
    expect(branchManager.canSeeBranch(3), isFalse);
    expect(trainer.canSeeBranch(3), isTrue);
    expect(trainer.canSeeBranch(9), isFalse);
    expect(member.canSeeBranch(9), isFalse);
  });

  test('sabit şube: BranchManager kendi şubesi, GymAdmin için yok', () {
    expect(StaffPermissions.of(_withAssignments([_branchManagerB]), null).fixedBranchId, 9);
    expect(StaffPermissions.of(_withAssignments([_gymAdminA]), null).fixedBranchId, isNull);
  });
}
