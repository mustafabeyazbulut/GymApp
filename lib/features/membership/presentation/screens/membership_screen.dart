// lib/features/membership/presentation/screens/membership_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/data/real_auth_repository.dart';
import '../../../auth/domain/auth_exceptions.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../domain/membership_summary.dart';
import '../providers/membership_provider.dart';

class MembershipScreen extends ConsumerStatefulWidget {
  const MembershipScreen({super.key});

  @override
  ConsumerState<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends ConsumerState<MembershipScreen> {
  bool _isFreezing = false;
  bool _isDeletingAccount = false;

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

  Future<void> _confirmAndDeleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.accountDeletionConfirmTitle),
        content: Text(l10n.accountDeletionConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.accountDeletionCancelButton),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.accountDeletionConfirmButton),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeletingAccount = true);
    try {
      await ref.read(authRepositoryProvider).deleteAccount();
      if (!mounted) return;
      // deleteAccount() already clears the token store; logOut() clears it again.
      // A second clear() on an already-cleared store is expected to be a no-op.
      await ref.read(authStateProvider.notifier).logOut();
    } on AuthException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.message)));
    } finally {
      if (mounted) setState(() => _isDeletingAccount = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final membershipAsync = ref.watch(membershipProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.membershipTitle)),
      body: membershipAsync.when(
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
            Card(
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
                        _StatusPill(
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
                            _StatusPill(text: l10n.membershipPaidStatus, isPositive: true),
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
            Card(
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
            const SizedBox(height: AppSpacing.xl),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              onPressed: _isDeletingAccount ? null : _confirmAndDeleteAccount,
              child: _isDeletingAccount
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
                    )
                  : Text(l10n.accountDeletionButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.isPositive});

  final String text;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: isPositive ? AppColors.successSurface : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isPositive ? AppColors.primary : AppColors.onBackgroundFaint,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
