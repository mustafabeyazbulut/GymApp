import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/format/money_format.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/revenue_report.dart';
import '../providers/reports_providers.dart';

final _dateFormat = DateFormat('dd.MM.yyyy');
// Tutarlar uygulamanın diline göre biçimlenir (tr: ₺1.234,50, en: ₺1,234.50).
String _price(BuildContext context, num amount) => formatMoney(amount, 'TRY', Localizations.localeOf(context));

class RevenueReportScreen extends ConsumerWidget {
  const RevenueReportScreen({super.key});

  Future<void> _pickRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
    );
    if (picked == null) return;
    await ref.read(revenueReportProvider.notifier).setRange(fromDate: picked.start, toDate: picked.end);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final reportAsync = ref.watch(revenueReportProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportsRevenueTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range_outlined),
            tooltip: l10n.reportsRevenuePickRangeButton,
            onPressed: () => _pickRange(context, ref),
          ),
        ],
      ),
      body: reportAsync.when(
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
                  onPressed: () => ref.invalidate(revenueReportProvider),
                  child: Text(l10n.commonRetry),
                ),
              ],
            ),
          ),
        ),
        data: (report) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              l10n.reportsRevenueRangeLabel(_dateFormat.format(report.fromDate), _dateFormat.format(report.toDate)),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onBackgroundFaint),
            ),
            const SizedBox(height: AppSpacing.md),
            _TotalCard(l10n: l10n, report: report),
            const SizedBox(height: AppSpacing.md),
            _MethodBreakdownCard(l10n: l10n, report: report),
            const SizedBox(height: AppSpacing.md),
            _DailyBreakdownCard(l10n: l10n, report: report),
          ],
        ),
      ),
    );
  }
}

String _methodLabel(AppLocalizations l10n, String method) => switch (method) {
      'Cash' => l10n.recordPaymentMethodCash,
      'Card' => l10n.recordPaymentMethodCard,
      'BankTransfer' => l10n.recordPaymentMethodBankTransfer,
      _ => method,
    };

class _Card extends StatelessWidget {
  const _Card({required this.icon, required this.label, required this.children});

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

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.l10n, required this.report});

  final AppLocalizations l10n;
  final RevenueReport report;

  @override
  Widget build(BuildContext context) {
    return _Card(
      icon: Icons.payments_outlined,
      label: l10n.reportsRevenueTotalLabel,
      children: [
        Text(_price(context, report.totalAmount), style: Theme.of(context).textTheme.headlineMedium),
      ],
    );
  }
}

class _MethodBreakdownCard extends StatelessWidget {
  const _MethodBreakdownCard({required this.l10n, required this.report});

  final AppLocalizations l10n;
  final RevenueReport report;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _Card(
      icon: Icons.pie_chart_outline,
      label: l10n.reportsRevenueMethodBreakdownLabel,
      children: [
        if (report.methodBreakdown.isEmpty)
          Text(
            l10n.reportsRevenueEmptyMessage,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.onBackgroundFaint),
          )
        else
          for (final entry in report.methodBreakdown) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_methodLabel(l10n, entry.method), style: textTheme.bodyLarge),
                Text(_price(context, entry.amount), style: textTheme.titleMedium),
              ],
            ),
            if (entry != report.methodBreakdown.last) const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}

class _DailyBreakdownCard extends StatelessWidget {
  const _DailyBreakdownCard({required this.l10n, required this.report});

  final AppLocalizations l10n;
  final RevenueReport report;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _Card(
      icon: Icons.calendar_month_outlined,
      label: l10n.reportsRevenueDailyBreakdownLabel,
      children: [
        if (report.dailyBreakdown.isEmpty)
          Text(
            l10n.reportsRevenueEmptyMessage,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.onBackgroundFaint),
          )
        else
          for (final entry in report.dailyBreakdown) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_dateFormat.format(entry.date), style: textTheme.bodyLarge),
                Text(_price(context, entry.amount), style: textTheme.titleMedium),
              ],
            ),
            if (entry != report.dailyBreakdown.last) const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}
