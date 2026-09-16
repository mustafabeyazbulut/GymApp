// lib/features/membership/presentation/screens/membership_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/locale/app_locale_provider.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/account_frozen_state.dart';
import '../../../../core/widgets/empty_membership_state.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/data/real_auth_repository.dart';
import '../../../auth/domain/auth_exceptions.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
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
  bool _isDeletingAccount = false;
  bool _isChangingLanguage = false;
  bool _isFreezingAccount = false;

  Future<void> _pickLanguage() async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.settingsLanguagePickerTitle),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop('tr'),
            child: const Text('Türkçe'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop('en'),
            child: const Text('English'),
          ),
        ],
      ),
    );

    if (selected == null || !mounted) return;

    setState(() => _isChangingLanguage = true);
    try {
      await ref.read(authRepositoryProvider).updatePreferredLanguage(selected);
      if (!mounted) return;
      ref.read(appLocaleProvider.notifier).setLocale(Locale(selected));
    } on AuthException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.message)));
    } finally {
      if (mounted) setState(() => _isChangingLanguage = false);
    }
  }

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

  Future<void> _confirmAndFreezeAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.accountFreezeConfirmTitle),
        content: Text(l10n.accountFreezeConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.accountDeletionCancelButton),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.accountFreezeConfirmButton),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isFreezingAccount = true);
    try {
      await ref.read(authRepositoryProvider).freezeAccount();
      if (!mounted) return;
      // freezeAccount() already revoked every refresh token server-side;
      // logOut() just clears the now-stale local copy.
      await ref.read(authStateProvider.notifier).logOut();
    } on AuthException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.message)));
    } finally {
      if (mounted) setState(() => _isFreezingAccount = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.membershipTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: l10n.notificationsTitle,
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody(context, ref, l10n)),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
              // Same hairline-card language as the Payment History card
              // below (border: AppColors.border, radius: AppSpacing.radiusLg,
              // labelSmall eyebrow) - kept here, outside the
              // active-membership-only ListView, for the same reachability
              // reason as Log Out: a freshly registered account with no
              // membership yet must still be able to reach these.
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
                            child: Text(l10n.settingsAccountSectionTitle, style: Theme.of(context).textTheme.labelSmall),
                          ),
                          _SettingsRow(
                            label: l10n.settingsLanguageLabel,
                            trailingText: _languageDisplayName(context),
                            isLoading: _isChangingLanguage,
                            onTap: _isChangingLanguage ? null : _pickLanguage,
                          ),
                          Container(height: 1, color: AppColors.border),
                          _SettingsRow(
                            label: l10n.accountFreezeButton,
                            isLoading: _isFreezingAccount,
                            onTap: _isFreezingAccount ? null : _confirmAndFreezeAccount,
                          ),
                          Container(height: 1, color: AppColors.border),
                          _SettingsRow(
                            label: l10n.accountDeletionButton,
                            labelColor: AppColors.error,
                            isLoading: _isDeletingAccount,
                            onTap: _isDeletingAccount ? null : _confirmAndDeleteAccount,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton(
                    onPressed: () => ref.read(authStateProvider.notifier).logOut(),
                    child: Text(l10n.commonLogOut),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _languageDisplayName(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'en' ? 'English' : 'Türkçe';

  // Kept as its own persistent bottom element (see build()), reachable
  // regardless of loading/error/empty-membership/active-membership state -
  // previously logOut() was only reachable via the delete-account flow deep
  // inside the active-membership branch, leaving no way out for an account
  // with no membership yet.
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

/// A tappable settings row matching the mockup's hairline-card language —
/// label on the left, either a plain chevron or a trailing value (e.g. the
/// current language name) + chevron on the right, swapped for a spinner
/// while [isLoading].
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    required this.onTap,
    this.trailingText,
    this.labelColor,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final String? trailingText;
  final Color? labelColor;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: labelColor),
            ),
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onBackgroundFaint),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (trailingText != null) ...[
                    Text(trailingText!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onBackgroundFaint)),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  const Icon(Icons.chevron_right, size: 18, color: AppColors.onBackgroundFaint),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

