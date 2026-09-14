import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/home_summary.dart';
import '../providers/home_summary_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summaryAsync = ref.watch(homeSummaryProvider);

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: const Text('GymApp')),
      body: summaryAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
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
                  onPressed: () => ref.invalidate(homeSummaryProvider),
                  child: Text(l10n.commonRetry),
                ),
              ],
            ),
          ),
        ),
        data: (summary) => _HomeContent(l10n: l10n, summary: summary),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.l10n, required this.summary});

  final AppLocalizations l10n;
  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(l10n.homeGreeting(summary.greetingName), style: textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.homeSubtitle, style: textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.homeActivePackageLabel, style: textTheme.labelSmall),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(summary.activePackageName, style: textTheme.titleMedium),
                    _Pill(text: l10n.homeDaysLeft(summary.daysLeft)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.homeNextClassLabel, style: textTheme.labelSmall),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${summary.nextClassName} · ${summary.nextClassTime}',
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('Eğitmen: ${summary.nextClassTrainer}', style: textTheme.bodyMedium),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                child: Text(l10n.homeReservationButton),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                child: Text(l10n.homeCheckInButton),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.homeWeeklyAttendanceLabel, style: textTheme.labelSmall),
                    Text(
                      l10n.homeWeeklyAttendanceCount(summary.attendedCount, 7),
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Bar + label are read from the same (label, attended)
                    // pair in one loop — see HomeSummary.weeklyAttendance's
                    // doc comment for why this isn't two same-length lists
                    // zipped by position.
                    for (final (label, attended) in summary.weeklyAttendance)
                      Expanded(
                        child: Column(
                          children: [
                            SizedBox(
                              height: 32,
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  height: attended ? 32 : 12,
                                  decoration: BoxDecoration(
                                    color: attended ? AppColors.primary : AppColors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(label, style: textTheme.labelSmall?.copyWith(fontSize: 8)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.successSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
