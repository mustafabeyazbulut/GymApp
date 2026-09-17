import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/data/real_auth_repository.dart';
import '../../features/auth/domain/auth_exceptions.dart';
import '../../features/auth/presentation/providers/auth_state_provider.dart';
import '../../features/auth/presentation/providers/current_user_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../locale/app_locale_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'otp_code_dialog.dart';

/// The app's side navigation drawer, shared across every shell branch (see
/// `appShellScaffoldKey`) and opened from the header's menu button. Only
/// holds destinations that aren't already reachable elsewhere in the header
/// or bottom nav (Home/Classes/Progress/Profile, Notifications' own bell
/// icon) — account settings (moved here from the Profile screen) and Log Out.
class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  bool _isChangingLanguage = false;
  bool _isFreezingAccount = false;
  bool _isDeletingAccount = false;

  String _languageDisplayName(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'en' ? 'English' : 'Türkçe';

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
      await ref.read(authRepositoryProvider).requestFreezeOtp();
      if (!mounted) return;
      final code = await showOtpCodeDialog(
        context: context,
        title: l10n.accountActionOtpTitle,
        message: l10n.accountActionOtpMessage,
        codeLabel: l10n.accountActionOtpCodeLabel,
        submitLabel: l10n.accountActionOtpSubmitButton,
        cancelLabel: l10n.accountActionOtpCancelButton,
      );
      if (code == null || !mounted) return;

      await ref.read(authRepositoryProvider).freezeAccount(code: code);
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
      await ref.read(authRepositoryProvider).requestDeleteAccountOtp();
      if (!mounted) return;
      final code = await showOtpCodeDialog(
        context: context,
        title: l10n.accountActionOtpTitle,
        message: l10n.accountActionOtpMessage,
        codeLabel: l10n.accountActionOtpCodeLabel,
        submitLabel: l10n.accountActionOtpSubmitButton,
        cancelLabel: l10n.accountActionOtpCancelButton,
      );
      if (code == null || !mounted) return;

      await ref.read(authRepositoryProvider).deleteAccount(code: code);
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
    final currentUser = ref.watch(currentUserProvider).asData?.value;

    void closeThenRun(Future<void> Function() action) {
      Navigator.pop(context);
      action();
    }

    void closeThenPush(String location) {
      Navigator.pop(context);
      context.push(location);
    }

    return Drawer(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(AppSpacing.radiusLg)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      _initial(currentUser?.fullName),
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser?.fullName ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          currentUser?.email ?? currentUser?.phone ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.sm),
                children: [
                  _DrawerItem(
                    icon: Icons.language,
                    label: l10n.settingsLanguageLabel,
                    trailingText: _languageDisplayName(context),
                    isLoading: _isChangingLanguage,
                    onTap: _isChangingLanguage ? null : () => closeThenRun(_pickLanguage),
                  ),
                  _DrawerItem(
                    icon: Icons.pause_circle_outline,
                    label: l10n.accountFreezeButton,
                    showChevron: true,
                    isLoading: _isFreezingAccount,
                    onTap: _isFreezingAccount ? null : () => closeThenRun(_confirmAndFreezeAccount),
                  ),
                  _DrawerItem(
                    icon: Icons.delete_outline,
                    label: l10n.accountDeletionButton,
                    color: AppColors.error,
                    showChevron: true,
                    isLoading: _isDeletingAccount,
                    onTap: _isDeletingAccount ? null : () => closeThenRun(_confirmAndDeleteAccount),
                  ),
                  if (currentUser?.isSuperAdmin ?? false)
                    _DrawerItem(
                      icon: Icons.add_business_outlined,
                      label: l10n.drawerCreateCompany,
                      onTap: () => closeThenPush('/admin/create-company'),
                    ),
                  if (currentUser?.staffAssignment != null)
                    _DrawerItem(
                      icon: Icons.person_add_alt_outlined,
                      label: l10n.drawerAddStaffMember,
                      onTap: () => closeThenPush('/admin/add-staff-member'),
                    ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: _DrawerItem(
                icon: Icons.logout,
                label: l10n.commonLogOut,
                color: AppColors.error,
                onTap: () {
                  Navigator.pop(context);
                  ref.read(authStateProvider.notifier).logOut();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _initial(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return '?';
    return fullName.trim()[0].toUpperCase();
  }
}

/// A tappable drawer row — icon, label, and either nothing, a chevron, a
/// trailing value + chevron (e.g. the current language), or a spinner while
/// [isLoading].
class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.trailingText,
    this.isLoading = false,
    this.showChevron = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final String? trailingText;
  final bool isLoading;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color ?? AppColors.onBackgroundMuted),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500, color: color ?? AppColors.onBackground),
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onBackgroundFaint),
                )
              else if (trailingText != null || showChevron)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (trailingText != null) ...[
                      Text(
                        trailingText!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onBackgroundFaint),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    const Icon(Icons.chevron_right, size: 18, color: AppColors.onBackgroundFaint),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
