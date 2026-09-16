# Kayıtta Telefon/E-posta Doğrulama (Mobil) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the Register screen into a 2-step flow (request codes → enter codes to complete) backed by the new `register/request-otp` + `register/complete` backend endpoints, with a country-code phone picker and digit-only OTP fields, per `docs/superpowers/specs/2026-09-16-register-phone-verification-design.md`.

**Architecture:** One half of a two-repo feature. The backend half is planned separately at `C:\Users\MBEYAZBULUT\Documents\GitHub\GymAppApi\docs\superpowers\plans\2026-09-16-register-phone-verification.md`. This plan's Task 3 (`AuthRepository`/`RealAuthRepository`) is hard-blocked on that plan's Tasks 4–6 (the two new endpoints) being implemented and reachable at `http://localhost:5195` — run that plan first, or at minimum through its Task 6, before starting this one.

**Tech Stack:** Flutter/Dart, `dio`, `flutter_riverpod` (`@riverpod` codegen), `mocktail`... — actually this repo's test stack is `mocktail` for the presentation layer and `http_mock_adapter` for repository tests (already used in `real_auth_repository_test.dart`), same as the completed Real Auth plan. One new dependency: `intl_phone_field` (country-code phone picker).

---

## Grounding facts confirmed by reading the actual codebase (do not re-derive, do not contradict)

- `AuthRepository.register(...)` is called from exactly one place: `RegisterScreen._submit()`. `RealAuthRepository` is the only production implementation; `current_user_provider_test.dart` uses a `mocktail` `class _MockAuthRepository extends Mock implements AuthRepository {}` — `Mock` auto-satisfies any interface shape, so changing the interface does not require touching that test file.
- `real_auth_repository_test.dart` already uses `+905551112233`-style E.164 phone numbers in its login/getMe fixtures (written before this plan, for the *login* identifier field, which stays free text) — this is existing precedent, not something this plan introduces to that file.
- `_mapException` in `real_auth_repository.dart` currently maps **every** `401` unconditionally to the hardcoded `InvalidCredentialsException()` ("Telefon numarası/e-posta veya şifre hatalı."). `register/complete`'s `401` means "wrong OTP code" (backend's own message already says which channel — phone/email/both), so mapping it through the same hardcoded path would show a misleading "wrong password" message on a brand-new registration attempt. **Task 3 fixes `_mapException` to check the request path** for this one case; every other `401` (login) keeps the existing hardcoded message unchanged.
- `l10n.yaml`'s `template-arb-file` is `app_tr.arb` — it carries `"@key": {}` metadata stubs after every string entry; `app_en.arb` (translation-only) does not. Follow that asymmetry exactly when adding new keys.
- `ForgotPasswordScreen` (`lib/features/auth/presentation/screens/forgot_password_screen.dart`) is the direct structural template for the new 2-step `RegisterScreen`: one `Form`, a `_Step` enum, disabled-not-hidden fields in step 2, a bottom `TextButton` that both goes back to step 1 and (on step 1) navigates away.
- `IntlPhoneField` (package `intl_phone_field`, confirmed from its source): `validator: FutureOr<String?> Function(PhoneNumber?)?`, `enabled: bool` (default `true`), `onChanged: ValueChanged<PhoneNumber>?`, `initialCountryCode: String?` (2-letter ISO, e.g. `'TR'`). `PhoneNumber` has a `completeNumber` getter (full E.164 string, e.g. `+905321234567`) built from its `countryCode` + `number` fields.

---

## Task 1: Add the `intl_phone_field` dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add the dependency**

Open `pubspec.yaml`. Find:

```yaml
  intl: ^0.20.3
  riverpod_annotation: ^4.0.7
```

Replace with:

```yaml
  intl: ^0.20.3
  intl_phone_field: ^3.2.0
  riverpod_annotation: ^4.0.7
```

- [ ] **Step 2: Fetch the package**

Run: `flutter pub get`
Expected: completes with `Got dependencies!`, `pubspec.lock` is updated to include `intl_phone_field`.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "Add intl_phone_field dependency for the Register screen's phone input"
```

---

## Task 2: Add new l10n strings

**Files:**
- Modify: `lib/l10n/app_tr.arb`
- Modify: `lib/l10n/app_en.arb`

- [ ] **Step 1: Add the Turkish keys (template file, with `@key` metadata)**

Open `lib/l10n/app_tr.arb`. Find:

```json
  "registerPasswordTooShort": "Şifre en az 8 karakter olmalı",
  "@registerPasswordTooShort": {},

  "forgotPasswordTitle": "Şifremi Unuttum",
