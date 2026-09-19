import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/real_auth_repository.dart';
import '../../domain/auth_exceptions.dart';
import '../providers/auth_state_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

enum _Step { requestOtp, completeRegistration }

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneCodeController = TextEditingController();
  final _emailCodeController = TextEditingController();
  _Step _step = _Step.requestOtp;
  String? _phone;
  bool _isSubmitting = false;
  String? _errorText;

  bool get _hasEmail => _emailController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneCodeController.dispose();
    _emailCodeController.dispose();
    super.dispose();
  }

  bool _ensurePhoneEntered() {
    if (_phone == null || _phone!.trim().isEmpty) {
      setState(() => _errorText = AppLocalizations.of(context)!.commonFieldRequired);
      return false;
    }
    return true;
  }

  Future<void> _requestOtp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_ensurePhoneEntered()) return;

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      await ref.read(authRepositoryProvider).requestRegistrationOtp(
            phone: _phone!,
            email: _hasEmail ? _emailController.text.trim() : null,
          );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_hasEmail ? l10n.registerCodeSentBothMessage : l10n.registerCodeSentPhoneOnlyMessage),
      ));
      setState(() => _step = _Step.completeRegistration);
    } on AuthException catch (exception) {
      if (!mounted) return;
      setState(() => _errorText = exception.localizedMessage(context));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _completeRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_ensurePhoneEntered()) return;

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      await ref.read(authRepositoryProvider).completeRegistration(
            fullName: _fullNameController.text.trim(),
            phone: _phone!,
            phoneCode: _phoneCodeController.text.trim(),
            email: _hasEmail ? _emailController.text.trim() : null,
            emailCode: _hasEmail ? _emailCodeController.text.trim() : null,
            password: _passwordController.text,
          );
      if (!mounted) return;
      ref.read(authStateProvider.notifier).logIn();
    } on AuthException catch (exception) {
      if (!mounted) return;
      setState(() => _errorText = exception.localizedMessage(context));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _backToRequestOtp() {
    setState(() {
      _step = _Step.requestOtp;
      _phoneCodeController.clear();
      _emailCodeController.clear();
      _errorText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final inStep1 = _step == _Step.requestOtp;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.06),
                Text(l10n.registerTitle, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.xl),
                TextFormField(
                  controller: _fullNameController,
                  enabled: inStep1,
                  decoration: InputDecoration(labelText: l10n.registerFullNameLabel),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? l10n.commonFieldRequired : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                IntlPhoneField(
                  enabled: inStep1,
                  initialCountryCode: 'TR',
                  decoration: InputDecoration(labelText: l10n.registerPhoneLabel),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (phone) => _phone = phone.completeNumber,
                  validator: (phone) =>
                      (phone == null || phone.number.trim().isEmpty) ? l10n.commonFieldRequired : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _emailController,
                  enabled: inStep1,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: l10n.registerEmailLabel),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final trimmed = value.trim();
                    final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed);
                    return isValid ? null : l10n.registerEmailInvalid;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _passwordController,
                  enabled: inStep1,
                  obscureText: true,
                  decoration: InputDecoration(labelText: l10n.registerPasswordLabel),
                  validator: (value) {
                    if (value == null || value.isEmpty) return l10n.commonFieldRequired;
                    if (value.length < 8) return l10n.registerPasswordTooShort;
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _confirmPasswordController,
                  enabled: inStep1,
                  obscureText: true,
                  decoration: InputDecoration(labelText: l10n.registerConfirmPasswordLabel),
                  validator: (value) {
                    if (value == null || value.isEmpty) return l10n.commonFieldRequired;
                    if (value != _passwordController.text) return l10n.registerPasswordMismatch;
                    return null;
                  },
                ),
                if (!inStep1) ...[
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _phoneCodeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: InputDecoration(labelText: l10n.registerPhoneCodeLabel),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty) ? l10n.commonFieldRequired : null,
                  ),
                  if (_hasEmail) ...[
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _emailCodeController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: InputDecoration(labelText: l10n.registerEmailCodeLabel),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty) ? l10n.commonFieldRequired : null,
                    ),
                  ],
                ],
                if (_errorText != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(_errorText!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.error)),
                ],
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : (inStep1 ? _requestOtp : _completeRegistration),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                        )
                      : Text(inStep1 ? l10n.registerSendCodeButton : l10n.registerSubmitButton),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextButton(
                  onPressed: _isSubmitting ? null : (inStep1 ? () => context.pop() : _backToRequestOtp),
                  child: Text(
                    inStep1 ? l10n.registerHaveAccount : l10n.registerChangeDetails,
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
