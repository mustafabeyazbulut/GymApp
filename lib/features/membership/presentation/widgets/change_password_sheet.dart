import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/data/real_auth_repository.dart';
import '../../../auth/domain/auth_exceptions.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';

Future<void> showChangePasswordSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
    ),
    builder: (context) => const _ChangePasswordSheet(),
  );
}

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      await ref.read(authRepositoryProvider).changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.profileChangePasswordSuccessMessage)));
      // Sunucu bu değişiklikte TÜM refresh token'ları iptal ediyor (bkz.
      // ChangePasswordCommandHandler) - mevcut oturum da dahil, bu yüzden
      // kullanıcıyı burada proaktif olarak çıkışa yönlendirmek, sessiz bir
      // refresh başarısızlığının sonraki bir ekranda beklenmedik şekilde
      // login'e düşmesini beklemekten daha net bir deneyim.
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      await ref.read(authStateProvider.notifier).logOut();
    } on AuthException catch (exception) {
      if (!mounted) return;
      setState(() => _errorText = exception.localizedMessage(context));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.profileChangePasswordTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: l10n.profileCurrentPasswordLabel),
                validator: (value) => value == null || value.isEmpty ? l10n.commonFieldRequired : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: l10n.profileNewPasswordLabel),
                validator: (value) {
                  if (value == null || value.isEmpty) return l10n.commonFieldRequired;
                  if (value.length < 8) return l10n.registerPasswordTooShort;
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: l10n.registerConfirmPasswordLabel),
                validator: (value) {
                  if (value == null || value.isEmpty) return l10n.commonFieldRequired;
                  if (value != _newPasswordController.text) return l10n.registerPasswordMismatch;
                  return null;
                },
              ),
              if (_errorText != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_errorText!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.error)),
              ],
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                      )
                    : Text(l10n.profileChangePasswordSubmitButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
