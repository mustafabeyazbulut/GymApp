class ExpiringMembership {
  const ExpiringMembership({
    required this.packageAssignmentId,
    required this.memberFullName,
    required this.memberPhone,
    required this.packageName,
    required this.branchName,
    required this.endDate,
    required this.daysRemaining,
  });

  factory ExpiringMembership.fromJson(Map<String, dynamic> json) => ExpiringMembership(
        packageAssignmentId: json['packageAssignmentId'] as int,
        memberFullName: json['memberFullName'] as String,
        memberPhone: json['memberPhone'] as String,
        packageName: json['packageName'] as String,
        branchName: json['branchName'] as String?,
        endDate: DateTime.parse(json['endDate'] as String).toLocal(),
        daysRemaining: json['daysRemaining'] as int,
      );

  final int packageAssignmentId;
  final String memberFullName;
  final String memberPhone;
  final String packageName;
  final String? branchName;
  final DateTime endDate;
  // Negatif = süresi zaten dolmuş (kaç gün önce). Pozitif = kaç gün sonra dolacak.
  final int daysRemaining;

  bool get isAlreadyExpired => daysRemaining < 0;
}
