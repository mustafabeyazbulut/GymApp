import 'expiring_membership.dart';
import 'outstanding_balance.dart';
import 'revenue_report.dart';

abstract interface class ReportsRepository {
  // fromDate/toDate null = backend'in varsayılanı (son 30 gün).
  Future<RevenueReport> getRevenueReport({DateTime? fromDate, DateTime? toDate});

  Future<List<OutstandingBalance>> getOutstandingBalances();

  Future<List<ExpiringMembership>> getExpiringMemberships({int daysAhead = 30});
}
