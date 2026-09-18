import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/classes/domain/reservation.dart';

void main() {
  test('fromJson parses a Booked reservation', () {
    final reservation = Reservation.fromJson({
      'id': 1,
      'trainerId': 99,
      'scheduledAt': '2026-01-01T10:00:00Z',
      'status': 'Booked',
      'qrCode': '111111',
    });

    expect(reservation.id, 1);
    expect(reservation.trainerId, 99);
    expect(reservation.status, ReservationStatus.booked);
    expect(reservation.qrCode, '111111');
  });

  test('reservationStatusFromApi maps every known status string', () {
    expect(reservationStatusFromApi('Booked'), ReservationStatus.booked);
    expect(reservationStatusFromApi('CheckedIn'), ReservationStatus.checkedIn);
    expect(reservationStatusFromApi('Cancelled'), ReservationStatus.cancelled);
    expect(reservationStatusFromApi('NoShow'), ReservationStatus.noShow);
  });
}
