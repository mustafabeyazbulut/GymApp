import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/auth/data/real_auth_repository.dart';
import 'package:gym_app/features/auth/domain/auth_repository.dart';
import 'package:gym_app/features/auth/domain/me_result.dart';
import 'package:gym_app/features/classes/data/real_class_repository.dart';
import 'package:gym_app/features/classes/domain/class_repository.dart';
import 'package:gym_app/features/classes/domain/reservation.dart';
import 'package:gym_app/features/classes/domain/trainer.dart';
import 'package:gym_app/features/classes/presentation/providers/class_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockClassRepository extends Mock implements ClassRepository {}

void main() {
  late _MockAuthRepository authRepository;
  late _MockClassRepository classRepository;
  late ProviderContainer container;

  final assignment = MePackageAssignment.fromJson({
    'id': 20,
    'companyId': 3,
    'companyName': 'MAT & MOVE Kadıköy',
    'branchId': null,
    'packageId': 5,
    'packageName': '10 Seans',
    'price': 1500,
    'status': 'Active',
    'startDate': '2026-01-01T00:00:00',
    'endDate': null,
    'sessionCount': 10,
    'remainingSessions': 7,
  });

  setUp(() {
    authRepository = _MockAuthRepository();
    classRepository = _MockClassRepository();
    container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(authRepository),
      classRepositoryProvider.overrideWithValue(classRepository),
    ]);
    addTearDown(container.dispose);

    when(() => authRepository.getMe()).thenAnswer((_) async => MeResult(
          id: 1,
          fullName: 'Ayşe',
          phone: '+905551112233',
          email: null,
          preferredLanguage: 'tr',
          isAccountFrozen: false,
          assignments: const [],
          packageAssignments: [assignment],
        ));
  });

  test('classTrainers delegates to the repository for the given id', () async {
    when(() => classRepository.getTrainers(20))
        .thenAnswer((_) async => [const Trainer(id: 99, fullName: 'Ali Antrenör', branchId: null)]);

    final result = await container.read(classTrainersProvider(20).future);

    expect(result.single.fullName, 'Ali Antrenör');
  });

  test('classCheckIns delegates to the repository for the given id', () async {
    when(() => classRepository.getCheckIns(20)).thenAnswer((_) async => []);

    final result = await container.read(classCheckInsProvider(20).future);

    expect(result, isEmpty);
    verify(() => classRepository.getCheckIns(20)).called(1);
  });

  test('build() loads reservations for the only membership when none is selected', () async {
    final reservation =
        Reservation(id: 1, trainerId: 99, scheduledAt: DateTime(2026), status: ReservationStatus.booked, qrCode: '1');
    when(() => classRepository.getReservations(20)).thenAnswer((_) async => [reservation]);

    final result = await container.read(classReservationsProvider.future);

    expect(result, hasLength(1));
  });

  test('createReservation calls the repository for the current membership then refreshes', () async {
    final reservation =
        Reservation(id: 1, trainerId: 99, scheduledAt: DateTime(2026), status: ReservationStatus.booked, qrCode: '1');
    when(() => classRepository.getReservations(20)).thenAnswer((_) async => []);
    when(() => classRepository.createReservation(
          packageAssignmentId: 20,
          trainerId: 99,
          scheduledAt: DateTime(2026),
        )).thenAnswer((_) async {});

    await container.read(classReservationsProvider.future);
    when(() => classRepository.getReservations(20)).thenAnswer((_) async => [reservation]);
    await container
        .read(classReservationsProvider.notifier)
        .createReservation(trainerId: 99, scheduledAt: DateTime(2026));

    verify(() => classRepository.createReservation(
          packageAssignmentId: 20,
          trainerId: 99,
          scheduledAt: DateTime(2026),
        )).called(1);
    expect(container.read(classReservationsProvider).value, hasLength(1));
  });

  test('cancelReservation calls the repository then refreshes', () async {
    when(() => classRepository.getReservations(20)).thenAnswer((_) async => []);
    when(() => classRepository.cancelReservation(1)).thenAnswer((_) async {});

    await container.read(classReservationsProvider.future);
    await container.read(classReservationsProvider.notifier).cancelReservation(1);

    verify(() => classRepository.cancelReservation(1)).called(1);
    verify(() => classRepository.getReservations(20)).called(2);
  });
}
