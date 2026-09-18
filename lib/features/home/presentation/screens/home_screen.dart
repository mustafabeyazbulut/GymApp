import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/membership_context_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/account_frozen_state.dart';
import '../../../../core/widgets/app_header_bar.dart';
import '../../../../core/widgets/empty_membership_state.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/domain/auth_exceptions.dart';
import '../../../auth/domain/me_result.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../membership/domain/membership_summary.dart';
import '../../../membership/presentation/widgets/membership_switcher.dart';
import '../../domain/home_summary.dart';
import '../providers/home_summary_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppHeaderBar(title: l10n.appTitle),
      body: currentUserAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, stackTrace) => _ErrorRetry(
          message: error is AuthException ? error.message : l10n.commonError,
          onRetry: () => ref.invalidate(currentUserProvider),
        ),
        data: (currentUser) {
          if (currentUser.isAccountFrozen) {
            return const AccountFrozenState();
          }
          final membershipsAsync = ref.watch(membershipsProvider);
          return membershipsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (error, stackTrace) => _ErrorRetry(
              message: error is ApiException ? error.message : l10n.commonError,
              onRetry: () => ref.invalidate(membershipsProvider),
            ),
            data: (memberships) {
              if (memberships.isEmpty) {
                return const EmptyMembershipState();
              }
              final selectedId = ref.watch(selectedMembershipIdProvider) ?? memberships.first.id;
              final selected = memberships.firstWhere((m) => m.id == selectedId, orElse: () => memberships.first);

              final summaryAsync = ref.watch(homeSummaryProvider);
              return summaryAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (error, stackTrace) => _ErrorRetry(
                  message: error is ApiException ? error.message : l10n.commonError,
                  onRetry: () => ref.invalidate(homeSummaryProvider),
                ),
                data: (summary) => _HomeContent(
                  l10n: l10n,
                  currentUser: currentUser,
                  memberships: memberships,
                  selectedId: selected.id,
                  summary: summary,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({
    required this.l10n,
    required this.currentUser,
    required this.memberships,
    required this.selectedId,
    required this.summary,
  });

  final AppLocalizations l10n;
  final MeResult currentUser;
  final List<MembershipSummary> memberships;
  final int selectedId;
  final HomeSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).languageCode;
    final greetingName = currentUser.fullName.trim().split(' ').first;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(l10n.homeGreeting(greetingName), style: textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.homeSubtitle, style: textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.lg),
        MembershipSwitcher(
          label: l10n.membershipSwitcherLabel,
          memberships: memberships,
          selectedId: selectedId,
          onSelect: (id) => ref.read(selectedMembershipIdProvider.notifier).select(id),
        ),
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
                  Expanded(child: Text(summary.packageName, style: textTheme.titleMedium)),
                  StatusPill(
                    text: summary.daysLeft == null ? l10n.homeNoExpiryLabel : l10n.homeDaysLeft(summary.daysLeft!),
                    isPositive: true,
                  ),
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
              if (summary.nextReservation == null)
                Text(l10n.homeNoUpcomingReservation, style: textTheme.bodyMedium)
              else ...[
                Text(
                  DateFormat('dd.MM.yyyy HH:mm', locale).format(summary.nextReservation!.scheduledAt),
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.homeNextClassTrainerLabel(summary.nextReservation!.trainerName),
                  style: textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ElevatedButton(
          // Branch index 1 = Dersler, Task 16'nın StatefulShellRoute
          // branch sırasına göre (home, classes, progress, membership).
          onPressed: () => StatefulNavigationShell.of(context).goBranch(1),
          child: Text(l10n.homeReservationButton),
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
                  for (final (day, attended) in summary.weeklyAttendance)
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
                          Text(
                            DateFormat.E(locale).format(day),
                            style: textTheme.labelSmall?.copyWith(fontSize: 8),
                          ),
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

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
          ],
        ),
      ),
    );
  }
}
