import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/trainer_schedule/domain/my_reservation.dart';

void main() {
  test('fromJson parses all fields including a null memberFullName/branchId', () {
    final reservation = MyReservation.fromJson({
      'id': 1,
      'packageAssignmentId': 10,
      'memberUserId': 7,
      'memberFullName': null,
      'companyId': 3,
      'branchId': null,
      'scheduledAt': '2026-01-01T10:00:00Z',
      'status': 'Booked',
      'qrCode': '111111',
    });

    expect(reservation.id, 1);
    expect(reservation.packageAssignmentId, 10);
    expect(reservation.memberFullName, isNull);
    expect(reservation.companyId, 3);
    expect(reservation.branchId, isNull);
    expect(reservation.status, MyReservationStatus.booked);
  });

  test('fromJson parses a Turkish member name', () {
    final reservation = MyReservation.fromJson({
      'id': 1,
      'packageAssignmentId': 10,
      'memberUserId': 7,
      'memberFullName': 'Ayşe Yılmaz',
      'companyId': 3,
      'branchId': 10,
      'scheduledAt': '2026-01-01T10:00:00Z',
      'status': 'CheckedIn',
      'qrCode': '111111',
    });

    expect(reservation.memberFullName, 'Ayşe Yılmaz');
    expect(reservation.branchId, 10);
    expect(reservation.status, MyReservationStatus.checkedIn);
  });

  test('myReservationStatusFromApi maps every known status string', () {
    expect(myReservationStatusFromApi('Booked'), MyReservationStatus.booked);
    expect(myReservationStatusFromApi('CheckedIn'), MyReservationStatus.checkedIn);
    expect(myReservationStatusFromApi('Cancelled'), MyReservationStatus.cancelled);
    expect(myReservationStatusFromApi('NoShow'), MyReservationStatus.noShow);
  });
}
