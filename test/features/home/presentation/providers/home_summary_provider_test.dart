import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/auth/data/real_auth_repository.dart';
import 'package:gym_app/features/auth/domain/auth_repository.dart';
import 'package:gym_app/features/auth/domain/me_result.dart';
import 'package:gym_app/features/classes/data/real_class_repository.dart';
import 'package:gym_app/features/classes/domain/check_in.dart';
import 'package:gym_app/features/classes/domain/class_repository.dart';
import 'package:gym_app/features/classes/domain/reservation.dart';
import 'package:gym_app/features/classes/domain/trainer.dart';
import 'package:gym_app/features/home/presentation/providers/home_summary_provider.dart';
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
    'endDate': '2026-12-31T00:00:00',
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
          fullName: 'Ayşe Yılmaz',
          phone: '+905551112233',
          email: null,
          preferredLanguage: 'tr',
          isAccountFrozen: false,
          assignments: const [],
          packageAssignments: [assignment],
        ));
  });

  test('computes package/next-reservation/attendance from real reservation and check-in data', () async {
    final now = DateTime.now();
    final future = now.add(const Duration(days: 1));
    when(() => classRepository.getTrainers(20)).thenAnswer((_) async => [
          const Trainer(id: 99, fullName: 'Ali Antrenör', branchId: null),
        ]);
    when(() => classRepository.getReservations(20)).thenAnswer((_) async => [
          Reservation(id: 1, trainerId: 99, scheduledAt: future, status: ReservationStatus.booked, qrCode: '111111'),
        ]);
    when(() => classRepository.getCheckIns(20)).thenAnswer((_) async => [
          CheckIn(id: 1, reservationId: null, checkedInAt: now),
        ]);

    final summary = await container.read(homeSummaryProvider.future);

    expect(summary.companyName, 'MAT & MOVE Kadıköy');
    expect(summary.packageName, '10 Seans');
    expect(summary.daysLeft, isNotNull);
    expect(summary.nextReservation, isNotNull);
    expect(summary.nextReservation!.trainerName, 'Ali Antrenör');
    expect(summary.attendedCount, 1);
  });

  test('nextReservation is null when there are no upcoming booked reservations', () async {
    when(() => classRepository.getTrainers(20)).thenAnswer((_) async => []);
    when(() => classRepository.getReservations(20)).thenAnswer((_) async => []);
    when(() => classRepository.getCheckIns(20)).thenAnswer((_) async => []);

    final summary = await container.read(homeSummaryProvider.future);

    expect(summary.nextReservation, isNull);
    expect(summary.attendedCount, 0);
  });

  test('nextReservation ignores a booked reservation in the past', () async {
    final past = DateTime.now().subtract(const Duration(days: 1));
    when(() => classRepository.getTrainers(20)).thenAnswer((_) async => [
          const Trainer(id: 99, fullName: 'Ali Antrenör', branchId: null),
        ]);
    when(() => classRepository.getReservations(20)).thenAnswer((_) async => [
          Reservation(id: 1, trainerId: 99, scheduledAt: past, status: ReservationStatus.booked, qrCode: '111111'),
        ]);
    when(() => classRepository.getCheckIns(20)).thenAnswer((_) async => []);

    final summary = await container.read(homeSummaryProvider.future);

    expect(summary.nextReservation, isNull);
  });
}
