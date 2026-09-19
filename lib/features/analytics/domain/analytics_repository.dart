import 'analytics_summary.dart';

abstract interface class AnalyticsRepository {
  // Sadece StaffManagement (GymAdmin/BranchManager/SuperAdmin) -
  // GET /api/analytics/summary. Kapsam ayrı bir parametre GEREKTİRMEZ -
  // backend'in ambient ITenantContext'i (mevcut X-Active-Company-Id
  // header'ı üzerinden) zaten daraltıyor.
  Future<AnalyticsSummary> getSummary();
}
