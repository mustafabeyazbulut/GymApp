import 'package:intl/intl.dart';

/// Rapor dönemi - sözleşmedeki `days` değerleri.
enum ReportPeriod {
  days7(7),
  days30(30),
  days90(90),
  year(365);

  const ReportPeriod(this.days);

  final int days;
}

class UserGrowthPoint {
  const UserGrowthPoint({required this.date, required this.newUsers});

  factory UserGrowthPoint.fromJson(Map<String, dynamic> json) => UserGrowthPoint(
        // Gün bazlı tarih - saat dilimi kaymasın diye yerel gün olarak.
        date: DateFormat('yyyy-MM-dd').parseStrict(json['date'] as String),
        newUsers: json['newUsers'] as int,
      );

  final DateTime date;
  final int newUsers;
}

/// Firma ve şube satırlarında ortak metrikler. activeMemberCount = geçerli
/// paketi olan tekil kullanıcı; staffCount = GymAdmin + BranchManager;
/// trainerCount ayrı.
class ReportMetrics {
  const ReportMetrics({
    required this.branchCount,
    required this.activeMemberCount,
    required this.trainerCount,
    required this.staffCount,
    required this.packageSalesInPeriod,
    required this.revenueInPeriod,
  });

  factory ReportMetrics.fromJson(Map<String, dynamic> json) => ReportMetrics(
        branchCount: json['branchCount'] as int?,
        activeMemberCount: json['activeMemberCount'] as int,
        trainerCount: json['trainerCount'] as int,
        staffCount: json['staffCount'] as int,
        packageSalesInPeriod: json['packageSalesInPeriod'] as int,
        revenueInPeriod: (json['revenueInPeriod'] as num).toDouble(),
      );

  // Şube satırında yok (null).
  final int? branchCount;
  final int activeMemberCount;
  final int trainerCount;
  final int staffCount;
  final int packageSalesInPeriod;
  final double revenueInPeriod;
}

class CompanyReportRow {
  const CompanyReportRow({
    required this.companyId,
    required this.companyName,
    required this.isActive,
    required this.metrics,
  });

  factory CompanyReportRow.fromJson(Map<String, dynamic> json) => CompanyReportRow(
        companyId: json['companyId'] as int,
        companyName: json['companyName'] as String,
        isActive: json['isActive'] as bool,
        metrics: ReportMetrics.fromJson(json),
      );

  final int companyId;
  final String companyName;
  final bool isActive;
  final ReportMetrics metrics;
}

class BranchReportRow {
  const BranchReportRow({
    required this.branchId,
    required this.branchName,
    required this.isActive,
    required this.metrics,
  });

  factory BranchReportRow.fromJson(Map<String, dynamic> json) => BranchReportRow(
        branchId: json['branchId'] as int,
        branchName: json['branchName'] as String,
        isActive: json['isActive'] as bool,
        metrics: ReportMetrics.fromJson(json),
      );

  final int branchId;
  final String branchName;
  final bool isActive;
  final ReportMetrics metrics;
}

/// Sistem Sahibinin platform raporu (ana senaryo §4.6).
class PlatformReportSummary {
  const PlatformReportSummary({
    required this.totalUsers,
    required this.newUsersInPeriod,
    required this.userGrowth,
    required this.companyCount,
    required this.activeCompanyCount,
    required this.branchCount,
    required this.activeMemberCount,
    required this.trainerCount,
    required this.staffCount,
    required this.packageSalesInPeriod,
    required this.revenueInPeriod,
    required this.currency,
    required this.companies,
  });

  factory PlatformReportSummary.fromJson(Map<String, dynamic> json) => PlatformReportSummary(
        totalUsers: json['totalUsers'] as int,
        newUsersInPeriod: json['newUsersInPeriod'] as int,
        userGrowth: (json['userGrowth'] as List)
            .cast<Map<String, dynamic>>()
            .map(UserGrowthPoint.fromJson)
            .toList(),
        companyCount: json['companyCount'] as int,
        activeCompanyCount: json['activeCompanyCount'] as int,
        branchCount: json['branchCount'] as int,
        activeMemberCount: json['activeMemberCount'] as int,
        trainerCount: json['trainerCount'] as int,
        staffCount: json['staffCount'] as int,
        packageSalesInPeriod: json['packageSalesInPeriod'] as int,
        revenueInPeriod: (json['revenueInPeriod'] as num).toDouble(),
        currency: json['currency'] as String,
        companies: (json['companies'] as List)
            .cast<Map<String, dynamic>>()
            .map(CompanyReportRow.fromJson)
            .toList(),
      );

  final int totalUsers;
  final int newUsersInPeriod;
  final List<UserGrowthPoint> userGrowth;
  final int companyCount;
  final int activeCompanyCount;
  final int branchCount;
  final int activeMemberCount;
  final int trainerCount;
  final int staffCount;
  final int packageSalesInPeriod;
  final double revenueInPeriod;
  final String currency;
  final List<CompanyReportRow> companies;
}
