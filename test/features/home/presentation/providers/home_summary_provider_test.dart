import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/home/data/fake_home_repository.dart';
import 'package:gym_app/features/home/domain/home_repository.dart';
import 'package:gym_app/features/home/domain/home_summary.dart';
import 'package:gym_app/features/home/presentation/providers/home_summary_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockHomeRepository extends Mock implements HomeRepository {}

void main() {
  test('loads the summary from the repository', () async {
    final repository = _MockHomeRepository();
    when(() => repository.getHomeSummary()).thenAnswer(
      (_) async => const HomeSummary(
        greetingName: 'Test',
        activePackageName: 'Test Paket',
        daysLeft: 5,
        nextClassName: 'Test Ders',
        nextClassTime: 'Yarın 10:00',
        nextClassTrainer: 'Test Eğitmen',
        weeklyAttendance: [true, false, false, false, false, false, false],
      ),
    );
    final container = ProviderContainer(
      overrides: [homeRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final summary = await container.read(homeSummaryProvider.future);

    expect(summary.greetingName, 'Test');
    expect(summary.daysLeft, 5);
  });
}
