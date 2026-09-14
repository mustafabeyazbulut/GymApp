import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/fake_progress_repository.dart';
import '../../domain/progress_summary.dart';

part 'progress_summary_provider.g.dart';

@riverpod
Future<ProgressSummary> progressSummary(Ref ref, ProgressCategory category) {
  return ref.watch(progressRepositoryProvider).getProgress(category);
}
