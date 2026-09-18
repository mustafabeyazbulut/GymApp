import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/membership_context_provider.dart';
import '../../../classes/presentation/providers/class_providers.dart';
import '../../data/real_progress_repository.dart';
import '../../domain/progress_summary.dart';

part 'progress_summary_provider.g.dart';

@riverpod
Future<List<ProgressNote>> progressNotes(Ref ref, int packageAssignmentId) =>
    ref.watch(progressRepositoryProvider).getProgressNotes(packageAssignmentId);

// Ayrı bir ProgressRepository çağrısı yok - classesThisMonth/attendanceValue
// zaten Classes feature'ının gerçek CheckIn verisinden (bkz.
// classCheckInsProvider) hesaplanıyor, sadece notes gerçekten yeni bir ağ
// çağrısı (progressNotesProvider).
@riverpod
Future<ProgressSummary> progressSummary(Ref ref) async {
  final memberships = await ref.watch(membershipsProvider.future);
  if (memberships.isEmpty) {
    return const ProgressSummary(classesThisMonth: 0, attendanceValue: 0, notes: []);
  }

  final selectedId = ref.watch(selectedMembershipIdProvider);
  final selected = memberships.any((m) => m.id == selectedId)
      ? memberships.firstWhere((m) => m.id == selectedId)
      : memberships.first;

  final checkIns = await ref.watch(classCheckInsProvider(selected.id).future);
  final notes = await ref.watch(progressNotesProvider(selected.id).future);

  final now = DateTime.now();
  final classesThisMonth =
      checkIns.where((c) => c.checkedInAt.year == now.year && c.checkedInAt.month == now.month).length;

  // Home ekranının haftalık devam grafiğiyle aynı "son 7 gün" penceresi -
  // aynı gerçek veriden türetilen iki farklı gösterge birbirinden
  // sapmasın diye.
  final today = DateTime(now.year, now.month, now.day);
  final attendedLast7Days = List.generate(7, (i) {
    final day = today.subtract(Duration(days: 6 - i));
    return checkIns.any((c) =>
        c.checkedInAt.year == day.year && c.checkedInAt.month == day.month && c.checkedInAt.day == day.day);
  }).where((attended) => attended).length;

  return ProgressSummary(
    classesThisMonth: classesThisMonth,
    attendanceValue: attendedLast7Days / 7,
    notes: notes,
  );
}