```

Replace with:

```json
  "registerPasswordTooShort": "Şifre en az 8 karakter olmalı",
  "@registerPasswordTooShort": {},
  "registerSendCodeButton": "Kod Gönder",
  "@registerSendCodeButton": {},
  "registerCodeSentPhoneOnlyMessage": "Telefonunuza doğrulama kodu gönderildi.",
  "@registerCodeSentPhoneOnlyMessage": {},
  "registerCodeSentBothMessage": "Telefonunuza ve e-postanıza doğrulama kodu gönderildi.",
  "@registerCodeSentBothMessage": {},
  "registerPhoneCodeLabel": "Telefon Kodu",
  "@registerPhoneCodeLabel": {},
  "registerEmailCodeLabel": "E-posta Kodu",
  "@registerEmailCodeLabel": {},
  "registerChangeDetails": "Bilgileri değiştir",
  "@registerChangeDetails": {},

  "forgotPasswordTitle": "Şifremi Unuttum",
```

- [ ] **Step 2: Add the English keys (no `@key` metadata, matches this file's existing style)**

Open `lib/l10n/app_en.arb`. Find:

```json
  "registerPasswordTooShort": "Password must be at least 8 characters",

  "forgotPasswordTitle": "Forgot Password",
```

Replace with:

```json
  "registerPasswordTooShort": "Password must be at least 8 characters",
  "registerSendCodeButton": "Send Code",
  "registerCodeSentPhoneOnlyMessage": "A verification code has been sent to your phone.",
  "registerCodeSentBothMessage": "A verification code has been sent to your phone and email.",
  "registerPhoneCodeLabel": "Phone Code",
  "registerEmailCodeLabel": "Email Code",
  "registerChangeDetails": "Change details",

  "forgotPasswordTitle": "Forgot Password",
```

- [ ] **Step 3: Regenerate localizations and verify it builds**

Run: `flutter gen-l10n`
Expected: completes with no errors, `lib/l10n/generated/app_localizations.dart` (and the `_en`/`_tr` variants) are regenerated with the new getters.

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/l10n/app_tr.arb lib/l10n/app_en.arb lib/l10n/generated/
git commit -m "Add l10n strings for the 2-step register flow"
```

---

## Task 3: `AuthRepository` — replace `register()` with `requestRegistrationOtp`/`completeRegistration`

**Files:**
- Modify: `lib/features/auth/domain/auth_repository.dart`
- Modify: `lib/features/auth/data/real_auth_repository.dart`
- Test: `test/features/auth/data/real_auth_repository_test.dart`

- [ ] **Step 1: Write the failing tests**

Open `test/features/auth/data/real_auth_repository_test.dart`. Replace this whole test:

```dart
  test('register on 409 throws ConflictAuthException with the server message', () async {
    adapter.onPost(
      '/api/auth/register',
      (server) => server.reply(409, {
        'Status': 409,
        'Errors': ['Bu telefon numarasıyla zaten bir hesap var.'],
      }),
      data: Matchers.any,
    );

    await expectLater(
      () => repository.register(fullName: 'Ayşe', phone: '+905551112233', password: 'Sifre123!'),
      throwsA(isA<ConflictAuthException>().having(
        (e) => e.message,
        'message',
        'Bu telefon numarasıyla zaten bir hesap var.',
      )),
    );
  });
```

with these five:

```dart
  test('requestRegistrationOtp on success does not throw', () async {
    adapter.onPost(
      '/api/auth/register/request-otp',
      (server) => server.reply(204, null),
      data: Matchers.any,
    );

    await repository.requestRegistrationOtp(phone: '+905551112233', email: 'ayse@test.com');
  });

  test('requestRegistrationOtp on 409 throws ConflictAuthException with the server message', () async {
    adapter.onPost(
      '/api/auth/register/request-otp',
      (server) => server.reply(409, {
        'Status': 409,
        'Errors': ['Bu telefon numarasıyla zaten bir hesap var.'],
      }),
      data: Matchers.any,
    );

    await expectLater(
      () => repository.requestRegistrationOtp(phone: '+905551112233'),
      throwsA(isA<ConflictAuthException>().having(
        (e) => e.message,
        'message',
        'Bu telefon numarasıyla zaten bir hesap var.',
      )),
    );
  });

  test('requestRegistrationOtp on 429 throws RateLimitedAuthException', () async {
    adapter.onPost('/api/auth/register/request-otp', (server) => server.reply(429, ''), data: Matchers.any);

    await expectLater(
      () => repository.requestRegistrationOtp(phone: '+905551112233'),
      throwsA(isA<RateLimitedAuthException>()),
    );
  });

  test('completeRegistration on success stores the returned token pair', () async {
    adapter.onPost(
      '/api/auth/register/complete',
      (server) => server.reply(201, {
        'accessToken': 'access-1',
        'expiresAtUtc': '2026-09-16T13:00:00Z',
        'refreshToken': 'refresh-1',
      }),
      data: Matchers.any,
    );

    await repository.completeRegistration(
      fullName: 'Ayşe',
      phone: '+905551112233',
      phoneCode: '123456',
      password: 'Sifre123!',
    );

    expect(await tokenStore.readAccessToken(), 'access-1');
    expect(await tokenStore.readRefreshToken(), 'refresh-1');
  });

  test("completeRegistration on 401 surfaces the server's own message (wrong code, not wrong password)", () async {
    adapter.onPost(
      '/api/auth/register/complete',
      (server) => server.reply(401, {
        'Status': 401,
        'Errors': ['Telefon kodu hatalı, süresi dolmuş veya çok fazla deneme yapıldı.'],
      }),
      data: Matchers.any,
    );

    await expectLater(
      () => repository.completeRegistration(
        fullName: 'Ayşe',
        phone: '+905551112233',
        phoneCode: '000000',
        password: 'Sifre123!',
      ),
      throwsA(isA<GenericAuthException>().having(
        (e) => e.message,
        'message',
        'Telefon kodu hatalı, süresi dolmuş veya çok fazla deneme yapıldı.',
      )),
    );
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/auth/data/real_auth_repository_test.dart`
Expected: FAIL — `requestRegistrationOtp`/`completeRegistration` do not exist yet on `AuthRepository`/`RealAuthRepository` (compile error)

