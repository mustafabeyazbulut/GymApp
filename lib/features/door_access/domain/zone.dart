class Zone {
  const Zone({required this.id, required this.branchId, required this.name});

  factory Zone.fromJson(Map<String, dynamic> json) => Zone(
        id: json['id'] as int,
        branchId: json['branchId'] as int,
        name: json['name'] as String,
      );

  final int id;
  final int branchId;
  final String name;
}

class Door {
  const Door({required this.id, required this.zoneId, required this.name});

  factory Door.fromJson(Map<String, dynamic> json) => Door(
        id: json['id'] as int,
        zoneId: json['zoneId'] as int,
        name: json['name'] as String,
      );

  final int id;
  final int zoneId;
  final String name;
}

// Backend'in ham enum ismi ("AllActiveMembers"/"Gender"/"Role"/"PackageCategory") -
// diğer raw-string alanlarla aynı desen. Hiçbir kod bu kuralları şu an
// DEĞERLENDİRMİYOR - sadece tanımlanıp saklanıyorlar (bkz.
// docs/superpowers/specs/2026-09-20-door-access-skeleton-design.md).
class ZoneAccessRule {
  const ZoneAccessRule({required this.id, required this.zoneId, required this.ruleType, required this.ruleValue});

  factory ZoneAccessRule.fromJson(Map<String, dynamic> json) => ZoneAccessRule(
        id: json['id'] as int,
        zoneId: json['zoneId'] as int,
        ruleType: json['ruleType'] as String,
        ruleValue: json['ruleValue'] as String?,
      );

  final int id;
  final int zoneId;
  final String ruleType;
  final String? ruleValue;
}
