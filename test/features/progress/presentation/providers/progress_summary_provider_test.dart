import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/auth/data/real_auth_repository.dart';
import 'package:gym_app/features/auth/domain/auth_repository.dart';
import 'package:gym_app/features/auth/domain/me_result.dart';
import 'package:gym_app/features/classes/data/real_class_repository.dart';
import 'package:gym_app/features/classes/domain/check_in.dart';
import 'package:gym_app/features/classes/domain/class_repository.dart';
import 'package:gym_app/features/progress/data/real_progress_repository.dart';
import 'package:gym_app/features/progress/domain/progress_repository.dart';
import 'package:gym_app/features/progress/domain/progress_summary.dart';
import 'package:gym_app/features/progress/presentation/providers/progress_summary_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockClassRepository extends Mock implements ClassRepository {}

class _MockProgressRepository extends Mock implements ProgressRepository {}

void main() {
  late _MockAuthRepository authRepository;
  late _MockClassRepository classRepository;
  late _MockProgressRepository progressRepository;
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
    progressRepository = _MockProgressRepository();
    container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(authRepository),
      classRepositoryProvider.overrideWithValue(classRepository),
      progressRepositoryProvider.overrideWithValue(progressRepository),
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

  test('computes classesThisMonth/attendanceValue from real check-ins and carries the notes', () async {
    final now = DateTime.now();
    when(() => classRepository.getCheckIns(20)).thenAnswer((_) async => [
          CheckIn(id: 1, reservationId: null, checkedInAt: now),
          CheckIn(id: 2, reservationId: null, checkedInAt: now.subtract(const Duration(days: 1))),
        ]);
    when(() => progressRepository.getProgressNotes(20)).thenAnswer((_) async => [
          ProgressNote(id: 1, techniqueScore: 70, conditionScore: 60, noteText: 'İyi ilerleme.', createdAt: now),
        ]);

    final summary = await container.read(progressSummaryProvider.future);

    expect(summary.classesThisMonth, 2);
    expect(summary.attendanceValue, greaterThan(0));
    expect(summary.latestNote!.noteText, 'İyi ilerleme.');
    expect(summary.techniqueValue, 0.7);
    expect(summary.conditionValue, 0.6);
  });

  test('progressNotesProvider delegates to the repository for the given id', () async {
    when(() => progressRepository.getProgressNotes(20)).thenAnswer((_) async => []);

    final result = await container.read(progressNotesProvider(20).future);

    expect(result, isEmpty);
    verify(() => progressRepository.getProgressNotes(20)).called(1);
  });

  test('latestNote is null when there are no notes yet', () async {
    when(() => classRepository.getCheckIns(20)).thenAnswer((_) async => []);
    when(() => progressRepository.getProgressNotes(20)).thenAnswer((_) async => []);

    final summary = await container.read(progressSummaryProvider.future);

    expect(summary.latestNote, isNull);
    expect(summary.techniqueValue, 0);
    expect(summary.conditionValue, 0);
  });
}
