class PackageAssignmentSummary {
  const PackageAssignmentSummary({
    required this.id,
    required this.packageId,
    required this.packageName,
    required this.price,
    required this.memberUserId,
    required this.memberFullName,
    required this.memberPhone,
    required this.companyId,
    required this.branchId,
    required this.startDate,
    required this.endDate,
    required this.remainingSessions,
    required this.status,
    required this.totalPaid,
    required this.remainingBalance,
  });

  factory PackageAssignmentSummary.fromJson(Map<String, dynamic> json) => PackageAssignmentSummary(
        id: json['id'] as int,
        packageId: json['packageId'] as int,
        packageName: json['packageName'] as String,
        price: (json['price'] as num).toDouble(),
        memberUserId: json['memberUserId'] as int,
        memberFullName: json['memberFullName'] as String,
        memberPhone: json['memberPhone'] as String,
        companyId: json['companyId'] as int,
        branchId: json['branchId'] as int?,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: json['endDate'] == null ? null : DateTime.parse(json['endDate'] as String),
        remainingSessions: json['remainingSessions'] as int?,
        status: json['status'] as String,
        totalPaid: (json['totalPaid'] as num).toDouble(),
        remainingBalance: (json['remainingBalance'] as num).toDouble(),
      );

  final int id;
  final int packageId;
  final String packageName;
  final double price;
  final int memberUserId;
  final String memberFullName;
  final String memberPhone;
  final int companyId;
  final int? branchId;
  final DateTime startDate;
  final DateTime? endDate;
  final int? remainingSessions;
  // Backend'in ham enum ismi: "Active"/"Frozen"/"Cancelled".
  final String status;
  final double totalPaid;
  final double remainingBalance;

  bool get isFullyPaid => remainingBalance <= 0;
}