- [ ] **Step 3: Update the `AuthRepository` interface**

Open `lib/features/auth/domain/auth_repository.dart`. Replace:

```dart
abstract interface class AuthRepository {
  // Phone is required (matches the backend User entity's required+unique
  // Phone column); email is optional. login() keeps a single `identifier`
  // field since the backend accepts either phone or email there.
  Future<void> register({
    required String fullName,
    required String phone,
    String? email,
    required String password,
  });

  Future<void> login({required String identifier, required String password});
```

with:

```dart
abstract interface class AuthRepository {
  // Two-step registration: request-otp sends a code to phone (and email, if
  // given) but creates nothing yet; completeRegistration only creates the
  // account once both codes are proven correct. Phone is required (matches
  // the backend User entity's required+unique Phone column); email is
  // optional. login() keeps a single `identifier` field since the backend
  // accepts either phone or email there.
  Future<void> requestRegistrationOtp({required String phone, String? email});

  Future<void> completeRegistration({
    required String fullName,
    required String phone,
    required String phoneCode,
    String? email,
    String? emailCode,
    required String password,
  });

  Future<void> login({required String identifier, required String password});
```

- [ ] **Step 4: Update `RealAuthRepository`**

Open `lib/features/auth/data/real_auth_repository.dart`. Replace:

```dart
  @override
  Future<void> register({
    required String fullName,
    required String phone,
    String? email,
    required String password,
  }) async {
    final response = await _guard(() => _dio.post<Map<String, dynamic>>('/api/auth/register', data: {
          'fullName': fullName,
          'phone': phone,
          'email': email,
          'password': password,
        }));
    await _storeTokenPair(response.data!);
  }
```

with:

```dart
  @override
  Future<void> requestRegistrationOtp({required String phone, String? email}) async {
    await _guard(() => _dio.post<void>('/api/auth/register/request-otp', data: {
          'phone': phone,
          'email': email,
        }));
  }

  @override
  Future<void> completeRegistration({
    required String fullName,
    required String phone,
    required String phoneCode,
    String? email,
    String? emailCode,
    required String password,
  }) async {
    final response = await _guard(() => _dio.post<Map<String, dynamic>>('/api/auth/register/complete', data: {
          'fullName': fullName,
          'phone': phone,
          'phoneCode': phoneCode,
          'email': email,
          'emailCode': emailCode,
          'password': password,
        }));
    await _storeTokenPair(response.data!);
  }
```

- [ ] **Step 5: Fix `_mapException`'s 401 handling for `register/complete`**

Still in `real_auth_repository.dart`, replace:

```dart
  AuthException _mapException(DioException exception) {
    final statusCode = exception.response?.statusCode;
    if (statusCode == null) {
      return const NetworkAuthException();
    }
    if (statusCode == 401) {
      return const InvalidCredentialsException();
    }
    if (statusCode == 429) {
      return const RateLimitedAuthException();
    }

    final data = exception.response?.data;
    final message = data is Map && data['Errors'] is List && (data['Errors'] as List).isNotEmpty
        ? (data['Errors'] as List).first.toString()
        : 'Beklenmeyen bir hata oluştu.';

    if (statusCode == 409) {
      return ConflictAuthException(message);
    }
    return GenericAuthException(message);
  }
```

with:

