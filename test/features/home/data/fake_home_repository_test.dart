import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/home/data/fake_home_repository.dart';

void main() {
  test('getHomeSummary returns the exact fixed mock summary', () async {
    final repository = FakeHomeRepository();

    final summary = await repository.getHomeSummary();

    expect(summary.greetingName, 'Elnara');
    expect(summary.activePackageName, 'BJJ + Fitness');
    expect(summary.daysLeft, 18);
    expect(summary.nextClassName, 'BJJ Temel');
    expect(summary.nextClassTime, 'Bugün 19:00');
    expect(summary.nextClassTrainer, 'Mert Demir');
    expect(summary.weeklyAttendance, const [
      ('Pzt', true), ('Sal', true), ('Çar', false), ('Per', true),
      ('Cum', false), ('Cmt', true), ('Paz', false),
    ]);
    expect(summary.attendedCount, 4);
  });
}
