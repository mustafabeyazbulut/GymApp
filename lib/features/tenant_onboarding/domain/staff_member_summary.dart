class StaffMemberSummary {
  const StaffMemberSummary({
    required this.assignmentId,
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.companyId,
    required this.branchId,
    required this.branchName,
  });

  factory StaffMemberSummary.fromJson(Map<String, dynamic> json) => StaffMemberSummary(
        assignmentId: json['assignmentId'] as int,
        userId: json['userId'] as int,
        fullName: json['fullName'] as String,
        phone: json['phone'] as String,
        role: json['role'] as String,
        companyId: json['companyId'] as int?,
        branchId: json['branchId'] as int?,
        branchName: json['branchName'] as String?,
      );

  final int assignmentId;
  final int userId;
  final String fullName;
  final String phone;
  // Backend'in ham enum ismi: "GymAdmin"/"BranchManager"/"Trainer".
  final String role;
  final int? companyId;
  final int? branchId;
  final String? branchName;
}