```dart
  AuthException _mapException(DioException exception) {
    final statusCode = exception.response?.statusCode;
    if (statusCode == null) {
      return const NetworkAuthException();
    }
    if (statusCode == 429) {
      return const RateLimitedAuthException();
    }

    final data = exception.response?.data;
    final message = data is Map && data['Errors'] is List && (data['Errors'] as List).isNotEmpty
        ? (data['Errors'] as List).first.toString()
        : 'Beklenmeyen bir hata oluştu.';

    if (statusCode == 401) {
      // register/complete's 401 means "wrong OTP code", not "wrong
      // password" - the server's own message already says which channel
      // (phone/email) failed, so surface it verbatim instead of the
      // hardcoded InvalidCredentialsException every other 401 uses.
      if (exception.requestOptions.path == '/api/auth/register/complete') {
        return GenericAuthException(message);
      }
      return const InvalidCredentialsException();
    }
    if (statusCode == 409) {
      return ConflictAuthException(message);
    }
    return GenericAuthException(message);
  }
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `flutter test test/features/auth/data/real_auth_repository_test.dart`
Expected: all tests PASS, including the pre-existing `login on 401 throws InvalidCredentialsException` test (proves the path-check didn't break the general case)

- [ ] **Step 7: Commit**

```bash
git add lib/features/auth/domain/auth_repository.dart lib/features/auth/data/real_auth_repository.dart test/features/auth/data/real_auth_repository_test.dart
git commit -m "Replace register() with requestRegistrationOtp/completeRegistration"
```

---

## Task 4: Rewrite `RegisterScreen` as a 2-step flow with a country-code phone field

**Files:**
- Modify: `lib/features/auth/presentation/screens/register_screen.dart`

No dedicated widget test — matches this repo's existing convention (no feature screen has one; `LoginScreen`/`ForgotPasswordScreen` don't either, per the Real Auth plan's own established precedent). Verify manually in Task 5 instead.

- [ ] **Step 1: Replace the whole file**

Open `lib/features/auth/presentation/screens/register_screen.dart`. Replace the entire file content with:

```dart
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
    _phoneCodeController.dispose();
    _emailCodeController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (!_formKey.currentState!.validate()) return;

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
      setState(() => _errorText = exception.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _completeRegistration() async {
    if (!_formKey.currentState!.validate()) return;

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
      setState(() => _errorText = exception.message);
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
```

- [ ] **Step 2: Run static analysis**

Run: `flutter analyze`
Expected: `No issues found!` (if `IntlPhoneField`'s `validator`/`enabled`/`onChanged` parameter names differ from what's used above, this step will surface it as a compile error — check `.dart_tool/package_config.json`'s resolved `intl_phone_field` version's actual source under `~/.pub-cache` or the `flutter analyze` error message and adjust the parameter names to match)

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/presentation/screens/register_screen.dart
git commit -m "Rewrite Register screen as a 2-step OTP flow with a country-code phone field"
```

---

## Task 5: Manual end-to-end smoke test

**Files:** none (verification only, no code changes)

Requires the backend plan's Tasks 1–6 already done and the API running at `http://localhost:5195` (see that plan's Task 8 for how to start Postgres + the API).

- [ ] **Step 1: Run the app**

Run: `flutter run -d chrome --web-port=9100` (or another target — the backend's `DevClients` CORS policy from earlier in this session already allows any origin in Development)

- [ ] **Step 2: Walk through phone-only registration**

On the Register screen: fill in name/phone (pick a country, enter a fresh number)/password, leave email blank, tap "Kod Gönder". Expect a SnackBar saying a code was sent to the phone only. Check the backend console for the `[FAKE SMS]` log line with the 6-digit code, enter it, tap "Hesap Oluştur". Expect landing on `/home`.

- [ ] **Step 3: Walk through phone+email registration**

Register a second account, this time filling in email too. Expect the "sent to phone and email" SnackBar, and both a `[FAKE SMS]` and `[FAKE EMAIL]` log line. Enter both codes, submit, expect success.

- [ ] **Step 4: Verify a wrong code shows the right message**

Register a third account (fresh phone), request a code, then submit with a deliberately wrong 6-digit phone code. Expect an inline error reading "Telefon kodu hatalı..." (not "Telefon numarası/e-posta veya şifre hatalı." — confirms Task 3's `_mapException` path-check works end-to-end, not just in the repository unit test).

- [ ] **Step 5: Verify the phone field rejects non-digit input and enforces a country format**

On the phone field, try typing letters — confirm none appear. Confirm the country picker works and changing country updates the expected number length/format.

- [ ] **Step 6: Confirm no regression in Login**

Log out (or use a fresh browser session) and log in with one of the accounts just created. Expect success — confirms Task 3's `_mapException` change didn't affect Login's own 401 handling.

No commit for this task (verification only).
