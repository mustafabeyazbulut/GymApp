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
  final _networkErrorBarKey = GlobalKey();
  bool _isSubmitting = false;
  bool _hasInvalidCredentialsError = false;
  bool _hasNetworkError = false;

  // Reserved bottom space for the network-error bar while it's shown, so the
  // bar (painted last in the Stack, on top of the scroll view) never overlaps
  // and swallows taps on the Forgot-password/Sign-up links beneath it.
  //
  // A plain fixed constant here would be fragile under large accessibility
  // text-scale factors: the bar's Row (icon + message + retry button) can
  // grow taller than a guessed number, which would either force the bar's
  // real content into a too-small box or leave the reserved padding short of
  // the bar's actual height — reintroducing the same overlap bug. Instead we
  // start with a reasonable estimate and correct it to the bar's real
  // rendered height once it's been laid out (see
  // `_measureNetworkErrorBarHeight`), so the reserved padding always matches
  // reality regardless of text scale or locale string length.
  double _networkErrorBarHeight = 56.0;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _measureNetworkErrorBarHeight() {
    if (!mounted) return;
    final renderObject = _networkErrorBarKey.currentContext?.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize) {
      final measuredHeight = renderObject.size.height;
      if ((measuredHeight - _networkErrorBarHeight).abs() > 0.5) {
        setState(() => _networkErrorBarHeight = measuredHeight);
      }
    }
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
                padding: EdgeInsets.only(
                  top: AppSpacing.xxl,
                  bottom: AppSpacing.xxl + (_hasNetworkError ? _networkErrorBarHeight : 0),
                ),
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
                                // Empty string (not null) — forces the red error-state styling and
                                // reserves the same error-line height as the password field below,
                                // without duplicating the error message on both fields. The real
                                // message only shows under the password field, per the approved mockup.
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
                  child: Builder(
                    builder: (context) {
                      // Re-measure after every frame this bar is shown; the
                      // setState in _measureNetworkErrorBarHeight only fires
                      // when the measured height actually changed, so this
                      // converges after a frame or two instead of looping.
                      WidgetsBinding.instance.addPostFrameCallback((_) => _measureNetworkErrorBarHeight());
                      return DecoratedBox(
                        key: _networkErrorBarKey,
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          border: Border(top: BorderSide(color: AppColors.border)),
                        ),
                        child: SafeArea(
                          top: false,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                            child: Row(
                              children: [
                                const Icon(Icons.circle, size: 6, color: AppColors.error),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    l10n.commonNetworkError,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                                TextButton(
                                  onPressed: _isSubmitting ? null : _submit,
                                  child: Text(l10n.commonRetry),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
