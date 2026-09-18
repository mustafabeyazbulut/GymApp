import 'progress_summary.dart';

abstract interface class ProgressRepository {
  Future<List<ProgressNote>> getProgressNotes(int packageAssignmentId);

  Future<void> recordProgressNote({
    required int packageAssignmentId,
    required int techniqueScore,
    required int conditionScore,
    String? noteText,
  });
}
