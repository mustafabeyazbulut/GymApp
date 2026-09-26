import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/format/money_format.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/platform_report.dart';
import '../providers/platform_report_providers.dart';

final _axisDateFormat = DateFormat('dd.MM');

/// Sistem Sahibinin platform raporları (ana senaryo §4.6): kullanıcı ve
/// büyüme, firma/şube sayıları, aktif üye, personel, paket satışı ve gelir;
/// firma satırından şube kırılımına inilir.
class PlatformReportsScreen extends ConsumerWidget {
  const PlatformReportsScreen({super.key});

  String _periodLabel(ReportPeriod period, AppLocalizations l10n) => switch (period) {
        ReportPeriod.days7 => l10n.platformReportsPeriod7,
        ReportPeriod.days30 => l10n.platformReportsPeriod30,
        ReportPeriod.days90 => l10n.platformReportsPeriod90,
        ReportPeriod.year => l10n.platformReportsPeriod365,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final period = ref.watch(selectedReportPeriodProvider);
    final summaryAsync = ref.watch(platformReportSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.platformReportsTitle)),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.refresh(platformReportSummaryProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final option in ReportPeriod.values)
                    ChoiceChip(
                      label: Text(_periodLabel(option, l10n)),
                      selected: option == period,
                      onSelected: (_) => ref.read(selectedReportPeriodProvider.notifier).select(option),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              ...summaryAsync.when(
                loading: () => [
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.xxl),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  ),
                ],
                error: (error, stackTrace) => [
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxl),
                    child: Column(
                      children: [
                        Text(
                          error is ApiException ? error.localizedMessage(context) : l10n.commonError,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        OutlinedButton(
                          onPressed: () => ref.invalidate(platformReportSummaryProvider),
                          child: Text(l10n.commonRetry),
                        ),
                      ],
                    ),
                  ),
                ],
                data: (summary) => _content(context, summary, l10n),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, PlatformReportSummary summary, AppLocalizations l10n) {
    final locale = Localizations.localeOf(context);
    final textTheme = Theme.of(context).textTheme;
    return [
      _StatGrid(
        tiles: [
          _StatTile(
            label: l10n.platformReportsTotalUsers,
            value: '${summary.totalUsers}',
            detail: l10n.platformReportsNewUsers(summary.newUsersInPeriod),
          ),
          _StatTile(
            label: l10n.platformReportsCompanies,
            value: '${summary.activeCompanyCount} / ${summary.companyCount}',
            detail: l10n.platformReportsActiveOfTotal,
          ),
          _StatTile(label: l10n.platformReportsBranches, value: '${summary.branchCount}'),
          _StatTile(label: l10n.platformReportsActiveMembers, value: '${summary.activeMemberCount}'),
          _StatTile(label: l10n.platformReportsTrainers, value: '${summary.trainerCount}'),
          _StatTile(label: l10n.platformReportsStaff, value: '${summary.staffCount}'),
          _StatTile(label: l10n.platformReportsPackageSales, value: '${summary.packageSalesInPeriod}'),
          _StatTile(
            label: l10n.platformReportsRevenue,
            value: formatMoney(summary.revenueInPeriod, summary.currency, locale),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.platformReportsUserGrowth, style: textTheme.labelSmall),
            const SizedBox(height: AppSpacing.md),
            if (summary.userGrowth.every((point) => point.newUsers == 0))
              Text(l10n.platformReportsUserGrowthEmpty, style: textTheme.bodyMedium)
            else
              _UserGrowthChart(points: summary.userGrowth),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      Text(l10n.platformReportsCompanyList, style: textTheme.titleMedium),
      const SizedBox(height: AppSpacing.sm),
      if (summary.companies.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Text(l10n.platformReportsNoCompanies, style: textTheme.bodyMedium),
        )
      else
        for (final company in summary.companies)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _CompanyRow(company: company, currency: summary.currency),
          ),
    ];
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.tiles});

  final List<_StatTile> tiles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - AppSpacing.md) / 2;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [for (final tile in tiles) SizedBox(width: tileWidth, child: tile)],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, this.detail});

  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.labelSmall),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: textTheme.titleLarge),
          ),
          if (detail != null)
            Text(detail!, style: textTheme.bodySmall?.copyWith(color: AppColors.onBackgroundFaint)),
        ],
      ),
    );
  }
}

