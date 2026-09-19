import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/real_analytics_repository.dart';
import '../../domain/analytics_summary.dart';

part 'analytics_providers.g.dart';

@riverpod
class AnalyticsSummaryNotifier extends _$AnalyticsSummaryNotifier {
  @override
  Future<AnalyticsSummary> build() => ref.watch(analyticsRepositoryProvider).getSummary();

  Future<void> refresh() async {
    final repository = ref.read(analyticsRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(repository.getSummary);
  }
}
