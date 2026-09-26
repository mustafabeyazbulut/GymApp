import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/format/localized_decimal.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/personal_log.dart';
import '../providers/personal_log_providers.dart';
import 'personal_log_sheet.dart';

final _dateFormat = DateFormat('dd.MM.yyyy');

// Kilo gidişatında gösterilen son ölçüm sayısı.
const _weightTrendLength = 5;

/// "Kişisel Takibim": kullanıcının gym'den bağımsız kendi antrenman ve ölçüm
/// kayıtları (ana senaryo §5.1). Paketi olsun olmasın her üye kullanır.
class PersonalTrackingSection extends ConsumerWidget {
  const PersonalTrackingSection({super.key});

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref, PersonalLog log) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.personalLogDeleteConfirmTitle),
        content: Text(l10n.personalLogDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.accountDeletionCancelButton),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.personalLogDeleteButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(personalLogActionsProvider.notifier).delete(log.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.personalLogDeletedMessage)));
    } on ApiException catch (exception) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.localizedMessage(context))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final logsAsync = ref.watch(personalLogsProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.refresh(personalLogsProvider.future),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          ElevatedButton.icon(
            onPressed: () => showPersonalLogSheet(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.personalLogAddButton),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...logsAsync.when(
            loading: () => [const Center(child: CircularProgressIndicator(color: AppColors.primary))],
            error: (error, stackTrace) => [
              Text(
                error is ApiException ? error.localizedMessage(context) : l10n.commonError,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: OutlinedButton(
                  onPressed: () => ref.invalidate(personalLogsProvider),
                  child: Text(l10n.commonRetry),
                ),
              ),
            ],
            data: (logs) {
              if (logs.isEmpty) {
                return [
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: Text(
                      l10n.personalLogEmptyMessage,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ];
              }
              final weights = logs.where((log) => log.weightKg != null).toList()
                ..sort((a, b) => b.date.compareTo(a.date));
              return [
                if (weights.isNotEmpty) ...[
                  _WeightTrendCard(weights: weights.take(_weightTrendLength + 1).toList()),
                  const SizedBox(height: AppSpacing.md),
                ],
                for (final log in logs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _PersonalLogCard(
                      log: log,
                      onEdit: () => showPersonalLogSheet(context, existing: log),
                      onDelete: () => _confirmAndDelete(context, ref, log),
                    ),
                  ),
              ];
            },
          ),
        ],
      ),
    );
  }
}

/// Son kilo ölçümleri, her biri bir öncekine göre farkıyla. Grafik yerine
/// sade bir liste - ek bağımlılık gerekmiyor.
class _WeightTrendCard extends StatelessWidget {
  // En yeniden eskiye; son satırın farkı için bir fazla öğe gelebilir.
  const _WeightTrendCard({required this.weights});

  final List<PersonalLog> weights;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final textTheme = Theme.of(context).textTheme;
    final visibleCount = weights.length > _weightTrendLength ? _weightTrendLength : weights.length;

    String delta(int index) {
      if (index + 1 >= weights.length) return '';
      final difference = weights[index].weightKg! - weights[index + 1].weightKg!;
      if (difference.abs() < 0.05) return '0';
      final sign = difference > 0 ? '+' : '−';
      return '$sign${formatLocalizedDecimal(difference.abs(), locale)}';
    }

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.personalLogWeightTrendTitle, style: textTheme.labelSmall),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < visibleCount; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(child: Text(_dateFormat.format(weights[i].date), style: textTheme.bodyMedium)),
                  Text('${formatLocalizedDecimal(weights[i].weightKg!, locale)} kg', style: textTheme.titleMedium),
                  SizedBox(
                    width: 56,
                    child: Text(
                      delta(i),
                      textAlign: TextAlign.end,
                      style: textTheme.bodyMedium?.copyWith(color: AppColors.onBackgroundMuted),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PersonalLogCard extends StatelessWidget {
  const _PersonalLogCard({required this.log, required this.onEdit, required this.onDelete});

  final PersonalLog log;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String _measurementSummary(Locale locale) => [
        if (log.weightKg != null) '${formatLocalizedDecimal(log.weightKg!, locale)} kg',
        if (log.bodyFatPercent != null) '%${formatLocalizedDecimal(log.bodyFatPercent!, locale)}',
        if (log.waistCm != null) '${formatLocalizedDecimal(log.waistCm!, locale)} cm',
      ].join(' · ');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final textTheme = Theme.of(context).textTheme;
    final isWorkout = log.kind == PersonalLogKind.workout;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: onEdit,
        child: _Card(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${isWorkout ? l10n.personalLogKindWorkout : l10n.personalLogKindMeasurement} · '
                      '${_dateFormat.format(log.date)}',
                      style: textTheme.labelSmall?.copyWith(color: AppColors.onBackgroundMuted),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (isWorkout) ...[
                      Text(log.title ?? '', style: textTheme.titleMedium),
                      if (log.durationMinutes != null)
                        Text(l10n.personalLogDurationValue(log.durationMinutes!), style: textTheme.bodyMedium),
                    ] else
                      Text(_measurementSummary(locale), style: textTheme.titleMedium),
                    if (log.notes != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(log.notes!, style: textTheme.bodyMedium?.copyWith(color: AppColors.onBackgroundFaint)),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.personalLogDeleteButton,
                icon: const Icon(Icons.delete_outline, color: AppColors.onBackgroundFaint),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  // Ink: kayıt kartı InkWell içinde - dolgulu kartta dokunma efekti görünsün.
  @override
  Widget build(BuildContext context) => Ink(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
      );
}
