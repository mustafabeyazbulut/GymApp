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

const _gymAdminA = MeAssignment(companyId: 1, companyName: 'A', branchId: null, role: 'GymAdmin');
const _branchManagerB = MeAssignment(companyId: 2, companyName: 'B', branchId: 9, role: 'BranchManager');
const _superAdmin = MeAssignment(companyId: null, companyName: null, branchId: null, role: 'SuperAdmin');
const _trainer = MeAssignment(companyId: 1, companyName: 'A', branchId: 3, role: 'Trainer');

void main() {
  test('GymAdmin aktif firmada tüm personel yetkilerine sahip', () {
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
  });

  test('personel ataması olmayan SuperAdmin sadece firma yönetimini görür', () {
    final permissions = StaffPermissions.of(_withAssignments([_superAdmin]), null);

    expect(permissions.canManageCompanies, isTrue);
    expect(permissions.canViewBranches, isFalse);
    expect(permissions.canManageStaff, isFalse);
    expect(permissions.canManagePackages, isFalse);
    expect(permissions.canCreateClassSession, isFalse);
    expect(permissions.canManageDoorAccess, isFalse);
    expect(permissions.canViewGymReports, isFalse);
    expect(permissions.canUploadContent, isFalse);
  });

  test('SuperAdmin aynı zamanda bir firmada GymAdmin ise o firmanın yetkilerini de alır', () {
    final permissions = StaffPermissions.of(_withAssignments([_superAdmin, _gymAdminA]), null);

    expect(permissions.canManageCompanies, isTrue);
    expect(permissions.canManagePackages, isTrue);
    expect(permissions.canManageDoorAccess, isTrue);
  });

  test('rolsüz üye veya sadece antrenör hiçbir personel yetkisine sahip değil', () {
    for (final me in [_withAssignments(const []), _withAssignments([_trainer])]) {
      final permissions = StaffPermissions.of(me, null);
      expect(permissions.hasActiveStaffRole, isFalse);
      expect(permissions.canManageCompanies, isFalse);
      expect(permissions.canViewBranches, isFalse);
      expect(permissions.canManagePackages, isFalse);
      expect(permissions.canUploadContent, isFalse);
    }
  });

  test('kullanıcı henüz yüklenmediyse hiçbir yetki yok', () {
    final permissions = StaffPermissions.of(null, null);

    expect(permissions.hasActiveStaffRole, isFalse);
    expect(permissions.canManageCompanies, isFalse);
  });

  test('yetkiler aktif firmadaki role göre belirlenir', () {
    final me = _withAssignments([_gymAdminA, _branchManagerB]);

    expect(StaffPermissions.of(me, 1).canManageDoorAccess, isTrue);
    expect(StaffPermissions.of(me, 2).canManageDoorAccess, isFalse);
    expect(StaffPermissions.of(me, 2).isBranchManager, isTrue);
  });

  test('aktif firma hiçbir atamayla eşleşmezse hiçbir personel yetkisi yok', () {
    final permissions = StaffPermissions.of(_withAssignments([_gymAdminA]), 999);

    expect(permissions.activeAssignment, isNull);
    expect(permissions.canManagePackages, isFalse);
    expect(permissions.canViewBranches, isFalse);
  });

  test('GymAdmin firmadaki her şubeyi, BranchManager sadece kendi şubesini görür', () {
    final gymAdmin = StaffPermissions.of(_withAssignments([_gymAdminA]), null);
    final branchManager = StaffPermissions.of(_withAssignments([_branchManagerB]), null);
    final member = StaffPermissions.of(_withAssignments(const []), null);

    expect(gymAdmin.canSeeBranch(3), isTrue);
    expect(gymAdmin.canSeeBranch(9), isTrue);
    expect(branchManager.canSeeBranch(9), isTrue);
    expect(branchManager.canSeeBranch(3), isFalse);
    expect(member.canSeeBranch(9), isFalse);
  });
}
