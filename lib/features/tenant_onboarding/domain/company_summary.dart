class CompanyListItem {
  const CompanyListItem({
    required this.id,
    required this.name,
    required this.isActive,
    required this.branchCount,
    required this.gymAdminCount,
    required this.branchManagerCount,
    required this.trainerCount,
    required this.memberCount,
  });

  factory CompanyListItem.fromJson(Map<String, dynamic> json) => CompanyListItem(
        id: json['id'] as int,
        name: json['name'] as String,
        isActive: json['isActive'] as bool,
        branchCount: json['branchCount'] as int,
        gymAdminCount: json['gymAdminCount'] as int,
        branchManagerCount: json['branchManagerCount'] as int,
        trainerCount: json['trainerCount'] as int,
        memberCount: json['memberCount'] as int,
      );

  final int id;
  final String name;
  final bool isActive;
  final int branchCount;
  final int gymAdminCount;
  final int branchManagerCount;
  final int trainerCount;
  final int memberCount;
}

class CompanyBranchSummary {
  const CompanyBranchSummary({
    required this.id,
    required this.name,
    required this.address,
    required this.isActive,
    this.managerName,
  });

  factory CompanyBranchSummary.fromJson(Map<String, dynamic> json) => CompanyBranchSummary(
        id: json['id'] as int,
        name: json['name'] as String,
        address: json['address'] as String,
        isActive: json['isActive'] as bool,
        managerName: json['managerName'] as String?,
      );

  final int id;
  final String name;
  final String address;
  final bool isActive;
  // Bu şubenin BranchManager'ı - henüz atanmadıysa null.
  final String? managerName;
}

class CompanyGymAdmin {
  const CompanyGymAdmin({required this.userId, required this.fullName, required this.phone});

  factory CompanyGymAdmin.fromJson(Map<String, dynamic> json) => CompanyGymAdmin(
        userId: json['userId'] as int,
        fullName: json['fullName'] as String,
        phone: json['phone'] as String,
      );

  final int userId;
  final String fullName;
  final String phone;
}

class CompanyDetail {
  const CompanyDetail({
    required this.id,
    required this.name,
    required this.isActive,
    required this.branches,
    required this.gymAdmins,
    required this.gymAdminCount,
    required this.branchManagerCount,
    required this.trainerCount,
    required this.memberCount,
  });

  factory CompanyDetail.fromJson(Map<String, dynamic> json) => CompanyDetail(
        id: json['id'] as int,
        name: json['name'] as String,
        isActive: json['isActive'] as bool,
        branches: (json['branches'] as List)
            .map((e) => CompanyBranchSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
        gymAdmins: (json['gymAdmins'] as List)
            .map((e) => CompanyGymAdmin.fromJson(e as Map<String, dynamic>))
            .toList(),
        gymAdminCount: json['gymAdminCount'] as int,
        branchManagerCount: json['branchManagerCount'] as int,
        trainerCount: json['trainerCount'] as int,
        memberCount: json['memberCount'] as int,
      );

  final int id;
  final String name;
  final bool isActive;
  final List<CompanyBranchSummary> branches;
  final List<CompanyGymAdmin> gymAdmins;
  final int gymAdminCount;
  final int branchManagerCount;
  final int trainerCount;
  final int memberCount;
}
