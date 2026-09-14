class Branch {
  const Branch({
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Branch &&
          other.id == id &&
          other.companyId == companyId &&
          other.name == name &&
          other.address == address &&
          other.isActive == isActive);

  @override
  int get hashCode => Object.hash(id, companyId, name, address, isActive);

  @override
  String toString() =>
      'Branch(id: $id, companyId: $companyId, name: $name, isActive: $isActive)';
}
