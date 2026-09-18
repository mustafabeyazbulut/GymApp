class CheckIn {
  const CheckIn({required this.id, required this.reservationId, required this.checkedInAt});

  final int id;
  // null = rezervasyonsuz/walk-in giriş (bkz. GymAppApi'nin
  // RecordGeneralCheckInCommand'ı).
  final int? reservationId;
  final DateTime checkedInAt;

  factory CheckIn.fromJson(Map<String, dynamic> json) => CheckIn(
        id: json['id'] as int,
        reservationId: json['reservationId'] as int?,
        checkedInAt: DateTime.parse(json['checkedInAt'] as String).toLocal(),
      );
}
