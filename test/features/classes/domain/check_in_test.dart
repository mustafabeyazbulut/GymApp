import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/classes/domain/check_in.dart';

void main() {
  test('fromJson parses a walk-in check-in (null reservationId)', () {
    final checkIn = CheckIn.fromJson({'id': 1, 'reservationId': null, 'checkedInAt': '2026-01-01T10:00:00Z'});

    expect(checkIn.id, 1);
    expect(checkIn.reservationId, isNull);
  });

  test('fromJson parses a reservation-fulfilling check-in', () {
    final checkIn = CheckIn.fromJson({'id': 1, 'reservationId': 5, 'checkedInAt': '2026-01-01T10:00:00Z'});

    expect(checkIn.reservationId, 5);
  });
}
