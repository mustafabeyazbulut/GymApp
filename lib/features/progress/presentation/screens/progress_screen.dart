// lib/features/progress/presentation/screens/progress_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/account_frozen_state.dart';
import '../../../../core/widgets/circular_stat_gauge.dart';
import '../../../../core/widgets/empty_membership_state.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/domain/auth_exceptions.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../domain/progress_summary.dart';
import '../providers/progress_summary_provider.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  ProgressCategory _selectedCategory = ProgressCategory.bjj;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.progressTitle)),
      body: ref.watch(currentUserProvider).when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error is AuthException ? error.message : l10n.commonError,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(
                  onPressed: () => ref.invalidate(currentUserProvider),
                  child: Text(l10n.commonRetry),
                ),
              ],
            ),
          ),
        ),
        data: (currentUser) {
          if (currentUser.isAccountFrozen) {
            return const AccountFrozenState();
          }
          if (!currentUser.hasActiveMembership) {
            return const EmptyMembershipState();
          }
          final summaryAsync = ref.watch(progressSummaryProvider(_selectedCategory));
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _CategoryTab(
                        label: l10n.progressCategoryBjj,
                        selected: _selectedCategory == ProgressCategory.bjj,
                        onTap: () => setState(() => _selectedCategory = ProgressCategory.bjj),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _CategoryTab(
                        label: l10n.progressCategoryFitness,
                        selected: _selectedCategory == ProgressCategory.fitness,
                        onTap: () => setState(() => _selectedCategory = ProgressCategory.fitness),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: summaryAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (error, stackTrace) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            error is ApiException ? error.message : l10n.commonError,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          OutlinedButton(
                            onPressed: () => ref.invalidate(progressSummaryProvider(_selectedCategory)),
                            child: Text(l10n.commonRetry),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (summary) => _ProgressContent(l10n: l10n, summary: summary),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTapTarget),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: selected ? AppColors.successSurface : AppColors.surface,
            border: selected ? null : Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? AppColors.primary : AppColors.onBackground,
                ),
          ),
        ),
      ),
    );
  }
}

class _ProgressContent extends StatelessWidget {
  const _ProgressContent({required this.l10n, required this.summary});

  final AppLocalizations l10n;
  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                const Icon(Icons.military_tech_outlined, color: AppColors.onBackgroundFaint, size: 32),
                const SizedBox(height: AppSpacing.sm),
                Text(summary.achievementTitle, style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '"${summary.achievementQuote}"',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.progressMonthLabel, style: textTheme.labelSmall),
                Text(l10n.progressClassesCount(summary.classesThisMonth), style: textTheme.titleMedium),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.progressAreasLabel, style: textTheme.labelSmall),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            CircularStatGauge(
              value: summary.techniqueValue,
              color: AppColors.primary,
              label: l10n.progressTechnique,
            ),
            CircularStatGauge(
              value: summary.attendanceValue,
              color: AppColors.secondary,
              label: l10n.progressAttendance,
            ),
            CircularStatGauge(
              value: summary.conditionValue,
              color: AppColors.onBackground,
              label: l10n.progressCondition,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.progressTrainerNoteLabel, style: textTheme.labelSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(summary.trainerNoteText, style: textTheme.bodyLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${summary.trainerNoteAuthor} · ${summary.trainerNoteDate}',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
