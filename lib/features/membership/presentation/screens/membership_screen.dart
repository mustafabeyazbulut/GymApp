// lib/features/membership/presentation/screens/membership_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/account_frozen_state.dart';
import '../../../../core/widgets/app_header_bar.dart';
import '../../../../core/widgets/empty_membership_state.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/domain/auth_exceptions.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../domain/membership_summary.dart';
import '../providers/membership_provider.dart';

class MembershipScreen extends ConsumerStatefulWidget {
  const MembershipScreen({super.key});

  @override
  ConsumerState<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends ConsumerState<MembershipScreen> {
  bool _isFreezing = false;

  Future<void> _requestFreeze() async {
    setState(() => _isFreezing = true);
    try {
      await ref.read(membershipProvider.notifier).requestFreeze();
    } finally {
      if (mounted) setState(() => _isFreezing = false);
    }
  }

  void _renew() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.membershipRenewRequested)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppHeaderBar(title: l10n.navMembership),
      body: _buildBody(context, ref, l10n),
    );
  }

  // Account settings (language, freeze, delete) and Log Out moved to
  // AppDrawer — reachable from every screen's header menu button now,
  // regardless of this screen's loading/error/empty-membership state.
  Widget _buildBody(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return ref.watch(currentUserProvider).when(
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
          final membershipAsync = ref.watch(membershipProvider);
          return membershipAsync.when(
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
                      onPressed: () => ref.invalidate(membershipProvider),
                      child: Text(l10n.commonRetry),
                    ),
                  ],
                ),
              ),
            ),
            data: (summary) => ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(summary.packageName, style: Theme.of(context).textTheme.titleMedium),
                            ),
                            StatusPill(
                              text: summary.status == MembershipStatus.active
                                  ? l10n.membershipActiveStatus
                                  : l10n.membershipFrozenStatus,
                              isPositive: summary.status == MembershipStatus.active,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${summary.startDate} – ${summary.endDate}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.only(top: AppSpacing.md),
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: AppColors.border)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(summary.price, style: Theme.of(context).textTheme.titleMedium),
                              if (summary.isPaid)
                                StatusPill(text: l10n.membershipPaidStatus, isPositive: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton(onPressed: _renew, child: Text(l10n.membershipRenewButton)),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton(
                  onPressed: summary.status == MembershipStatus.frozen || _isFreezing
                      ? null
                      : _requestFreeze,
                  child: _isFreezing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onBackground),
                        )
                      : Text(
                          summary.status == MembershipStatus.frozen
                              ? l10n.membershipFrozenButton
                              : l10n.membershipFreezeButton,
                        ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.membershipPaymentHistoryLabel, style: Theme.of(context).textTheme.labelSmall),
                        const SizedBox(height: AppSpacing.sm),
                        for (final entry in summary.paymentHistory)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.date, style: Theme.of(context).textTheme.bodyMedium),
                                Text(entry.amount, style: Theme.of(context).textTheme.bodyLarge),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
  }
}

