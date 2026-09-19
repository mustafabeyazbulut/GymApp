import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/real_auth_repository.dart';
import '../../domain/auth_exceptions.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _Step { requestCode, resetPassword }

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  _Step _step = _Step.requestCode;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _identifierController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      await ref.read(authRepositoryProvider).forgotPassword(identifier: _identifierController.text.trim());
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.forgotPasswordCodeSentMessage)));
      setState(() => _step = _Step.resetPassword);
    } on AuthException catch (exception) {
      if (!mounted) return;
      setState(() => _errorText = exception.localizedMessage(context));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            identifier: _identifierController.text.trim(),
            code: _codeController.text.trim(),
            newPassword: _newPasswordController.text,
          );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.forgotPasswordSuccessMessage)));
      context.pop();
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

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                Text(l10n.forgotPasswordTitle, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.xl),
                TextFormField(
                  controller: _identifierController,
                  enabled: _step == _Step.requestCode,
                  decoration: InputDecoration(labelText: l10n.forgotPasswordIdentifierLabel),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? l10n.commonFieldRequired : null,
                ),
                if (_step == _Step.resetPassword) ...[
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _codeController,
                    decoration: InputDecoration(labelText: l10n.forgotPasswordCodeLabel),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty) ? l10n.commonFieldRequired : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(labelText: l10n.forgotPasswordNewPasswordLabel),
                    validator: (value) {
                      if (value == null || value.isEmpty) return l10n.commonFieldRequired;
                      if (value.length < 8) return l10n.registerPasswordTooShort;
                      return null;
                    },
                  ),
                ],
                if (_errorText != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(_errorText!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.error)),
                ],
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : (_step == _Step.requestCode ? _requestCode : _resetPassword),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                        )
                      : Text(_step == _Step.requestCode ? l10n.forgotPasswordSendCodeButton : l10n.forgotPasswordResetButton),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          if (_step == _Step.requestCode) {
                            context.pop();
                          } else {
                            setState(() {
                              _step = _Step.requestCode;
                              _codeController.clear();
                              _newPasswordController.clear();
                              _errorText = null;
                            });
                          }
                        },
                  child: Text(
                    _step == _Step.requestCode ? l10n.forgotPasswordBackToLogin : l10n.forgotPasswordChangeIdentifier,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
