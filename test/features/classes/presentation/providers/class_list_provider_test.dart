import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/classes/data/fake_class_repository.dart';
import 'package:gym_app/features/classes/domain/class_repository.dart';
import 'package:gym_app/features/classes/domain/class_session.dart';
import 'package:gym_app/features/classes/presentation/providers/class_list_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockClassRepository extends Mock implements ClassRepository {}

void main() {
  late _MockClassRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _MockClassRepository();
    container = ProviderContainer(
      overrides: [classRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('build() loads sessions from the repository', () async {
    when(() => repository.getClassSessions()).thenAnswer(
      (_) async => const [
        ClassSession(
          id: 1,
          name: 'Test Ders',
          category: ClassCategory.bjj,
          timeRange: '10:00–11:00',
          trainerName: 'Test Eğitmen',
          capacity: 10,
          enrolledCount: 3,
        ),
      ],
    );

    final result = await container.read(classListProvider.future);

    expect(result, hasLength(1));
    expect(result.single.name, 'Test Ders');
  });

  test('reserveSpot calls the repository then refreshes the list', () async {
    when(() => repository.getClassSessions()).thenAnswer(
      (_) async => const [
        ClassSession(
          id: 1,
          name: 'Test Ders',
          category: ClassCategory.bjj,
          timeRange: '10:00–11:00',
          trainerName: 'Test Eğitmen',
          capacity: 10,
          enrolledCount: 3,
        ),
      ],
    );
    when(() => repository.reserveSpot(1)).thenAnswer((_) async {});

    await container.read(classListProvider.future);
    await container.read(classListProvider.notifier).reserveSpot(1);

    verify(() => repository.reserveSpot(1)).called(1);
    verify(() => repository.getClassSessions()).called(2);
  });
}
