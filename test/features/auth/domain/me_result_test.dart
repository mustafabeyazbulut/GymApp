import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/auth/domain/me_result.dart';

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

void main() {
  test('isSuperAdmin is true when any assignment is SuperAdmin', () {
    final me = _withAssignments([
      const MeAssignment(companyId: null, companyName: null, branchId: null, role: 'SuperAdmin'),
    ]);
    expect(me.isSuperAdmin, isTrue);
  });

  test('isSuperAdmin is false for a user without any assignment', () {
    final me = _withAssignments(const []);
    expect(me.isSuperAdmin, isFalse);
  });

  test('isTrainer is true when any assignment is Trainer', () {
    final me = _withAssignments([
      const MeAssignment(companyId: 1, companyName: 'Co', branchId: 2, role: 'Trainer'),
    ]);
    expect(me.isTrainer, isTrue);
  });

  test('isTrainer is false for a user without any assignment', () {
    final me = _withAssignments(const []);
    expect(me.isTrainer, isFalse);
  });

  test('staffAssignment returns the GymAdmin assignment', () {
    final gymAdmin = const MeAssignment(companyId: 1, companyName: 'Co', branchId: null, role: 'GymAdmin');
    final me = _withAssignments([gymAdmin]);
    expect(me.staffAssignment, same(gymAdmin));
  });

  test('staffAssignment returns the BranchManager assignment', () {
    final branchManager = const MeAssignment(companyId: 1, companyName: 'Co', branchId: 5, role: 'BranchManager');
    final me = _withAssignments([branchManager]);
    expect(me.staffAssignment, same(branchManager));
  });

  test('staffAssignment is null for a Trainer-only user', () {
    final me = _withAssignments([
      const MeAssignment(companyId: 1, companyName: 'Co', branchId: 2, role: 'Trainer'),
    ]);
    expect(me.staffAssignment, isNull);
  });

  test('staffAssignments returns every GymAdmin/BranchManager assignment across companies', () {
    final gymAdminA = const MeAssignment(companyId: 1, companyName: 'A', branchId: null, role: 'GymAdmin');
    final branchManagerB = const MeAssignment(companyId: 2, companyName: 'B', branchId: 9, role: 'BranchManager');
    final me = _withAssignments([
      gymAdminA,
      const MeAssignment(companyId: 1, companyName: 'A', branchId: 3, role: 'Trainer'),
      branchManagerB,
    ]);
    expect(me.staffAssignments, [gymAdminA, branchManagerB]);
  });

  test('staffAssignmentFor returns the assignment matching the given companyId', () {
    final companyA = const MeAssignment(companyId: 1, companyName: 'A', branchId: null, role: 'GymAdmin');
    final companyB = const MeAssignment(companyId: 2, companyName: 'B', branchId: 9, role: 'BranchManager');
    final me = _withAssignments([companyA, companyB]);

    expect(me.staffAssignmentFor(2), same(companyB));
  });

  test('staffAssignmentFor falls back to the first staff assignment when companyId is null', () {
    final companyA = const MeAssignment(companyId: 1, companyName: 'A', branchId: null, role: 'GymAdmin');
    final companyB = const MeAssignment(companyId: 2, companyName: 'B', branchId: 9, role: 'BranchManager');
    final me = _withAssignments([companyA, companyB]);

    expect(me.staffAssignmentFor(null), same(companyA));
  });

  // Backend aynı firmada GymAdmin+BranchManager'ı engelliyor; yine de iki
  // eşleşme gelirse daha geniş yetkili GymAdmin seçilmeli.
  test('staffAssignmentFor prefers GymAdmin when the same company has several staff assignments', () {
    final branchManager = const MeAssignment(companyId: 1, companyName: 'A', branchId: 9, role: 'BranchManager');
    final gymAdmin = const MeAssignment(companyId: 1, companyName: 'A', branchId: null, role: 'GymAdmin');
    final me = _withAssignments([branchManager, gymAdmin]);

    expect(me.staffAssignmentFor(1), same(gymAdmin));
  });

  // Eşleşmeyen bir aktif firma, ilk atamaya DÜŞMEMELİ - aksi halde kullanıcı
  // farkında olmadan yanlış gym bağlamında işlem yapabilir.
  test('staffAssignmentFor returns null when companyId matches none', () {
    final companyA = const MeAssignment(companyId: 1, companyName: 'A', branchId: null, role: 'GymAdmin');
    final me = _withAssignments([companyA]);

    expect(me.staffAssignmentFor(999), isNull);
  });

  test('staffAssignments is empty for a user without any assignment', () {
    final me = _withAssignments(const []);
    expect(me.staffAssignments, isEmpty);
  });

  test('MePackageAssignment.fromJson parses all fields including nullable ones', () {
    final assignment = MePackageAssignment.fromJson({
      'id': 20,
      'companyId': 3,
      'companyName': 'MAT & MOVE Kadıköy',
      'branchId': null,
      'packageId': 5,
      'packageName': '10 Seans',
      'price': 1500,
      'status': 'Active',
      'startDate': '2026-01-01T00:00:00',
      'endDate': null,
      'sessionCount': 10,
      'remainingSessions': 7,
    });

    expect(assignment.id, 20);
    expect(assignment.companyId, 3);
    expect(assignment.companyName, 'MAT & MOVE Kadıköy');
    expect(assignment.branchId, isNull);
    expect(assignment.packageName, '10 Seans');
    expect(assignment.price, 1500.0);
    expect(assignment.status, 'Active');
    expect(assignment.isFrozen, isFalse);
    expect(assignment.startDate, DateTime(2026, 1, 1));
    expect(assignment.endDate, isNull);
    expect(assignment.sessionCount, 10);
    expect(assignment.remainingSessions, 7);
  });

  test('MePackageAssignment.isFrozen is true when status is Frozen', () {
    final assignment = MePackageAssignment.fromJson({
      'id': 1,
      'companyId': 1,
      'companyName': 'Co',
      'branchId': null,
      'packageId': 1,
      'packageName': 'Paket',
      'price': 100,
      'status': 'Frozen',
      'startDate': '2026-01-01T00:00:00',
      'endDate': '2026-02-01T00:00:00',
      'sessionCount': null,
      'remainingSessions': null,
    });

    expect(assignment.isFrozen, isTrue);
  });
}
