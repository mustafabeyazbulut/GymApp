import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/providers/membership_context_provider.dart';
import 'package:gym_app/features/auth/data/real_auth_repository.dart';
import 'package:gym_app/features/auth/domain/auth_repository.dart';
import 'package:gym_app/features/auth/domain/me_result.dart';
import 'package:gym_app/features/membership/domain/membership_summary.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository authRepository;
  late ProviderContainer container;

  MeResult meWithAssignments(List<MePackageAssignment> packageAssignments) => MeResult(
        id: 1,
        fullName: 'Ayşe',
        phone: '+905551112233',
        email: null,
        preferredLanguage: 'tr',
        isAccountFrozen: false,
        assignments: const [],
        packageAssignments: packageAssignments,
      );

  final assignmentA = MePackageAssignment.fromJson({
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

  final assignmentB = MePackageAssignment.fromJson({
    'id': 21,
    'companyId': 4,
    'companyName': 'MAT & MOVE Beşiktaş',
    'branchId': null,
    'packageId': 6,
    'packageName': 'Aylık Üyelik',
    'price': 2000,
    'status': 'Frozen',
    'startDate': '2026-02-01T00:00:00',
    'endDate': '2026-03-01T00:00:00',
    'sessionCount': null,
    'remainingSessions': null,
  });

  setUp(() {
    authRepository = _MockAuthRepository();
    container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(authRepository),
    ]);
    addTearDown(container.dispose);
  });

  test('memberships maps every PackageAssignment from currentUserProvider', () async {
    when(() => authRepository.getMe()).thenAnswer((_) async => meWithAssignments([assignmentA, assignmentB]));

    final result = await container.read(membershipsProvider.future);

    expect(result, hasLength(2));
    expect(result[0].id, 20);
    expect(result[0].companyName, 'MAT & MOVE Kadıköy');
    expect(result[0].status, MembershipStatus.active);
    expect(result[0].remainingSessions, 7);
    expect(result[1].id, 21);
    expect(result[1].status, MembershipStatus.frozen);
  });

  test('memberships is empty when the user has no PackageAssignment', () async {
    when(() => authRepository.getMe()).thenAnswer((_) async => meWithAssignments([]));

    final result = await container.read(membershipsProvider.future);

    expect(result, isEmpty);
  });

  test('selectedMembershipId defaults to null and updates on select', () {
    expect(container.read(selectedMembershipIdProvider), isNull);

    container.read(selectedMembershipIdProvider.notifier).select(21);

    expect(container.read(selectedMembershipIdProvider), 21);
  });
}
