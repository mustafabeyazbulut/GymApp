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
    );

void main() {
  test('isSuperAdmin is true when any assignment is SuperAdmin', () {
    final me = _withAssignments([
      const MeAssignment(companyId: null, companyName: null, branchId: null, role: 'SuperAdmin'),
    ]);
    expect(me.isSuperAdmin, isTrue);
  });

  test('isSuperAdmin is false for a plain Member', () {
    final me = _withAssignments([
      const MeAssignment(companyId: 1, companyName: 'Co', branchId: 2, role: 'Member'),
    ]);
    expect(me.isSuperAdmin, isFalse);
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

  test('staffAssignment is null for a plain Member or Trainer', () {
    final me = _withAssignments([
      const MeAssignment(companyId: 1, companyName: 'Co', branchId: 2, role: 'Member'),
      const MeAssignment(companyId: 1, companyName: 'Co', branchId: 2, role: 'Trainer'),
    ]);
    expect(me.staffAssignment, isNull);
  });
}
