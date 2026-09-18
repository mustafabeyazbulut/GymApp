import 'my_reservation.dart';

abstract interface class TrainerScheduleRepository {
  Future<List<MyReservation>> getMyReservations();

  // Üçü de sadece Status == Booked bir rezervasyon için geçerli - bkz.
  // GymAppApi'nin CheckInReservationCommand/MarkReservationNoShowCommand/
  // CancelReservationCommand'ı.
  Future<void> checkIn(int reservationId);
  Future<void> markNoShow(int reservationId);
  Future<void> cancel(int reservationId);
}
