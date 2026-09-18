import 'check_in.dart';
import 'reservation.dart';
import 'trainer.dart';

abstract interface class ClassRepository {
  // Bir PackageAssignment için rezerve edilebilecek antrenörler - hangi
  // trainerId'lerin geçerli olduğunu görmenin tek yolu bu, genel bir
  // antrenör dizini yok (bkz. GetPackageAssignmentTrainersQueryHandler,
  // GymAppApi).
  Future<List<Trainer>> getTrainers(int packageAssignmentId);

  Future<List<Reservation>> getReservations(int packageAssignmentId);

  Future<List<CheckIn>> getCheckIns(int packageAssignmentId);

  Future<void> createReservation({
    required int packageAssignmentId,
    required int trainerId,
    required DateTime scheduledAt,
  });

  Future<void> cancelReservation(int reservationId);
}
