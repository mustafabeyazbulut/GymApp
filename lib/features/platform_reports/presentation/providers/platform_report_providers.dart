import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/real_platform_report_repository.dart';
import '../../domain/platform_report.dart';

part 'platform_report_providers.g.dart';

@riverpod
class SelectedReportPeriod extends _$SelectedReportPeriod {
  @override
  ReportPeriod build() => ReportPeriod.days30;

  void select(ReportPeriod period) => state = period;
}

// Dönem değişince özet ve açık şube kırılımları yeniden yüklenir.
@riverpod
Future<PlatformReportSummary> platformReportSummary(Ref ref) =>
    ref.watch(platformReportRepositoryProvider).getSummary(ref.watch(selectedReportPeriodProvider));

@riverpod
Future<List<BranchReportRow>> companyBranchReport(Ref ref, int companyId) => ref
    .watch(platformReportRepositoryProvider)
    .getCompanyBranches(companyId, ref.watch(selectedReportPeriodProvider));
