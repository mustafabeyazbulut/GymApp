class PackageSummary {
  const PackageSummary({
    required this.id,
    required this.companyId,
    required this.branchId,
    required this.name,
    required this.description,
    required this.type,
    required this.durationDays,
    required this.sessionCount,
    required this.price,
    required this.isActive,
    required this.maxFreezeDays,
  });

  factory PackageSummary.fromJson(Map<String, dynamic> json) => PackageSummary(
        id: json['id'] as int,
        companyId: json['companyId'] as int,
        branchId: json['branchId'] as int?,
        name: json['name'] as String,
        description: json['description'] as String?,
        type: json['type'] as String,
        durationDays: json['durationDays'] as int?,
        sessionCount: json['sessionCount'] as int?,
        price: (json['price'] as num).toDouble(),
        isActive: json['isActive'] as bool,
        maxFreezeDays: json['maxFreezeDays'] as int?,
      );

  final int id;
  final int companyId;
  final int? branchId;
  final String name;
  final String? description;
  // Backend'in ham enum ismi: "Duration" veya "SessionBased".
  final String type;
  final int? durationDays;
  final int? sessionCount;
  final double price;
  final bool isActive;
  // null = dondurma süresi sınırsız.
  final int? maxFreezeDays;

  bool get isDuration => type == 'Duration';
}
