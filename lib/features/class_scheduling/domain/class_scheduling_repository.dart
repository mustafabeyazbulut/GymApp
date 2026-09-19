import 'class_enrollment.dart';
import 'class_session.dart';

abstract interface class ClassSchedulingRepository {
  // branchId verilmezse çağıranın tüm görebildiği şubeler döner - backend
  // [Authorize] (herkese açık), GET /api/class-sessions.
  Future<List<ClassSession>> getClassSessions({int? branchId, DateTime? from, DateTime? to});

  Future<void> enroll({required int classSessionId, required int packageAssignmentId});

  Future<void> cancelEnrollment(int classEnrollmentId);

  Future<List<MyClassEnrollment>> getMyEnrollments();

  // Sadece StaffManagement (GymAdmin/BranchManager) - POST /api/class-sessions.
  Future<void> createClassSession({
    required int branchId,
    required int trainerUserId,
    required ClassSessionCategory category,
    required String name,
    required DateTime date,
    required String startTime, // "HH:mm"
    required String endTime, // "HH:mm"
    required int capacity,
    required int cancellationCutoffHours,
  });
}
