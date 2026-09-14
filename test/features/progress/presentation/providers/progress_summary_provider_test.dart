import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/progress/data/fake_progress_repository.dart';
import 'package:gym_app/features/progress/domain/progress_repository.dart';
import 'package:gym_app/features/progress/domain/progress_summary.dart';
import 'package:gym_app/features/progress/presentation/providers/progress_summary_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockProgressRepository extends Mock implements ProgressRepository {}

void main() {
  test('loads the summary for the requested category from the repository', () async {
    final repository = _MockProgressRepository();
    when(() => repository.getProgress(ProgressCategory.fitness)).thenAnswer(
      (_) async => const ProgressSummary(
        achievementTitle: 'Test Başlık',
        achievementQuote: 'Test Alıntı',
        classesThisMonth: 4,
        techniqueValue: 0.3,
        attendanceValue: 0.4,
        conditionValue: 0.5,
        trainerNoteText: 'Test Not',
        trainerNoteAuthor: 'Test Eğitmen',
        trainerNoteDate: '01.01.2026',
      ),
    );
    final container = ProviderContainer(
      overrides: [progressRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final summary = await container.read(progressSummaryProvider(ProgressCategory.fitness).future);

    expect(summary.achievementTitle, 'Test Başlık');
    expect(summary.classesThisMonth, 4);
  });
}
