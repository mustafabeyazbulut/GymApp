import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/class_scheduling/data/real_class_scheduling_repository.dart';
import 'package:gym_app/features/class_scheduling/domain/class_enrollment.dart';
import 'package:gym_app/features/class_scheduling/domain/class_scheduling_repository.dart';
import 'package:gym_app/features/class_scheduling/domain/class_session.dart';
import 'package:gym_app/features/class_scheduling/presentation/providers/class_scheduling_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockClassSchedulingRepository extends Mock implements ClassSchedulingRepository {}

void main() {
  late _MockClassSchedulingRepository repository;
  late ProviderContainer container;

  final session = ClassSession(
    id: 1,
    branchId: 10,
    trainerUserId: 99,
    category: ClassSessionCategory.groupClass,
    name: 'Yoga',
    date: DateTime(2026, 9, 21),
    startTime: '09:00:00',
    endTime: '10:00:00',
    capacity: 10,
    enrolledCount: 3,
    cancellationCutoffHours: 2,
  );

  final enrollment = MyClassEnrollment(
    id: 7,
    classSessionId: 1,
    className: 'Yoga',
    category: ClassSessionCategory.groupClass,
    date: DateTime(2026, 9, 21),
    startTime: '09:00:00',
    endTime: '10:00:00',
    status: ClassEnrollmentStatus.reserved,
  );

  setUp(() {
    repository = _MockClassSchedulingRepository();
    container = ProviderContainer(overrides: [
      classSchedulingRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);
  });

  test('WeeklyClassSessions.build() loads sessions for the next 7 days', () async {
    when(() => repository.getClassSessions(from: any(named: 'from'), to: any(named: 'to')))
        .thenAnswer((_) async => [session]);

    final result = await container.read(weeklyClassSessionsProvider.future);

    expect(result, hasLength(1));
    expect(result.single.name, 'Yoga');
  });

  test('WeeklyClassSessions.enroll calls the repository then refreshes and invalidates my enrollments', () async {
    when(() => repository.getClassSessions(from: any(named: 'from'), to: any(named: 'to')))
        .thenAnswer((_) async => []);
    when(() => repository.enroll(classSessionId: 1, packageAssignmentId: 20)).thenAnswer((_) async {});
    when(() => repository.getMyEnrollments()).thenAnswer((_) async => []);

    await container.read(weeklyClassSessionsProvider.future);
    when(() => repository.getClassSessions(from: any(named: 'from'), to: any(named: 'to')))
        .thenAnswer((_) async => [session]);
    await container
        .read(weeklyClassSessionsProvider.notifier)
        .enroll(classSessionId: 1, packageAssignmentId: 20);

    verify(() => repository.enroll(classSessionId: 1, packageAssignmentId: 20)).called(1);
    expect(container.read(weeklyClassSessionsProvider).value, hasLength(1));
  });

  test('MyClassEnrollments.build() loads the callers own enrollments', () async {
    when(() => repository.getMyEnrollments()).thenAnswer((_) async => [enrollment]);

    final result = await container.read(myClassEnrollmentsProvider.future);

    expect(result.single.className, 'Yoga');
  });

  test('MyClassEnrollments.cancel calls the repository then refreshes', () async {
    when(() => repository.getMyEnrollments()).thenAnswer((_) async => [enrollment]);
    when(() => repository.cancelEnrollment(7)).thenAnswer((_) async {});

    await container.read(myClassEnrollmentsProvider.future);
    when(() => repository.getMyEnrollments()).thenAnswer((_) async => []);
    await container.read(myClassEnrollmentsProvider.notifier).cancel(7);

    verify(() => repository.cancelEnrollment(7)).called(1);
    expect(container.read(myClassEnrollmentsProvider).value, isEmpty);
  });

  test('ClassSessionActions.createClassSession calls the repository then invalidates the weekly schedule', () async {
    when(() => repository.createClassSession(
          branchId: 10,
          trainerUserId: 99,
          category: ClassSessionCategory.groupClass,
          name: 'Yoga',
          date: DateTime(2026, 9, 21),
          startTime: '09:00',
          endTime: '10:00',
          capacity: 10,
          cancellationCutoffHours: 2,
        )).thenAnswer((_) async {});

    await container.read(classSessionActionsProvider.notifier).createClassSession(
          branchId: 10,
          trainerUserId: 99,
          category: ClassSessionCategory.groupClass,
          name: 'Yoga',
          date: DateTime(2026, 9, 21),
          startTime: '09:00',
          endTime: '10:00',
          capacity: 10,
          cancellationCutoffHours: 2,
        );

    verify(() => repository.createClassSession(
          branchId: 10,
          trainerUserId: 99,
          category: ClassSessionCategory.groupClass,
          name: 'Yoga',
          date: DateTime(2026, 9, 21),
          startTime: '09:00',
          endTime: '10:00',
          capacity: 10,
          cancellationCutoffHours: 2,
        )).called(1);
  });
}
