import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/analytics/data/real_analytics_repository.dart';
import 'package:gym_app/features/analytics/domain/analytics_repository.dart';
import 'package:gym_app/features/analytics/domain/analytics_summary.dart';
import 'package:gym_app/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

void main() {
  late _MockAnalyticsRepository repository;
  late ProviderContainer container;

  const summary = AnalyticsSummary(
    activeMembers: ActiveMemberMetric(currentCount: 10, countThirtyDaysAgo: 8, trendPercentage: 25.0),
    classOccupancy: ClassOccupancyMetric(overallOccupancyRate: 0.5, classBreakdown: []),
    packageSales: PackageSalesMetric(totalCount: 4, categoryBreakdown: []),
    trainerActiveStudents: [],
  );

  setUp(() {
    repository = _MockAnalyticsRepository();
    container = ProviderContainer(overrides: [
      analyticsRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);
  });

  test('AnalyticsSummaryNotifier.build() loads the summary from the repository', () async {
    when(() => repository.getSummary()).thenAnswer((_) async => summary);

    final result = await container.read(analyticsSummaryProvider.future);

    expect(result.activeMembers.currentCount, 10);
    expect(result.packageSales.totalCount, 4);
    verify(() => repository.getSummary()).called(1);
  });

  test('AnalyticsSummaryNotifier.refresh() reloads the summary from the repository', () async {
    when(() => repository.getSummary()).thenAnswer((_) async => summary);
    await container.read(analyticsSummaryProvider.future);

    const refreshed = AnalyticsSummary(
      activeMembers: ActiveMemberMetric(currentCount: 11, countThirtyDaysAgo: 8, trendPercentage: 37.5),
      classOccupancy: ClassOccupancyMetric(overallOccupancyRate: 0.6, classBreakdown: []),
      packageSales: PackageSalesMetric(totalCount: 5, categoryBreakdown: []),
      trainerActiveStudents: [],
    );
    when(() => repository.getSummary()).thenAnswer((_) async => refreshed);

    await container.read(analyticsSummaryProvider.notifier).refresh();

    expect(container.read(analyticsSummaryProvider).value?.activeMembers.currentCount, 11);
    verify(() => repository.getSummary()).called(2);
  });

  test('AnalyticsSummaryNotifier surfaces a repository error as AsyncError', () async {
    when(() => repository.getSummary()).thenAnswer((_) async => throw Exception('boom'));
    // autoDispose bir provider'ı, kimse dinlemiyorken hemen dispose eder -
    // testin sonuna kadar canlı tutulması için bir listener ekleniyor.
    final subscription = container.listen(analyticsSummaryProvider, (_, _) {});
    addTearDown(subscription.close);

    AsyncValue<AnalyticsSummary> state = container.read(analyticsSummaryProvider);
    for (var i = 0; i < 20 && state.isLoading; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      state = container.read(analyticsSummaryProvider);
    }

    expect(state.hasError, isTrue);
  });
}
