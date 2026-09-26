import 'platform_report.dart';

/// Sadece Sistem Sahibi görevinde (header'sız istek) çağrılır; diğerlerine
/// backend 403 döner.
abstract interface class PlatformReportRepository {
  Future<PlatformReportSummary> getSummary(ReportPeriod period);

  Future<List<BranchReportRow>> getCompanyBranches(int companyId, ReportPeriod period);
}
