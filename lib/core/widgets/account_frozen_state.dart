import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../../features/auth/data/real_auth_repository.dart';
import '../../features/auth/domain/auth_exceptions.dart';
import '../../features/auth/presentation/providers/current_user_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import 'otp_code_dialog.dart';

/// Giriş yapmış kullanıcının kendi hesabı self-servis olarak dondurulmuşsa
/// 4 içerik ekranının her birinde normal içerik yerine gösterilir (üyelik
/// paketiyle ilgili olan ve hesabın giriş erişimiyle ilgili olmayan
/// EmptyMembershipState'ten farklıdır). Bu widget'ın "4 ekranın tamamına,
/// normal içerik kontrolünden önce devreye girer" örüntüsünü yansıtır.
class AccountFrozenState extends ConsumerStatefulWidget {
  const AccountFrozenState({super.key});

  @override
  ConsumerState<AccountFrozenState> createState() => _AccountFrozenStateState();
}

class _AccountFrozenStateState extends ConsumerState<AccountFrozenState> {
  bool _isReactivating = false;
  String? _errorText;

  Future<void> _reactivate() async {
    setState(() {
      _isReactivating = true;
      _errorText = null;
    });
    try {
      await ref.read(authRepositoryProvider).requestUnfreezeOtp();
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final code = await showOtpCodeDialog(
        context: context,
        title: l10n.accountActionOtpTitle,
        message: l10n.accountActionOtpMessage,
        codeLabel: l10n.accountActionOtpCodeLabel,
        submitLabel: l10n.accountActionOtpSubmitButton,
        cancelLabel: l10n.accountActionOtpCancelButton,
      );
      if (code == null || !mounted) return;

      await ref.read(authRepositoryProvider).reactivateAccount(code: code);
      if (!mounted) return;
      ref.invalidate(currentUserProvider);
    } on AuthException catch (exception) {
      if (!mounted) return;
      setState(() => _errorText = exception.localizedMessage(context));
    } finally {
      if (mounted) setState(() => _isReactivating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pause_circle_outline, size: 40, color: AppColors.onBackgroundFaint),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.accountFrozenTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.accountFrozenBody,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: _isReactivating ? null : _reactivate,
              child: _isReactivating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                    )
                  : Text(l10n.accountFrozenReactivateButton),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_errorText!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.error)),
            ],
          ],
        ),
      ),
    );
  }
}
