import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/trainer_schedule/data/real_trainer_schedule_repository.dart';
import 'package:gym_app/features/trainer_schedule/domain/my_reservation.dart';
import 'package:gym_app/features/trainer_schedule/domain/trainer_schedule_repository.dart';
import 'package:gym_app/features/trainer_schedule/presentation/providers/my_reservations_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockTrainerScheduleRepository extends Mock implements TrainerScheduleRepository {}

void main() {
  late _MockTrainerScheduleRepository repository;
  late ProviderContainer container;

  final reservation = MyReservation(
    id: 1,
    packageAssignmentId: 10,
    memberFullName: 'Ayşe Yılmaz',
    companyId: 3,
    branchId: 10,
    scheduledAt: DateTime(2026, 1, 1),
    status: MyReservationStatus.booked,
  );

  setUp(() {
    repository = _MockTrainerScheduleRepository();
    container = ProviderContainer(overrides: [
      trainerScheduleRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);
  });

  test('build() loads reservations from the repository', () async {
    when(() => repository.getMyReservations()).thenAnswer((_) async => [reservation]);

    final result = await container.read(myReservationsProvider.future);

    expect(result.single.memberFullName, 'Ayşe Yılmaz');
  });

  test('checkIn calls the repository then refreshes', () async {
    when(() => repository.getMyReservations()).thenAnswer((_) async => [reservation]);
    when(() => repository.checkIn(1)).thenAnswer((_) async {});

    await container.read(myReservationsProvider.future);
    await container.read(myReservationsProvider.notifier).checkIn(1);

    verify(() => repository.checkIn(1)).called(1);
    verify(() => repository.getMyReservations()).called(2);
  });

  test('markNoShow calls the repository then refreshes', () async {
    when(() => repository.getMyReservations()).thenAnswer((_) async => [reservation]);
    when(() => repository.markNoShow(1)).thenAnswer((_) async {});

    await container.read(myReservationsProvider.future);
    await container.read(myReservationsProvider.notifier).markNoShow(1);

    verify(() => repository.markNoShow(1)).called(1);
    verify(() => repository.getMyReservations()).called(2);
  });

  test('cancel calls the repository then refreshes', () async {
    when(() => repository.getMyReservations()).thenAnswer((_) async => [reservation]);
    when(() => repository.cancel(1)).thenAnswer((_) async {});

    await container.read(myReservationsProvider.future);
    await container.read(myReservationsProvider.notifier).cancel(1);

    verify(() => repository.cancel(1)).called(1);
    verify(() => repository.getMyReservations()).called(2);
  });
}
