import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/membership/data/fake_membership_repository.dart';
import 'package:gym_app/features/membership/domain/membership_repository.dart';
import 'package:gym_app/features/membership/domain/membership_summary.dart';
import 'package:gym_app/features/membership/presentation/providers/membership_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

void main() {
  late _MockMembershipRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _MockMembershipRepository();
    container = ProviderContainer(
      overrides: [membershipRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  const activeSummary = MembershipSummary(
    packageName: 'Test Paket',
    status: MembershipStatus.active,
    startDate: '01.01.2026',
    endDate: '31.01.2026',
    price: '₺1.000',
    isPaid: true,
    paymentHistory: [],
  );

  test('build() loads the membership from the repository', () async {
    when(() => repository.getMembership()).thenAnswer((_) async => activeSummary);

    final summary = await container.read(membershipProvider.future);

    expect(summary.packageName, 'Test Paket');
  });

  test('requestFreeze calls the repository then refreshes', () async {
    when(() => repository.getMembership()).thenAnswer((_) async => activeSummary);
    when(() => repository.requestFreeze()).thenAnswer((_) async {});

    await container.read(membershipProvider.future);
    await container.read(membershipProvider.notifier).requestFreeze();

    verify(() => repository.requestFreeze()).called(1);
    verify(() => repository.getMembership()).called(2);
  });
}
