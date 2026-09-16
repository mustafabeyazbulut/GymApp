class MeAssignment {
  const MeAssignment({
    required this.companyId,
    required this.companyName,
    required this.branchId,
    required this.role,
  });

  factory MeAssignment.fromJson(Map<String, dynamic> json) => MeAssignment(
        companyId: json['companyId'] as int?,
        companyName: json['companyName'] as String?,
        branchId: json['branchId'] as int?,
        role: json['role'] as String,
      );

  // Null for a platform-wide assignment (e.g. SuperAdmin), which is not tied to a single company.
  final int? companyId;
  final String? companyName;
  final int? branchId;
  final String role;
}

class MeResult {
  const MeResult({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.preferredLanguage,
    required this.isAccountFrozen,
    required this.assignments,
  });

  factory MeResult.fromJson(Map<String, dynamic> json) => MeResult(
        id: json['id'] as int,
        fullName: json['fullName'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String?,
        preferredLanguage: json['preferredLanguage'] as String,
        isAccountFrozen: json['isAccountFrozen'] as bool,
        assignments: (json['assignments'] as List)
            .map((e) => MeAssignment.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final int id;
  final String fullName;
  final String phone;
  final String? email;
  final String preferredLanguage;
  final bool isAccountFrozen;
  final List<MeAssignment> assignments;

  bool get hasActiveMembership => assignments.isNotEmpty;
}
