class OutstandingBalance {
  const OutstandingBalance({
    required this.packageAssignmentId,
    required this.memberFullName,
    required this.memberPhone,
    required this.packageName,
    required this.branchName,
    required this.price,
    required this.totalPaid,
    required this.remainingBalance,
  });

  factory OutstandingBalance.fromJson(Map<String, dynamic> json) => OutstandingBalance(
        packageAssignmentId: json['packageAssignmentId'] as int,
        memberFullName: json['memberFullName'] as String,
        memberPhone: json['memberPhone'] as String,
        packageName: json['packageName'] as String,
        branchName: json['branchName'] as String?,
        price: (json['price'] as num).toDouble(),
        totalPaid: (json['totalPaid'] as num).toDouble(),
        remainingBalance: (json['remainingBalance'] as num).toDouble(),
      );

  final int packageAssignmentId;
  final String memberFullName;
  final String memberPhone;
  final String packageName;
  final String? branchName;
  final double price;
  final double totalPaid;
  final double remainingBalance;
}
