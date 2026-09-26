import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/analytics_summary.dart';
import '../providers/analytics_providers.dart';

/// StaffManagement (GymAdmin/BranchManager/SuperAdmin) için salt-okunur bir
/// raporlama özeti - GET /api/analytics/summary. Kapsam tamamen backend'in
/// ambient ITenantContext'inden geliyor, bu ekranın kendi bir filtre/tarih
/// seçici GEREKMİYOR (bkz. docs/superpowers/specs/2026-09-20-analytics-design.md
/// "Kapsam Dışı": "Özelleştirilebilir tarih aralığı seçimi").
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summaryAsync = ref.watch(analyticsSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.analyticsTitle)),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error is ApiException ? error.localizedMessage(context) : l10n.commonError,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(
                  onPressed: () => ref.invalidate(analyticsSummaryProvider),
                  child: Text(l10n.commonRetry),
                ),
              ],
            ),
          ),
        ),
        data: (summary) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _ActiveMembersCard(l10n: l10n, metric: summary.activeMembers),
            const SizedBox(height: AppSpacing.md),
            _ClassOccupancyCard(l10n: l10n, metric: summary.classOccupancy),
            const SizedBox(height: AppSpacing.md),
            _PackageSalesCard(l10n: l10n, metric: summary.packageSales),
            const SizedBox(height: AppSpacing.md),
            _TrainerStudentsCard(l10n: l10n, trainers: summary.trainerActiveStudents),
          ],
        ),
      ),
    );
  }
}

String _categoryLabel(AppLocalizations l10n, String? category) => switch (category) {
      'GroupClass' => l10n.classSessionCategoryGroupClass,
      'MartialArts' => l10n.classSessionCategoryMartialArts,
      _ => l10n.analyticsPackageCategoryOther,
    };

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.label, required this.children});

  final IconData icon;
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.onBackgroundFaint),
              const SizedBox(width: AppSpacing.xs),
              Text(label, style: textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

class _ActiveMembersCard extends StatelessWidget {
  const _ActiveMembersCard({required this.l10n, required this.metric});

  final AppLocalizations l10n;
  final ActiveMemberMetric metric;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final trend = metric.trendPercentage;

    final (IconData? trendIcon, Color trendColor, String trendText) = trend == null
        ? (null, AppColors.onBackgroundFaint, l10n.analyticsTrendUnavailable)
        : trend == 0
            ? (null, AppColors.onBackgroundFaint, l10n.analyticsTrendFlat)
            : trend > 0
                ? (Icons.arrow_upward, AppColors.primary, l10n.analyticsTrendUp(trend.toStringAsFixed(1)))
                : (Icons.arrow_downward, AppColors.error, l10n.analyticsTrendDown(trend.abs().toStringAsFixed(1)));

    return _MetricCard(
      icon: Icons.groups_outlined,
      label: l10n.analyticsActiveMembersLabel,
      children: [
        Text('${metric.currentCount}', style: textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            if (trendIcon != null) ...[
              Icon(trendIcon, size: 14, color: trendColor),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(trendText, style: textTheme.bodyMedium?.copyWith(color: trendColor)),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.analyticsActiveMembersPreviousLabel(metric.countThirtyDaysAgo),
          style: textTheme.bodySmall?.copyWith(color: AppColors.onBackgroundFaint),
        ),
      ],
    );
  }
}

class _ClassOccupancyCard extends StatelessWidget {
  const _ClassOccupancyCard({required this.l10n, required this.metric});

  final AppLocalizations l10n;
  final ClassOccupancyMetric metric;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _MetricCard(
      icon: Icons.event_seat_outlined,
      label: l10n.analyticsClassOccupancyLabel,
      children: [
        Text('%${(metric.overallOccupancyRate * 100).toStringAsFixed(0)}', style: textTheme.headlineMedium),
        if (metric.classBreakdown.isEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.analyticsClassOccupancyEmptyMessage,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.onBackgroundFaint),
          ),
        ] else ...[
          const SizedBox(height: AppSpacing.md),
          for (final entry in metric.classBreakdown) ...[
            _ClassOccupancyRow(l10n: l10n, entry: entry),
            if (entry != metric.classBreakdown.last) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ],
    );
  }
}

class _ClassOccupancyRow extends StatelessWidget {
  const _ClassOccupancyRow({required this.l10n, required this.entry});

  final AppLocalizations l10n;
  final ClassOccupancyBreakdown entry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.className, style: textTheme.bodyLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(
                '${l10n.analyticsClassOccupancySessionCount(entry.sessionCount)} · '
                '${l10n.analyticsClassOccupancyEnrolledOfCapacity(entry.totalEnrolled, entry.totalCapacity)}',
                style: textTheme.bodySmall?.copyWith(color: AppColors.onBackgroundFaint),
              ),
            ],
          ),
        ),
        Text(
          '%${(entry.occupancyRate * 100).toStringAsFixed(0)}',
          style: textTheme.titleMedium?.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }
}

class _PackageSalesCard extends StatelessWidget {
  const _PackageSalesCard({required this.l10n, required this.metric});

  final AppLocalizations l10n;
  final PackageSalesMetric metric;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _MetricCard(
      icon: Icons.sell_outlined,
      label: l10n.analyticsPackageSalesLabel,
      children: [
        Text('${metric.totalCount}', style: textTheme.headlineMedium),
        if (metric.categoryBreakdown.isEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.analyticsPackageSalesEmptyMessage,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.onBackgroundFaint),
          ),
        ] else ...[
          const SizedBox(height: AppSpacing.md),
          for (final entry in metric.categoryBreakdown) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_categoryLabel(l10n, entry.category), style: textTheme.bodyLarge),
                Text('${entry.count}', style: textTheme.titleMedium),
              ],
            ),
            if (entry != metric.categoryBreakdown.last) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ],
    );
  }
}

class _TrainerStudentsCard extends StatelessWidget {
  const _TrainerStudentsCard({required this.l10n, required this.trainers});

  final AppLocalizations l10n;
  final List<TrainerActiveStudent> trainers;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _MetricCard(
      icon: Icons.school_outlined,
      label: l10n.analyticsTrainerStudentsLabel,
      children: [
        if (trainers.isEmpty)
          Text(
            l10n.analyticsTrainerStudentsEmptyMessage,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.onBackgroundFaint),
          )
        else
          for (final trainer in trainers) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    trainer.trainerFullName,
                    style: textTheme.bodyLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('${trainer.activeStudentCount}', style: textTheme.titleMedium),
              ],
            ),
            if (trainer != trainers.last) const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}
