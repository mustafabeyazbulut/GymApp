import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/real_auth_repository.dart';
import '../../domain/auth_exceptions.dart';
import '../providers/auth_state_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _hasInvalidCredentialsError = false;
  bool _hasNetworkError = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _hasInvalidCredentialsError = false;
      _hasNetworkError = false;
    });
    try {
      await ref.read(authRepositoryProvider).login(
            identifier: _identifierController.text,
            password: _passwordController.text,
          );
      if (!mounted) return;
      ref.read(authStateProvider.notifier).logIn();
    } on InvalidCredentialsException {
      if (!mounted) return;
      setState(() => _hasInvalidCredentialsError = true);
    } on NetworkAuthException {
      if (!mounted) return;
      setState(() => _hasNetworkError = true);
    } on AuthException {
      if (!mounted) return;
      setState(() => _hasNetworkError = true); // any other unmapped failure reads as connectivity, per the mockup's two-state design
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.4, -0.7),
            radius: 0.9,
            colors: [Color(0x248BC34A), AppColors.background],
            stops: [0.0, 0.6],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                child: Column(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                    Container(
                      width: 26,
                      height: 26,
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      transform: Matrix4.rotationZ(0.7854),
                      transformAlignment: Alignment.center,
                    ),
                    Text(
                      'MAT & MOVE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.loginWelcomeTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.loginSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _identifierController,
                              enabled: !_isSubmitting,
                              decoration: InputDecoration(
                                labelText: l10n.loginIdentifierLabel,
                                errorText: _hasInvalidCredentialsError ? '' : null,
                              ),
                              validator: (value) => (value == null || value.trim().isEmpty)
                                  ? l10n.commonFieldRequired
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              enabled: !_isSubmitting,
                              decoration: InputDecoration(
                                labelText: l10n.loginPasswordLabel,
                                errorText:
                                    _hasInvalidCredentialsError ? l10n.loginInvalidCredentialsError : null,
                              ),
                              validator: (value) => (value == null || value.trim().isEmpty)
                                  ? l10n.commonFieldRequired
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            ElevatedButton(
                              onPressed: _isSubmitting ? null : _submit,
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.onPrimary,
                                      ),
                                    )
                                  : Text(l10n.loginSubmitButton),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            TextButton(
                              onPressed: _isSubmitting ? null : () => context.push('/forgot-password'),
                              child: Text(l10n.loginForgotPassword, textAlign: TextAlign.center),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextButton(
                              onPressed: _isSubmitting ? null : () => context.push('/register'),
                              child: Text(l10n.loginNoAccount, textAlign: TextAlign.center),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_hasNetworkError)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 6, color: AppColors.error),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(l10n.commonNetworkError, style: Theme.of(context).textTheme.bodyMedium),
                            ),
                            TextButton(
                              onPressed: _isSubmitting ? null : _submit,
                              child: Text(l10n.loginRetryButton),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
