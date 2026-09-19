// GymAppApi'nin GET /api/analytics/summary yanıtının mobil karşılığı - salt
// okunur, StaffManagement (GymAdmin/BranchManager/SuperAdmin) için basit bir
// raporlama özeti. Backend'in AnalyticsSummaryDto'suyla birebir aynı alanlar
// (bkz. GymAppApi'nin Features/Analytics/Queries/GetAnalyticsSummary'si).
class AnalyticsSummary {
  const AnalyticsSummary({
    required this.activeMembers,
    required this.classOccupancy,
    required this.packageSales,
    required this.trainerActiveStudents,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) => AnalyticsSummary(
        activeMembers: ActiveMemberMetric.fromJson(json['activeMembers'] as Map<String, dynamic>),
        classOccupancy: ClassOccupancyMetric.fromJson(json['classOccupancy'] as Map<String, dynamic>),
        packageSales: PackageSalesMetric.fromJson(json['packageSales'] as Map<String, dynamic>),
        trainerActiveStudents: (json['trainerActiveStudents'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(TrainerActiveStudent.fromJson)
            .toList(),
      );

  final ActiveMemberMetric activeMembers;
  final ClassOccupancyMetric classOccupancy;
  final PackageSalesMetric packageSales;
  final List<TrainerActiveStudent> trainerActiveStudents;
}

class ActiveMemberMetric {
  const ActiveMemberMetric({
    required this.currentCount,
    required this.countThirtyDaysAgo,
    required this.trendPercentage,
  });

  factory ActiveMemberMetric.fromJson(Map<String, dynamic> json) => ActiveMemberMetric(
        currentCount: json['currentCount'] as int,
        countThirtyDaysAgo: json['countThirtyDaysAgo'] as int,
        trendPercentage: (json['trendPercentage'] as num?)?.toDouble(),
      );

  final int currentCount;
  final int countThirtyDaysAgo;
  // null = 30 gün önce hiç aktif üye yoktu (sıfıra bölme yapılamadı) -
  // backend'in ActiveMemberMetricDto.TrendPercentage'ı, karşılaştırılamaz.
  final double? trendPercentage;
}

class ClassOccupancyMetric {
  const ClassOccupancyMetric({required this.overallOccupancyRate, required this.classBreakdown});

  factory ClassOccupancyMetric.fromJson(Map<String, dynamic> json) => ClassOccupancyMetric(
        overallOccupancyRate: (json['overallOccupancyRate'] as num).toDouble(),
        classBreakdown: (json['classBreakdown'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(ClassOccupancyBreakdown.fromJson)
            .toList(),
      );

  // 0..1 arası oran (0.75 = %75 doluluk).
  final double overallOccupancyRate;
  final List<ClassOccupancyBreakdown> classBreakdown;
}

class ClassOccupancyBreakdown {
  const ClassOccupancyBreakdown({
    required this.className,
    required this.sessionCount,
    required this.totalCapacity,
    required this.totalEnrolled,
    required this.occupancyRate,
  });

  factory ClassOccupancyBreakdown.fromJson(Map<String, dynamic> json) => ClassOccupancyBreakdown(
        className: json['className'] as String,
        sessionCount: json['sessionCount'] as int,
        totalCapacity: json['totalCapacity'] as int,
        totalEnrolled: json['totalEnrolled'] as int,
        occupancyRate: (json['occupancyRate'] as num).toDouble(),
      );

  final String className;
  final int sessionCount;
  final int totalCapacity;
  final int totalEnrolled;
  final double occupancyRate;
}

class PackageSalesMetric {
  const PackageSalesMetric({required this.totalCount, required this.categoryBreakdown});

  factory PackageSalesMetric.fromJson(Map<String, dynamic> json) => PackageSalesMetric(
        totalCount: json['totalCount'] as int,
        categoryBreakdown: (json['categoryBreakdown'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(PackageSalesCategoryBreakdown.fromJson)
            .toList(),
      );

  final int totalCount;
  final List<PackageSalesCategoryBreakdown> categoryBreakdown;
}

class PackageSalesCategoryBreakdown {
  const PackageSalesCategoryBreakdown({required this.category, required this.count});

  factory PackageSalesCategoryBreakdown.fromJson(Map<String, dynamic> json) => PackageSalesCategoryBreakdown(
        category: json['category'] as String?,
        count: json['count'] as int,
      );

  // 'GroupClass' | 'MartialArts' | null (Package.Category set edilmemiş -
  // ör. sadece 1:1 Reservation için kullanılan bir PT paketi).
  final String? category;
  final int count;
}

class TrainerActiveStudent {
  const TrainerActiveStudent({
    required this.trainerUserId,
    required this.trainerFullName,
    required this.activeStudentCount,
  });

  factory TrainerActiveStudent.fromJson(Map<String, dynamic> json) => TrainerActiveStudent(
        trainerUserId: json['trainerUserId'] as int,
        trainerFullName: json['trainerFullName'] as String,
        activeStudentCount: json['activeStudentCount'] as int,
      );

  final int trainerUserId;
  final String trainerFullName;
  final int activeStudentCount;
}
