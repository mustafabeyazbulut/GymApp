enum ReservationStatus { booked, checkedIn, cancelled, noShow }

ReservationStatus reservationStatusFromApi(String value) => switch (value) {
      'CheckedIn' => ReservationStatus.checkedIn,
      'Cancelled' => ReservationStatus.cancelled,
      'NoShow' => ReservationStatus.noShow,
      _ => ReservationStatus.booked,
    };

class Reservation {
  const Reservation({
    required this.id,
    required this.trainerId,
    required this.scheduledAt,
    required this.status,
    required this.qrCode,
  });

  final int id;
  final int trainerId;
  final DateTime scheduledAt;
  final ReservationStatus status;
  final String qrCode;

  factory Reservation.fromJson(Map<String, dynamic> json) => Reservation(
        id: json['id'] as int,
        trainerId: json['trainerId'] as int,
        scheduledAt: DateTime.parse(json['scheduledAt'] as String).toLocal(),
        status: reservationStatusFromApi(json['status'] as String),
        qrCode: json['qrCode'] as String,
      );
}
