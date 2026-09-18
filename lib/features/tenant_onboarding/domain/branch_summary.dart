class BranchSummary {
  const BranchSummary({
    required this.id,
    required this.companyId,
    required this.name,
    required this.address,
    required this.isActive,
  });

  factory BranchSummary.fromJson(Map<String, dynamic> json) => BranchSummary(
        id: json['id'] as int,
        companyId: json['companyId'] as int,
        name: json['name'] as String,
        address: json['address'] as String,
        isActive: json['isActive'] as bool,
      );

  final int id;
  final int companyId;
  final String name;
  final String address;
  final bool isActive;
}
