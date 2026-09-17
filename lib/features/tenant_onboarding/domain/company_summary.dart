class CompanyListItem {
  const CompanyListItem({
    required this.id,
    required this.name,
    required this.isActive,
    required this.branchCount,
  });

  factory CompanyListItem.fromJson(Map<String, dynamic> json) => CompanyListItem(
        id: json['id'] as int,
        name: json['name'] as String,
        isActive: json['isActive'] as bool,
        branchCount: json['branchCount'] as int,
      );

  final int id;
  final String name;
  final bool isActive;
  final int branchCount;
}

class CompanyBranchSummary {
  const CompanyBranchSummary({
    required this.id,
    required this.name,
    required this.address,
    required this.isActive,
  });

  factory CompanyBranchSummary.fromJson(Map<String, dynamic> json) => CompanyBranchSummary(
        id: json['id'] as int,
        name: json['name'] as String,
        address: json['address'] as String,
        isActive: json['isActive'] as bool,
      );

  final int id;
  final String name;
  final String address;
  final bool isActive;
}

class CompanyDetail {
  const CompanyDetail({
    required this.id,
    required this.name,
    required this.isActive,
    required this.branches,
  });

  factory CompanyDetail.fromJson(Map<String, dynamic> json) => CompanyDetail(
        id: json['id'] as int,
        name: json['name'] as String,
        isActive: json['isActive'] as bool,
        branches: (json['branches'] as List)
            .map((e) => CompanyBranchSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final int id;
  final String name;
  final bool isActive;
  final List<CompanyBranchSummary> branches;
}