/// Günlük yeni kullanıcı sayısı için sade çubuk grafik - tek aksan rengi,
/// sol üstte en yüksek değer, altta ilk ve son tarih. Ek bağımlılık yok.
class _UserGrowthChart extends StatelessWidget {
  const _UserGrowthChart({required this.points});

  final List<UserGrowthPoint> points;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final axisStyle = textTheme.bodySmall?.copyWith(color: AppColors.onBackgroundFaint);
    final maxValue = points.map((point) => point.newUsers).fold<int>(0, math.max);
    final total = points.fold<int>(0, (sum, point) => sum + point.newUsers);

    return Semantics(
      label: '${points.length} / $total',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('$maxValue', style: axisStyle),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 120,
            child: CustomPaint(painter: _BarChartPainter(points: points, maxValue: maxValue)),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Text(_axisDateFormat.format(points.first.date), style: axisStyle),
              const Spacer(),
              Text(_axisDateFormat.format(points.last.date), style: axisStyle),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({required this.points, required this.maxValue});

  final List<UserGrowthPoint> points;
  final int maxValue;

  @override
  void paint(Canvas canvas, Size size) {
    final baseline = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), baseline);
    if (points.isEmpty || maxValue == 0) return;

    final slot = size.width / points.length;
    final barWidth = math.max(1.0, math.min(slot * 0.7, 24.0));
    final barPaint = Paint()..color = AppColors.primary;
    for (var i = 0; i < points.length; i++) {
      final height = size.height * points[i].newUsers / maxValue;
      if (height <= 0) continue;
      final left = slot * i + (slot - barWidth) / 2;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(left, size.height - height, barWidth, height),
          topLeft: const Radius.circular(2),
          topRight: const Radius.circular(2),
        ),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter oldDelegate) => oldDelegate.points != points || oldDelegate.maxValue != maxValue;
}

/// Firma satırı: dokununca (ExpansionTile açılınca) şube kırılımı yüklenir.
class _CompanyRow extends StatelessWidget {
  const _CompanyRow({required this.company, required this.currency});

  final CompanyReportRow company;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: AppColors.onBackgroundMuted,
        collapsedIconColor: AppColors.onBackgroundFaint,
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
        childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        title: Row(
          children: [
            Expanded(child: Text(company.companyName, style: textTheme.titleMedium)),
            StatusPill(
              text: company.isActive ? l10n.companyManagementActiveBadge : l10n.companyManagementInactiveBadge,
              isPositive: company.isActive,
            ),
          ],
        ),
        subtitle: Text(
          '${l10n.platformReportsActiveMembers}: ${company.metrics.activeMemberCount} · '
          '${formatMoney(company.metrics.revenueInPeriod, currency, locale)}',
          style: textTheme.bodyMedium,
        ),
        children: [_BranchBreakdown(companyId: company.companyId, currency: currency)],
      ),
    );
  }
}

class _BranchBreakdown extends ConsumerWidget {
  const _BranchBreakdown({required this.companyId, required this.currency});

  final int companyId;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final textTheme = Theme.of(context).textTheme;
    final branchesAsync = ref.watch(companyBranchReportProvider(companyId));

    return branchesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (error, stackTrace) => Column(
        children: [
          Text(error is ApiException ? error.localizedMessage(context) : l10n.commonError),
          TextButton(
            onPressed: () => ref.invalidate(companyBranchReportProvider(companyId)),
            child: Text(l10n.commonRetry),
          ),
        ],
      ),
      data: (branches) => branches.isEmpty
          ? Align(
              alignment: Alignment.centerLeft,
              child: Text(l10n.platformReportsNoBranches, style: textTheme.bodyMedium),
            )
          : Column(
              children: [
                for (final branch in branches) ...[
                  const Divider(color: AppColors.border, height: AppSpacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(branch.branchName, style: textTheme.bodyLarge),
                            Text(
                              l10n.platformReportsMetricsLine(
                                branch.metrics.activeMemberCount,
                                branch.metrics.trainerCount,
                                branch.metrics.staffCount,
                                branch.metrics.packageSalesInPeriod,
                              ),
                              style: textTheme.bodySmall?.copyWith(color: AppColors.onBackgroundFaint),
                            ),
                            Text(
                              formatMoney(branch.metrics.revenueInPeriod, currency, locale),
                              style: textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      StatusPill(
                        text: branch.isActive
                            ? l10n.companyManagementActiveBadge
                            : l10n.companyManagementInactiveBadge,
                        isPositive: branch.isActive,
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
      );
}
