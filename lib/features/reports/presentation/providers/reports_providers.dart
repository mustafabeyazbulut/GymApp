import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/real_reports_repository.dart';
import '../../domain/expiring_membership.dart';
import '../../domain/outstanding_balance.dart';
import '../../domain/revenue_report.dart';

part 'reports_providers.g.dart';

@riverpod
class RevenueReportNotifier extends _$RevenueReportNotifier {
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  Future<RevenueReport> build() => ref.watch(reportsRepositoryProvider).getRevenueReport();

  Future<void> setRange({DateTime? fromDate, DateTime? toDate}) async {
    _fromDate = fromDate;
    _toDate = toDate;
    final repository = ref.read(reportsRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repository.getRevenueReport(fromDate: _fromDate, toDate: _toDate));
  }
}

@riverpod
class OutstandingBalancesNotifier extends _$OutstandingBalancesNotifier {
  @override
  Future<List<OutstandingBalance>> build() => ref.watch(reportsRepositoryProvider).getOutstandingBalances();

  Future<void> refresh() async {
    final repository = ref.read(reportsRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(repository.getOutstandingBalances);
  }
}

@riverpod
class ExpiringMembershipsNotifier extends _$ExpiringMembershipsNotifier {
  int _daysAhead = 30;

  @override
  Future<List<ExpiringMembership>> build() => ref.watch(reportsRepositoryProvider).getExpiringMemberships(daysAhead: _daysAhead);

  Future<void> setDaysAhead(int daysAhead) async {
    _daysAhead = daysAhead;
    final repository = ref.read(reportsRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repository.getExpiringMemberships(daysAhead: _daysAhead));
  }
}
