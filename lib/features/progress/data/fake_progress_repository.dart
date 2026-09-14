import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/progress_repository.dart';
import '../domain/progress_summary.dart';

part 'fake_progress_repository.g.dart';

class FakeProgressRepository implements ProgressRepository {
  static const _bjj = ProgressSummary(
    achievementTitle: 'Beyaz Kuşak · 2. derece',
    achievementQuote: 'Yolculuk kuşakla değil, çabayla ölçülür.',
    classesThisMonth: 11,
    techniqueValue: 0.65,
    attendanceValue: 0.80,
    conditionValue: 0.50,
    trainerNoteText: 'Guard geçişlerinde belirgin ilerleme.',
    trainerNoteAuthor: 'Mert Demir',
    trainerNoteDate: '22.09.2026',
  );

  static const _fitness = ProgressSummary(
    achievementTitle: 'Kondisyon Seviyesi: Orta',
    achievementQuote: 'Küçük adımlar, büyük değişim.',
    classesThisMonth: 9,
    techniqueValue: 0.55,
    attendanceValue: 0.70,
    conditionValue: 0.75,
    trainerNoteText: 'Squat formunda gözle görülür gelişim.',
    trainerNoteAuthor: 'Selin Kaya',
    trainerNoteDate: '20.09.2026',
  );

  @override
  Future<ProgressSummary> getProgress(ProgressCategory category) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return category == ProgressCategory.bjj ? _bjj : _fitness;
  }
}

@riverpod
ProgressRepository progressRepository(Ref ref) => FakeProgressRepository();
