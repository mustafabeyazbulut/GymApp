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

  test('MeAssignment.fromJson id ve branchName alanlarını okur', () {
    final assignment = MeAssignment.fromJson({
      'id': 42,
      'companyId': 1,
      'companyName': 'Test Gym',
      'branchId': 7,
      'branchName': 'Kadıköy',
      'role': 'BranchManager',
    });

    expect(assignment.id, 42);
    expect(assignment.branchName, 'Kadıköy');
  });

  // Backend id/branchName'i henüz göndermiyorsa (eski sürüm) ayrıştırma
  // patlamamalı.
  test('MeAssignment.fromJson id ve branchName yoksa null döner', () {
    final assignment = MeAssignment.fromJson({
      'companyId': 1,
      'companyName': 'Test Gym',
      'branchId': null,
      'role': 'GymAdmin',
    });

    expect(assignment.id, isNull);
    expect(assignment.branchName, isNull);
  });

  test('staffAssignments Trainer dahil tüm personel atamalarını döner, SuperAdmin hariç', () {
    const gymAdminA = MeAssignment(id: 1, companyId: 1, companyName: 'A', branchId: null, role: 'GymAdmin');
    const trainerA = MeAssignment(id: 2, companyId: 1, companyName: 'A', branchId: 3, role: 'Trainer');
    const branchManagerB = MeAssignment(id: 3, companyId: 2, companyName: 'B', branchId: 9, role: 'BranchManager');
    final me = _withAssignments([
      const MeAssignment(id: 4, companyId: null, companyName: null, branchId: null, role: 'SuperAdmin'),
      gymAdminA,
      trainerA,
      branchManagerB,
    ]);

    expect(me.staffAssignments, [gymAdminA, trainerA, branchManagerB]);
  });

  test('staffAssignments personel ataması olmayan kullanıcı için boş', () {
    expect(_withAssignments(const []).staffAssignments, isEmpty);
  });

  test('selectableContexts Sistem Sahibi\'ni en üstte, ardından personel görevlerini döner', () {
    const superAdmin = MeAssignment(id: 4, companyId: null, companyName: null, branchId: null, role: 'SuperAdmin');
    const gymAdminA = MeAssignment(id: 1, companyId: 1, companyName: 'A', branchId: null, role: 'GymAdmin');
    final me = _withAssignments([gymAdminA, superAdmin]);

    expect(me.selectableContexts, [superAdmin, gymAdminA]);
    expect(me.staffAssignments, [gymAdminA]);
  });

  group('defaultActiveAssignment', () {
    test('tek atama varsa onu seçer (Trainer dahil)', () {
      const trainer = MeAssignment(id: 5, companyId: 1, companyName: 'A', branchId: 3, role: 'Trainer');
      expect(_withAssignments([trainer]).defaultActiveAssignment, same(trainer));
    });

    test('GymAdmin > BranchManager > Trainer önceliğini uygular', () {
      const trainer = MeAssignment(id: 1, companyId: 1, companyName: 'A', branchId: 3, role: 'Trainer');
      const branchManager = MeAssignment(id: 2, companyId: 2, companyName: 'B', branchId: 9, role: 'BranchManager');
      const gymAdmin = MeAssignment(id: 3, companyId: 3, companyName: 'C', branchId: null, role: 'GymAdmin');

      expect(_withAssignments([trainer, branchManager, gymAdmin]).defaultActiveAssignment, same(gymAdmin));
      expect(_withAssignments([trainer, branchManager]).defaultActiveAssignment, same(branchManager));
    });

    test('SuperAdmin için varsayılan Sistem Sahibi\'dir', () {
      const gymAdmin = MeAssignment(id: 1, companyId: 3, companyName: 'C', branchId: null, role: 'GymAdmin');
      const superAdmin = MeAssignment(id: 9, companyId: null, companyName: null, branchId: null, role: 'SuperAdmin');

      expect(_withAssignments([gymAdmin, superAdmin]).defaultActiveAssignment, same(superAdmin));
    });

    test('aynı rolde en küçük Id seçilir', () {
      const kadikoy = MeAssignment(id: 12, companyId: 1, companyName: 'A', branchId: 3, role: 'BranchManager');
      const besiktas = MeAssignment(id: 8, companyId: 1, companyName: 'A', branchId: 4, role: 'BranchManager');

      expect(_withAssignments([kadikoy, besiktas]).defaultActiveAssignment, same(besiktas));
    });

    test('id gelmeyen atamalar id taşıyanlardan sonra gelir', () {
      const withoutId = MeAssignment(companyId: 1, companyName: 'A', branchId: 3, role: 'Trainer');
      const withId = MeAssignment(id: 99, companyId: 2, companyName: 'B', branchId: 4, role: 'Trainer');

      expect(_withAssignments([withoutId, withId]).defaultActiveAssignment, same(withId));
    });

    test('hiç görev yoksa null', () {
      expect(_withAssignments(const []).defaultActiveAssignment, isNull);
    });
  });

  group('activeAssignment', () {
    const trainerA = MeAssignment(id: 1, companyId: 1, companyName: 'A', branchId: 3, role: 'Trainer');
    const branchManagerB = MeAssignment(id: 2, companyId: 2, companyName: 'B', branchId: 9, role: 'BranchManager');

    test('seçilen Id görevlerden biriyse onu döner', () {
      expect(_withAssignments([trainerA, branchManagerB]).activeAssignment(1), same(trainerA));
    });

    test('seçim yoksa varsayılan kuralı uygular', () {
      expect(_withAssignments([trainerA, branchManagerB]).activeAssignment(null), same(branchManagerB));
    });

    // Atama kaldırıldıysa veya cihazda başka bir kullanıcının seçimi kaldıysa
    // aynı kuralla yeniden seçilir.
    test('seçilen Id artık geçerli değilse varsayılan kurala döner', () {
      expect(_withAssignments([trainerA, branchManagerB]).activeAssignment(999), same(branchManagerB));
    });

    test('SuperAdmin personel görevini seçebilir ve Sistem Sahibi\'ne geri dönebilir', () {
      const superAdmin = MeAssignment(id: 7, companyId: null, companyName: null, branchId: null, role: 'SuperAdmin');
      final me = _withAssignments([superAdmin, branchManagerB]);

      expect(me.activeAssignment(2), same(branchManagerB));
      expect(me.activeAssignment(7), same(superAdmin));
    });
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
