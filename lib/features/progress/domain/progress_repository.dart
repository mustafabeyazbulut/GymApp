import 'progress_summary.dart';

abstract interface class ProgressRepository {
  Future<ProgressSummary> getProgress(ProgressCategory category);
}
