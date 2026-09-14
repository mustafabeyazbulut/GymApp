import '../domain/branch.dart';

class BranchDto {
  const BranchDto({
    required this.id,
    required this.companyId,
    required this.name,
    required this.address,
    required this.isActive,
  });

  final int id;
  final int companyId;
  final String name;
  final String address;
  final bool isActive;

  factory BranchDto.fromJson(Map<String, dynamic> json) => BranchDto(
        id: json['id'] as int,
        companyId: json['companyId'] as int,
        name: json['name'] as String,
        address: json['address'] as String,
        isActive: json['isActive'] as bool,
      );

  Branch toDomain() => Branch(
        id: id,
        companyId: companyId,
        name: name,
        address: address,
        isActive: isActive,
      );
}
