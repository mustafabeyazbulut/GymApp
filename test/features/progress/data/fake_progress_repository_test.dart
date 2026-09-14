import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/progress/data/fake_progress_repository.dart';
import 'package:gym_app/features/progress/domain/progress_summary.dart';

void main() {
  test('getProgress returns different data for bjj and fitness categories', () async {
    final repository = FakeProgressRepository();

    final bjj = await repository.getProgress(ProgressCategory.bjj);
    final fitness = await repository.getProgress(ProgressCategory.fitness);

    expect(bjj.achievementTitle, isNot(equals(fitness.achievementTitle)));
    expect(bjj.techniqueValue, inInclusiveRange(0.0, 1.0));
    expect(fitness.techniqueValue, inInclusiveRange(0.0, 1.0));
  });
}
