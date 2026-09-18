enum MyReservationStatus { booked, checkedIn, cancelled, noShow }

MyReservationStatus myReservationStatusFromApi(String value) => switch (value) {
      'CheckedIn' => MyReservationStatus.checkedIn,
      'Cancelled' => MyReservationStatus.cancelled,
      'NoShow' => MyReservationStatus.noShow,
      _ => MyReservationStatus.booked,
    };

class MyReservation {
  const MyReservation({
    required this.id,
    required this.packageAssignmentId,
    required this.memberFullName,
    required this.companyId,
    required this.branchId,
    required this.scheduledAt,
    required this.status,
  });

  factory MyReservation.fromJson(Map<String, dynamic> json) => MyReservation(
        id: json['id'] as int,
        packageAssignmentId: json['packageAssignmentId'] as int,
        memberFullName: json['memberFullName'] as String?,
        companyId: json['companyId'] as int,
        branchId: json['branchId'] as int?,
        scheduledAt: DateTime.parse(json['scheduledAt'] as String).toLocal(),
        status: myReservationStatusFromApi(json['status'] as String),
      );

  final int id;
  final int packageAssignmentId;
  final String? memberFullName;
  final int companyId;
  final int? branchId;
  final DateTime scheduledAt;
  final MyReservationStatus status;
}
