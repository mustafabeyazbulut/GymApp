import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/progress/data/fake_progress_repository.dart';
import 'package:gym_app/features/progress/domain/progress_summary.dart';

void main() {
  test('getProgress returns different data for bjj and fitness categories', () async {
    final repository = FakeProgressRepository();

    final bjj = await repository.getProgress(ProgressCategory.bjj);
    final fitness = await repository.getProgress(ProgressCategory.fitness);

    expect(bjj.achievementTitle, 'Beyaz Kuşak · 2. derece');
    expect(bjj.achievementQuote, 'Yolculuk kuşakla değil, çabayla ölçülür.');
    expect(bjj.classesThisMonth, 11);
    expect(bjj.techniqueValue, 0.65);
    expect(bjj.attendanceValue, 0.80);
    expect(bjj.conditionValue, 0.50);
    expect(bjj.trainerNoteText, 'Guard geçişlerinde belirgin ilerleme.');
    expect(bjj.trainerNoteAuthor, 'Mert Demir');
    expect(bjj.trainerNoteDate, '22.09.2026');

    expect(fitness.achievementTitle, 'Kondisyon Seviyesi: Orta');
    expect(fitness.achievementQuote, 'Küçük adımlar, büyük değişim.');
    expect(fitness.classesThisMonth, 9);
    expect(fitness.techniqueValue, 0.55);
    expect(fitness.attendanceValue, 0.70);
    expect(fitness.conditionValue, 0.75);
    expect(fitness.trainerNoteText, 'Squat formunda gözle görülür gelişim.');
    expect(fitness.trainerNoteAuthor, 'Selin Kaya');
    expect(fitness.trainerNoteDate, '20.09.2026');
  });
}
