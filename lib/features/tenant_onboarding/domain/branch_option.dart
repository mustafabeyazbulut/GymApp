class BranchOption {
  const BranchOption({required this.id, required this.name});

  factory BranchOption.fromJson(Map<String, dynamic> json) =>
      BranchOption(id: json['id'] as int, name: json['name'] as String);

  final int id;
  final String name;
}
