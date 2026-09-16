import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/account_frozen_state.dart';
import '../../../../core/widgets/empty_membership_state.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/domain/auth_exceptions.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../domain/home_summary.dart';
import '../providers/home_summary_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: Text(l10n.appTitle)),
      body: currentUserAsync.when(
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
          final summaryAsync = ref.watch(homeSummaryProvider);
          return summaryAsync.when(
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
                      onPressed: () => ref.invalidate(homeSummaryProvider),
                      child: Text(l10n.commonRetry),
                    ),
                  ],
                ),
              ),
            ),
            data: (summary) => _HomeContent(l10n: l10n, summary: summary),
          );
        },
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
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.onBackgroundFaint),
                  const SizedBox(width: AppSpacing.xs),
                  Text(l10n.homeActivePackageLabel, style: textTheme.labelSmall),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(summary.activePackageName, style: textTheme.titleMedium),
                  StatusPill(text: l10n.homeDaysLeft(summary.daysLeft), isPositive: true),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_month_outlined, size: 14, color: AppColors.onBackgroundFaint),
                  const SizedBox(width: AppSpacing.xs),
                  Text(l10n.homeNextClassLabel, style: textTheme.labelSmall),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${summary.nextClassName} · ${summary.nextClassTime}',
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.homeNextClassTrainerLabel(summary.nextClassTrainer),
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                // Branch index 1 = Dersler, per Task 16's StatefulShellRoute
                // branch order (home, classes, progress, membership).
                onPressed: () => StatefulNavigationShell.of(context).goBranch(1),
                child: Text(l10n.homeReservationButton),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: OutlinedButton(
                // Deliberately a no-op — Faz 2 door-access check-in, not
                // built yet. Per spec, unlike Reservation, this one stays
                // silent for now.
                onPressed: () {},
                child: Text(l10n.homeCheckInButton),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
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
      ],
    );
  }
}
