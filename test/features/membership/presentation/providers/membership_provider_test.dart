import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/membership/data/real_membership_repository.dart';
import 'package:gym_app/features/membership/domain/membership_repository.dart';
import 'package:gym_app/features/membership/domain/membership_summary.dart';
import 'package:gym_app/features/membership/presentation/providers/membership_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

void main() {
  late _MockMembershipRepository membershipRepository;
  late ProviderContainer container;

  setUp(() {
    membershipRepository = _MockMembershipRepository();
    container = ProviderContainer(overrides: [
      membershipRepositoryProvider.overrideWithValue(membershipRepository),
    ]);
    addTearDown(container.dispose);
  });

  test('membershipPayments delegates to the repository for the given id', () async {
    when(() => membershipRepository.getPayments(20)).thenAnswer((_) async => [
          PaymentHistoryEntry(date: DateTime(2026, 1, 1), amount: 1500),
        ]);

    final result = await container.read(membershipPaymentsProvider(20).future);

    expect(result, hasLength(1));
    expect(result.single.amount, 1500);
    verify(() => membershipRepository.getPayments(20)).called(1);
  });

  test('MembershipActions.requestFreeze calls the repository', () async {
    when(() => membershipRepository.requestFreeze(20)).thenAnswer((_) async {});

    await container.read(membershipActionsProvider.notifier).requestFreeze(20);

    verify(() => membershipRepository.requestFreeze(20)).called(1);
  });

  test('MembershipActions.requestUnfreeze calls the repository', () async {
    when(() => membershipRepository.requestUnfreeze(20)).thenAnswer((_) async {});

    await container.read(membershipActionsProvider.notifier).requestUnfreeze(20);

    verify(() => membershipRepository.requestUnfreeze(20)).called(1);
  });
}
