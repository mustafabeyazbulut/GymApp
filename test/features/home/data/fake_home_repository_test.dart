import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/home/data/fake_home_repository.dart';

void main() {
  test('getHomeSummary returns a fixed mock summary with sane values', () async {
    final repository = FakeHomeRepository();

    final summary = await repository.getHomeSummary();

    expect(summary.greetingName, isNotEmpty);
    expect(summary.activePackageName, isNotEmpty);
    expect(summary.daysLeft, greaterThan(0));
    expect(summary.weeklyAttendance, hasLength(7));
    expect(summary.attendedCount, summary.weeklyAttendance.where((d) => d).length);
  });
}
