import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/active_staff_assignment_provider.dart';
import '../../data/real_class_scheduling_repository.dart';
import '../../domain/class_enrollment.dart';
import '../../domain/class_session.dart';

part 'class_scheduling_providers.g.dart';

// Önümüzdeki 7 gün (bugün dahil) - haftalık program görünümü için.
(DateTime, DateTime) _thisWeekRange() {
  final now = DateTime.now();
  final from = DateTime(now.year, now.month, now.day);
  final to = from.add(const Duration(days: 7));
  return (from, to);
}

@riverpod
class WeeklyClassSessions extends _$WeeklyClassSessions {
  @override
  Future<List<ClassSession>> build() {
    // Personelin gördüğü program aktif göreve özel - görev değişince yenilenir.
    ref.watch(activeStaffAssignmentProvider);
    final (from, to) = _thisWeekRange();
    return ref.watch(classSchedulingRepositoryProvider).getClassSessions(from: from, to: to);
  }

  Future<void> enroll({required int classSessionId, required int packageAssignmentId}) async {
    final repository = ref.read(classSchedulingRepositoryProvider);
    await repository.enroll(classSessionId: classSessionId, packageAssignmentId: packageAssignmentId);
    final (from, to) = _thisWeekRange();
    state = await AsyncValue.guard(() => repository.getClassSessions(from: from, to: to));
    ref.invalidate(myClassEnrollmentsProvider);
  }
}

@riverpod
class MyClassEnrollments extends _$MyClassEnrollments {
  @override
  Future<List<MyClassEnrollment>> build() => ref.watch(classSchedulingRepositoryProvider).getMyEnrollments();

  Future<void> cancel(int classEnrollmentId) async {
    final repository = ref.read(classSchedulingRepositoryProvider);
    await repository.cancelEnrollment(classEnrollmentId);
    state = await AsyncValue.guard(repository.getMyEnrollments);
    ref.invalidate(weeklyClassSessionsProvider);
  }
}

// Kendi state'i yok, sadece staff'ın ders programı oluşturma mutasyonunu
// sunuyor - PackageActions'ın aynı deseni.
@riverpod
class ClassSessionActions extends _$ClassSessionActions {
  @override
  void build() {}

  Future<void> createClassSession({
    required int branchId,
    required int trainerUserId,
    required ClassSessionCategory category,
    required String name,
    required DateTime date,
    required String startTime,
    required String endTime,
    required int capacity,
    required int cancellationCutoffHours,
  }) async {
    await ref.read(classSchedulingRepositoryProvider).createClassSession(
          branchId: branchId,
          trainerUserId: trainerUserId,
          category: category,
          name: name,
          date: date,
          startTime: startTime,
          endTime: endTime,
          capacity: capacity,
          cancellationCutoffHours: cancellationCutoffHours,
        );
    ref.invalidate(weeklyClassSessionsProvider);
  }
}
