# Member Experience (Mock Data) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Branch (backend-gated) proof-of-concept with the full "MAT & MOVE" mockup experience — a fake-authenticated 4-tab app (Ana Sayfa, Dersler, Gelişimim, Üyeliğim) driven entirely by mock/local data through the same repository-interface pattern the Branch feature already proved, so swapping in real backends later only touches the data layer.

**Architecture:** Five independent features (`auth`, `home`, `classes`, `progress`, `membership`), each `domain/` (plain models + repository interface) → `data/` (`Fake...Repository`, in-memory, no network) → `presentation/` (Riverpod providers + screens), mirroring `lib/features/branches/` exactly minus the JSON/Dio layer (mock repositories work with domain objects directly, no DTOs needed). A new `StatefulShellRoute` wires the 4 tabs behind a fake `authStateProvider` gate; `/login` sits outside the shell.

**Tech Stack:** Same as Mobile Foundation — Flutter/Dart, `flutter_riverpod` + `riverpod_generator`, `go_router` (`StatefulShellRoute.indexedStack`), `mocktail` for tests, existing `AppTheme`/`AppSpacing`/`AppTypography` design tokens (one token value changes — see Task 2).

**Spec:** `docs/superpowers/specs/2026-09-14-member-experience-design.md` — read it in full before starting.

---

## Environment notes carried over from prior plans (still true)

- **Use the PowerShell tool for every `flutter`/`dart` command** — Bash/Git Bash cannot invoke the Flutter CLI correctly in this environment. Plain `git` works via either.
- `dart run build_runner build --delete-conflicting-outputs` — the `--delete-conflicting-outputs` flag is deprecated/ignored by this project's build_runner version (prints a harmless warning, still works). Keep passing it.
- `AsyncValue.copyWithPrevious` is `@internal` in the installed `riverpod` version — never call it. If a provider needs to preserve its last-known value across a failed reload, use a private cache field (see Task 9's `HomeList`-equivalent note, same pattern as `lib/features/branches/presentation/providers/branch_list_provider.dart`'s `_lastKnownBranches`).
- Flutter's `NavigationBar` widget throws `destinations.length >= 2 is not true` with fewer than 2 destinations. Not a risk here (4 real destinations), but keep it in mind if `AppShell` is ever touched again with fewer.
- No worktree/branch isolation — work directly on `main`, matching every prior task in this repo and the backend repo.

---

## Task 1: Remove the Branch Feature

**Files:**
- Delete: `lib/features/branches/` (entire directory: `domain/`, `data/`, `presentation/`)
- Delete: `test/features/branches/` (entire directory)
- Modify: `lib/core/router/app_router.dart` — will be fully rewritten in Task 17, but for this task just remove the Branch imports/routes so the project compiles again with no Branch code referenced (leave a minimal placeholder router so the app still builds — Task 17 replaces it properly)

The Branch feature was a proof-of-concept for the Mobile Foundation plan (backend-gated Branch list/create). The user explicitly rejected it as the direction for the real app and asked for it removed — see the design spec's "Kapsam Dışı" section. Nothing here is reused; the feature and its tests are deleted outright, not archived.

- [ ] **Step 1: Delete the Branch feature and its tests**

Run:
```bash
git rm -r lib/features/branches
git rm -r test/features/branches
```
Expected: both directories removed from the working tree and staged for deletion.

- [ ] **Step 2: Replace `app_router.dart` with a temporary minimal router**

The current file imports `BranchListScreen`/`BranchFormScreen`, which no longer exist. Replace its contents with a minimal placeholder so the project compiles — this is intentionally temporary, Task 17 replaces it with the real `/login` + `StatefulShellRoute` router once all 5 screens exist.

```dart
// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Member Experience — under construction')),
        ),
      ),
    ],
  );
}
```

- [ ] **Step 3: Regenerate and verify**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```
Expected: `flutter analyze` → `No issues found!`. `flutter test` → all remaining tests pass (the Branch tests are gone, so the count drops — expect only `test/core/network/api_exception_test.dart`'s 2 tests to remain at this point; that's correct, not a regression, since every other existing test belonged to the now-deleted Branch feature).

- [ ] **Step 4: Commit**

```bash
git add lib/core/router/app_router.dart lib/core/router/app_router.g.dart
git commit -m "Remove Branch feature and replace router with temporary placeholder"
```

---

## Task 2: Update `AppColors.primary` to a Calmer Green

**Files:**
- Modify: `lib/core/theme/app_colors.dart`

The original `#C6FF3D` (neon lime) was rejected by the user during visual brainstorming as too harsh/eye-straining. Settled on `#8BC34A` — still reads as the brand's green-energy accent, but with much lower luminance against the near-black background.

- [ ] **Step 1: Change the primary color**

In `lib/core/theme/app_colors.dart`, change:
```dart
  static const primary = Color(0xFFC6FF3D);
```
to:
```dart
  static const primary = Color(0xFF8BC34A);
```
Also update `successSurface` (currently `Color(0x1AC6FF3D)`, a 10%-alpha tint of the old primary used for the "Aktif" status pill background) to match the new primary:
```dart
  static const successSurface = Color(0x1A8BC34A);
```
No other token changes — `onPrimary` (`0xFF0D0D0F`) stays, `secondary` (`0xFF2DD4BF`, teal, used for the "Devamlılık" progress gauge) stays.

- [ ] **Step 2: Verify contrast still holds**

`onPrimary` (`#0D0D0F`, near-black) on `primary` (`#8BC34A`) needs to clear a comfortable contrast ratio for bold button text. `#8BC34A` is *darker* than `#C6FF3D` (lower luminance), so contrast against near-black text is higher, not lower, than the already-passing original — no regression possible here, but confirm by eye once the app runs (Task 18).

- [ ] **Step 3: Verify and commit**

Run: `flutter analyze`
Expected: `No issues found!`

```bash
git add lib/core/theme/app_colors.dart
git commit -m "Tone down primary accent from neon lime to a calmer green"
```

---

## Task 3: Rewrite Localization — Remove Branch Keys, Add Member Experience Keys

**Files:**
- Modify: `lib/l10n/app_tr.arb`
- Modify: `lib/l10n/app_en.arb`

All Branch-specific keys are removed (the feature is gone). `commonFieldRequired` replaces the old `branchFormValidationRequired` under a more general name (it's reused by the login form and will be reused by any future form). `commonError`/`commonRetry` are kept as-is (still used by every screen's `AsyncValue` error branch).

- [ ] **Step 1: Replace `lib/l10n/app_tr.arb` entirely**

```json
{
  "@@locale": "tr",
  "appTitle": "GymApp",
  "@appTitle": {},
  "commonFieldRequired": "Bu alan zorunludur",
  "@commonFieldRequired": {},
  "commonError": "Bir şeyler ters gitti",
  "@commonError": {},
  "commonRetry": "Tekrar Dene",
  "@commonRetry": {},

  "navHome": "Ana Sayfa",
  "@navHome": {},
  "navClasses": "Dersler",
  "@navClasses": {},
  "navProgress": "Gelişim",
  "@navProgress": {},
  "navMembership": "Profil",
  "@navMembership": {},

  "loginWelcomeTitle": "Tekrar hoş geldin",
  "@loginWelcomeTitle": {},
  "loginSubtitle": "Disiplin bugün de seninle",
  "@loginSubtitle": {},
  "loginIdentifierLabel": "Telefon veya e-posta",
  "@loginIdentifierLabel": {},
  "loginPasswordLabel": "Şifre",
  "@loginPasswordLabel": {},
  "loginSubmitButton": "Giriş Yap",
  "@loginSubmitButton": {},
  "loginForgotPassword": "Şifremi unuttum",
  "@loginForgotPassword": {},

  "homeGreeting": "Merhaba, {name}",
  "@homeGreeting": {
    "placeholders": { "name": { "type": "String" } }
  },
  "homeSubtitle": "Disiplin bugün de seninle",
  "@homeSubtitle": {},
  "homeActivePackageLabel": "Aktif Paketin",
  "@homeActivePackageLabel": {},
  "homeDaysLeft": "{count} gün kaldı",
  "@homeDaysLeft": {
    "placeholders": { "count": { "type": "int" } }
  },
  "homeNextClassLabel": "Sıradaki Ders",
  "@homeNextClassLabel": {},
  "homeReservationButton": "Rezervasyon",
  "@homeReservationButton": {},
  "homeCheckInButton": "Giriş Yap",
  "@homeCheckInButton": {},
  "homeWeeklyAttendanceLabel": "Bu Hafta Devam",
  "@homeWeeklyAttendanceLabel": {},
  "homeWeeklyAttendanceCount": "{attended}/{total} ders",
  "@homeWeeklyAttendanceCount": {
    "placeholders": {
      "attended": { "type": "int" },
      "total": { "type": "int" }
    }
  },

  "classesTitle": "Dersler",
  "@classesTitle": {},
  "classesFilterAll": "Tümü",
  "@classesFilterAll": {},
  "classesCategoryBjj": "BJJ",
  "@classesCategoryBjj": {},
  "classesCategoryFitness": "Fitness",
  "@classesCategoryFitness": {},
  "classesCapacityLabel": "{enrolled}/{capacity} kişi",
  "@classesCapacityLabel": {
    "placeholders": {
      "enrolled": { "type": "int" },
      "capacity": { "type": "int" }
    }
  },
  "classesReserveButton": "Yer Ayır",
  "@classesReserveButton": {},
  "classesReservedButton": "Rezerve Edildi",
  "@classesReservedButton": {},
  "classesWaitlistButton": "Bekleme Listesi",
  "@classesWaitlistButton": {},

  "progressTitle": "Gelişimim",
  "@progressTitle": {},
  "progressMonthLabel": "Bu Ay",
  "@progressMonthLabel": {},
  "progressClassesCount": "{count} ders",
  "@progressClassesCount": {
    "placeholders": { "count": { "type": "int" } }
  },
  "progressAreasLabel": "Gelişim Alanlarım",
  "@progressAreasLabel": {},
  "progressTechnique": "Teknikler",
  "@progressTechnique": {},
  "progressAttendance": "Devamlılık",
  "@progressAttendance": {},
  "progressCondition": "Kondisyon",
  "@progressCondition": {},
  "progressTrainerNoteLabel": "Son Eğitmen Notu",
  "@progressTrainerNoteLabel": {},
  "progressCategoryBjj": "BJJ",
  "@progressCategoryBjj": {},
  "progressCategoryFitness": "Fitness",
  "@progressCategoryFitness": {},

  "membershipTitle": "Üyeliğim",
  "@membershipTitle": {},
  "membershipActiveStatus": "Aktif",
  "@membershipActiveStatus": {},
  "membershipFrozenStatus": "Donduruldu",
  "@membershipFrozenStatus": {},
  "membershipPaidStatus": "Ödendi",
  "@membershipPaidStatus": {},
  "membershipRenewButton": "Üyeliği Yenile",
  "@membershipRenewButton": {},
  "membershipFreezeButton": "Dondurma Talebi",
  "@membershipFreezeButton": {},
  "membershipRenewRequested": "Yenileme talebi alındı",
  "@membershipRenewRequested": {},
  "membershipPaymentHistoryLabel": "Ödeme Geçmişi",
  "@membershipPaymentHistoryLabel": {}
}
```

- [ ] **Step 2: Replace `lib/l10n/app_en.arb` entirely**

```json
{
  "@@locale": "en",
  "appTitle": "GymApp",
  "commonFieldRequired": "This field is required",
  "commonError": "Something went wrong",
  "commonRetry": "Retry",

  "navHome": "Home",
  "navClasses": "Classes",
  "navProgress": "Progress",
  "navMembership": "Profile",

  "loginWelcomeTitle": "Welcome back",
  "loginSubtitle": "Discipline is with you today",
  "loginIdentifierLabel": "Phone or email",
  "loginPasswordLabel": "Password",
  "loginSubmitButton": "Log In",
  "loginForgotPassword": "Forgot password",

  "homeGreeting": "Hello, {name}",
  "homeSubtitle": "Discipline is with you today",
  "homeActivePackageLabel": "Your Active Package",
  "homeDaysLeft": "{count} days left",
  "homeNextClassLabel": "Next Class",
  "homeReservationButton": "Reservation",
  "homeCheckInButton": "Check In",
  "homeWeeklyAttendanceLabel": "This Week's Attendance",
  "homeWeeklyAttendanceCount": "{attended}/{total} classes",

  "classesTitle": "Classes",
  "classesFilterAll": "All",
  "classesCategoryBjj": "BJJ",
  "classesCategoryFitness": "Fitness",
  "classesCapacityLabel": "{enrolled}/{capacity} people",
  "classesReserveButton": "Reserve Spot",
  "classesReservedButton": "Reserved",
  "classesWaitlistButton": "Waitlist",

  "progressTitle": "My Progress",
  "progressMonthLabel": "This Month",
  "progressClassesCount": "{count} classes",
  "progressAreasLabel": "My Growth Areas",
  "progressTechnique": "Technique",
  "progressAttendance": "Attendance",
  "progressCondition": "Condition",
  "progressTrainerNoteLabel": "Latest Trainer Note",
  "progressCategoryBjj": "BJJ",
  "progressCategoryFitness": "Fitness",

  "membershipTitle": "My Membership",
  "membershipActiveStatus": "Active",
  "membershipFrozenStatus": "Frozen",
  "membershipPaidStatus": "Paid",
  "membershipRenewButton": "Renew Membership",
  "membershipFreezeButton": "Request Freeze",
  "membershipRenewRequested": "Renewal request received",
  "membershipPaymentHistoryLabel": "Payment History"
}
```

- [ ] **Step 3: Regenerate and verify**

Run: `flutter gen-l10n`
Expected: succeeds, no errors (a "synthetic-package no longer has any effect" deprecation warning is expected/harmless, unrelated to this change).

Note: no application code references these new keys yet (they're consumed by screens built in later tasks) — `flutter analyze` on the whole project will still show errors from `app_router.dart` referencing screens that don't exist. That's expected at this point in the plan; ignore it until Task 17.

- [ ] **Step 4: Commit**

```bash
git add lib/l10n/app_tr.arb lib/l10n/app_en.arb
git commit -m "Replace Branch localization keys with Member Experience keys"
```

---

## Task 4: `CircularStatGauge` Widget

**Files:**
- Create: `lib/core/widgets/circular_stat_gauge.dart`
- Test: `test/core/widgets/circular_stat_gauge_test.dart`

A small, reusable donut/ring gauge for the Progress screen's three percentage stats (Teknikler/Devamlılık/Kondisyon). Flutter has no built-in ring-gauge widget; this is a `CustomPainter` drawing two arcs (a full-circle track + a value arc) plus a centered percentage label.

- [ ] **Step 1: Write the failing widget test**

```dart
// test/core/widgets/circular_stat_gauge_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/widgets/circular_stat_gauge.dart';

void main() {
  testWidgets('renders the percentage label for the given value', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CircularStatGauge(value: 0.65, color: Colors.green, label: 'Teknikler'),
        ),
      ),
    );

    expect(find.text('%65'), findsOneWidget);
    expect(find.text('Teknikler'), findsOneWidget);
  });

  testWidgets('clamps out-of-range values into the label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CircularStatGauge(value: 1.4, color: Colors.green, label: 'Test'),
        ),
      ),
    );

    expect(find.text('%100'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/widgets/circular_stat_gauge_test.dart`
Expected: FAIL — `package:gym_app/core/widgets/circular_stat_gauge.dart` not found.

- [ ] **Step 3: Implement `CircularStatGauge`**

```dart
// lib/core/widgets/circular_stat_gauge.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// A small ring gauge showing a 0.0–1.0 value as a percentage, with a
/// centered label below. Used by the Progress screen's three growth-area
/// stats. `value` is clamped to [0, 1] before both drawing and labeling.
class CircularStatGauge extends StatelessWidget {
  const CircularStatGauge({
    required this.value,
    required this.color,
    required this.label,
    this.size = 56,
    super.key,
  });

  final double value;
  final Color color;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _GaugePainter(value: clamped, color: color),
            child: Center(
              child: Text(
                '%${(clamped * 100).round()}',
                style: AppTypography.textTheme.labelLarge?.copyWith(
                  color: AppColors.onBackground,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTypography.textTheme.bodyMedium?.copyWith(fontSize: 9),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - 6) / 2;
    const strokeWidth = 6.0;

    final trackPaint = Paint()
      ..color = AppColors.surfaceElevated
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    const startAngle = -1.5707963267948966; // -90deg, 12 o'clock
    final sweepAngle = 6.283185307179586 * value; // value * 2*pi
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/widgets/circular_stat_gauge_test.dart`
Expected: PASS — 2 tests passed.

- [ ] **Step 5: Verify and commit**

Run: `flutter analyze lib/core/widgets/circular_stat_gauge.dart test/core/widgets/circular_stat_gauge_test.dart`
Expected: no issues.

```bash
git add lib/core/widgets/circular_stat_gauge.dart test/core/widgets/circular_stat_gauge_test.dart
git commit -m "Add CircularStatGauge widget for progress ring stats"
```

---

## Task 5: Auth Feature — Fake Repository + Auth State

**Files:**
- Create: `lib/features/auth/domain/auth_repository.dart`
- Create: `lib/features/auth/data/fake_auth_repository.dart`
- Create: `lib/features/auth/presentation/providers/auth_state_provider.dart`
- Test: `test/features/auth/data/fake_auth_repository_test.dart`
- Test: `test/features/auth/presentation/providers/auth_state_provider_test.dart`

No real authentication exists. `FakeAuthRepository.login(...)` always succeeds after a short artificial delay (so the login button's loading spinner has something real to show). `authStateProvider` is a separate, simple boolean `Notifier` the router reads to decide `/login` vs. the tab shell — kept apart from the repository so the router doesn't need to know anything about how login "happened."

- [ ] **Step 1: Write the failing test for `FakeAuthRepository`**

```dart
// test/features/auth/data/fake_auth_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/auth/data/fake_auth_repository.dart';

void main() {
  test('login completes without throwing for any non-empty credentials', () async {
    final repository = FakeAuthRepository();

    await expectLater(
      repository.login(identifier: 'elnara@example.com', password: 'anything'),
      completes,
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/auth/data/fake_auth_repository_test.dart`
Expected: FAIL — `package:gym_app/features/auth/data/fake_auth_repository.dart` not found.

- [ ] **Step 3: Implement `AuthRepository` and `FakeAuthRepository`**

```dart
// lib/features/auth/domain/auth_repository.dart
abstract interface class AuthRepository {
  Future<void> login({required String identifier, required String password});
}
```

```dart
// lib/features/auth/data/fake_auth_repository.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/auth_repository.dart';

part 'fake_auth_repository.g.dart';

/// No real backend exists yet — any non-empty identifier/password is
/// accepted after a short artificial delay, so the login button's loading
/// state has something real to show. See `AuthState` (presentation layer)
/// for what "being logged in" actually gates in the app.
class FakeAuthRepository implements AuthRepository {
  @override
  Future<void> login({required String identifier, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }
}

@riverpod
AuthRepository authRepository(Ref ref) => FakeAuthRepository();
```

- [ ] **Step 4: Run code generation**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `lib/features/auth/data/fake_auth_repository.g.dart` generated.

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/auth/data/fake_auth_repository_test.dart`
Expected: PASS — 1 test passed.

- [ ] **Step 6: Write the failing test for `authStateProvider`**

```dart
// test/features/auth/presentation/providers/auth_state_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/auth/presentation/providers/auth_state_provider.dart';

void main() {
  test('starts logged out, logIn sets true, logOut sets false', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(authStateProvider), false);

    container.read(authStateProvider.notifier).logIn();
    expect(container.read(authStateProvider), true);

    container.read(authStateProvider.notifier).logOut();
    expect(container.read(authStateProvider), false);
  });
}
```

- [ ] **Step 7: Run test to verify it fails**

Run: `flutter test test/features/auth/presentation/providers/auth_state_provider_test.dart`
Expected: FAIL — `auth_state_provider.dart` not found.

- [ ] **Step 8: Implement `authStateProvider`**

```dart
// lib/features/auth/presentation/providers/auth_state_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_state_provider.g.dart';

/// Whether the app should show the tab shell (true) or `/login` (false).
/// No persistence — resets to false every app launch, by design (see spec).
@riverpod
class AuthState extends _$AuthState {
  @override
  bool build() => false;

  void logIn() => state = true;
  void logOut() => state = false;
}
```

- [ ] **Step 9: Run code generation and verify tests pass**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/auth
```
Expected: `auth_state_provider.g.dart` generated; 2 tests passed (1 repository + 1 state).

- [ ] **Step 10: Verify and commit**

Run: `flutter analyze lib/features/auth test/features/auth`
Expected: no issues.

```bash
git add lib/features/auth test/features/auth
git commit -m "Add fake auth repository and auth state provider"
```

---

## Task 6: Login Screen

**Files:**
- Create: `lib/features/auth/presentation/screens/login_screen.dart`

No test for this screen (matches the established convention from the Branch feature — screens themselves aren't unit-tested, only providers/repositories are; screens are verified in the manual smoke test, Task 18).

- [ ] **Step 1: Write `LoginScreen`**

A dark background with a soft low-opacity radial glow (approximating the brainstormed visual — a full custom gradient painter is unnecessary, a `RadialGradient`-filled `Container` behind the content achieves the same look), brand mark, welcome copy, two validated fields, submit button with loading state.

```dart
// lib/features/auth/presentation/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/fake_auth_repository.dart';
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

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(authRepositoryProvider).login(
            identifier: _identifierController.text,
            password: _passwordController.text,
          );
      if (!mounted) return;
      ref.read(authStateProvider.notifier).logIn();
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
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 26,
                height: 26,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                transform: Matrix4.rotationZ(0.7854),
                transformAlignment: Alignment.center,
              ),
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
                        decoration: InputDecoration(labelText: l10n.loginIdentifierLabel),
                        validator: (value) => (value == null || value.trim().isEmpty)
                            ? l10n.commonFieldRequired
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(labelText: l10n.loginPasswordLabel),
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
                      Text(
                        l10n.loginForgotPassword,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify and commit**

Run: `flutter analyze lib/features/auth/presentation/screens/login_screen.dart`
Expected: this single file analyzes without issue (the whole-project `flutter analyze` still fails at this point — `app_router.dart` doesn't reference this screen yet, and other screens don't exist yet; that's expected until Task 17).

```bash
git add lib/features/auth/presentation/screens/login_screen.dart
git commit -m "Add login screen"
```

---

## Task 7: Home Feature — Domain + Fake Repository + Provider

**Files:**
- Create: `lib/features/home/domain/home_summary.dart`
- Create: `lib/features/home/domain/home_repository.dart`
- Create: `lib/features/home/data/fake_home_repository.dart`
- Create: `lib/features/home/presentation/providers/home_summary_provider.dart`
- Test: `test/features/home/data/fake_home_repository_test.dart`
- Test: `test/features/home/presentation/providers/home_summary_provider_test.dart`

- [ ] **Step 1: Write the failing test for `FakeHomeRepository`**

```dart
// test/features/home/data/fake_home_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/home/data/fake_home_repository.dart';

void main() {
  test('getHomeSummary returns a fixed mock summary with sane values', () async {
    final repository = FakeHomeRepository();

    final summary = await repository.getHomeSummary();

    expect(summary.greetingName, isNotEmpty);
    expect(summary.activePackageName, isNotEmpty);
    expect(summary.daysLeft, greaterThan(0));
    expect(summary.weeklyAttendance, hasLength(7));
    expect(summary.attendedCount, summary.weeklyAttendance.where((d) => d).length);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/home/data/fake_home_repository_test.dart`
Expected: FAIL — `package:gym_app/features/home/data/fake_home_repository.dart` not found.

- [ ] **Step 3: Implement `HomeSummary`, `HomeRepository`, `FakeHomeRepository`**

```dart
// lib/features/home/domain/home_summary.dart
class HomeSummary {
  const HomeSummary({
    required this.greetingName,
    required this.activePackageName,
    required this.daysLeft,
    required this.nextClassName,
    required this.nextClassTime,
    required this.nextClassTrainer,
    required this.weeklyAttendance,
  });

  final String greetingName;
  final String activePackageName;
  final int daysLeft;
  final String nextClassName;
  final String nextClassTime;
  final String nextClassTrainer;

  /// One entry per day, Monday first — true means a class was attended.
  final List<bool> weeklyAttendance;

  int get attendedCount => weeklyAttendance.where((attended) => attended).length;
}
```

```dart
// lib/features/home/domain/home_repository.dart
import 'home_summary.dart';

abstract interface class HomeRepository {
  Future<HomeSummary> getHomeSummary();
}
```

```dart
// lib/features/home/data/fake_home_repository.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/home_repository.dart';
import '../domain/home_summary.dart';

part 'fake_home_repository.g.dart';

class FakeHomeRepository implements HomeRepository {
  @override
  Future<HomeSummary> getHomeSummary() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const HomeSummary(
      greetingName: 'Elnara',
      activePackageName: 'BJJ + Fitness',
      daysLeft: 18,
      nextClassName: 'BJJ Temel',
      nextClassTime: 'Bugün 19:00',
      nextClassTrainer: 'Mert Demir',
      weeklyAttendance: [true, true, false, true, false, true, false],
    );
  }
}

@riverpod
HomeRepository homeRepository(Ref ref) => FakeHomeRepository();
```

- [ ] **Step 4: Run code generation and verify the repository test passes**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/home/data/fake_home_repository_test.dart
```
Expected: `fake_home_repository.g.dart` generated; 1 test passed.

- [ ] **Step 5: Write the failing test for `homeSummaryProvider`**

```dart
// test/features/home/presentation/providers/home_summary_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/home/data/fake_home_repository.dart';
import 'package:gym_app/features/home/domain/home_repository.dart';
import 'package:gym_app/features/home/domain/home_summary.dart';
import 'package:gym_app/features/home/presentation/providers/home_summary_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockHomeRepository extends Mock implements HomeRepository {}

void main() {
  test('loads the summary from the repository', () async {
    final repository = _MockHomeRepository();
    when(() => repository.getHomeSummary()).thenAnswer(
      (_) async => const HomeSummary(
        greetingName: 'Test',
        activePackageName: 'Test Paket',
        daysLeft: 5,
        nextClassName: 'Test Ders',
        nextClassTime: 'Yarın 10:00',
        nextClassTrainer: 'Test Eğitmen',
        weeklyAttendance: [true, false, false, false, false, false, false],
      ),
    );
    final container = ProviderContainer(
      overrides: [homeRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final summary = await container.read(homeSummaryProvider.future);

    expect(summary.greetingName, 'Test');
    expect(summary.daysLeft, 5);
  });
}
```

- [ ] **Step 6: Run test to verify it fails**

Run: `flutter test test/features/home/presentation/providers/home_summary_provider_test.dart`
Expected: FAIL — `home_summary_provider.dart` not found.

- [ ] **Step 7: Implement `homeSummaryProvider`**

```dart
// lib/features/home/presentation/providers/home_summary_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/fake_home_repository.dart';
import '../../domain/home_summary.dart';

part 'home_summary_provider.g.dart';

@riverpod
Future<HomeSummary> homeSummary(Ref ref) {
  return ref.watch(homeRepositoryProvider).getHomeSummary();
}
```

- [ ] **Step 8: Run code generation and verify tests pass**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/home
```
Expected: `home_summary_provider.g.dart` generated; 2 tests passed.

- [ ] **Step 9: Verify and commit**

Run: `flutter analyze lib/features/home test/features/home`
Expected: no issues.

```bash
git add lib/features/home test/features/home
git commit -m "Add home summary domain, fake repository and provider"
```

---

## Task 8: Home Screen (Ana Sayfa)

**Files:**
- Create: `lib/features/home/presentation/screens/home_screen.dart`

The weekly attendance bar chart is simple enough to inline directly in the screen (7 `Container`s in a `Row`, height proportional to a fixed per-day value) — no separate chart widget needed, unlike the progress gauges which are reused 3 times and warranted `CircularStatGauge`.

- [ ] **Step 1: Write `HomeScreen`**

```dart
// lib/features/home/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/home_summary.dart';
import '../providers/home_summary_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summaryAsync = ref.watch(homeSummaryProvider);

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: const Text('GymApp')),
      body: summaryAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
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
                  onPressed: () => ref.invalidate(homeSummaryProvider),
                  child: Text(l10n.commonRetry),
                ),
              ],
            ),
          ),
        ),
        data: (summary) => _HomeContent(l10n: l10n, summary: summary),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.l10n, required this.summary});

  final AppLocalizations l10n;
  final HomeSummary summary;

  static const _dayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(l10n.homeGreeting(summary.greetingName), style: textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.homeSubtitle, style: textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.homeActivePackageLabel, style: textTheme.labelSmall),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(summary.activePackageName, style: textTheme.titleMedium),
                    _Pill(text: l10n.homeDaysLeft(summary.daysLeft)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.homeNextClassLabel, style: textTheme.labelSmall),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${summary.nextClassName} · ${summary.nextClassTime}',
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('Eğitmen: ${summary.nextClassTrainer}', style: textTheme.bodyMedium),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                child: Text(l10n.homeReservationButton),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                child: Text(l10n.homeCheckInButton),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.homeWeeklyAttendanceLabel, style: textTheme.labelSmall),
                    Text(
                      l10n.homeWeeklyAttendanceCount(summary.attendedCount, 7),
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 32,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final attended in summary.weeklyAttendance)
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            height: attended ? 32 : 12,
                            decoration: BoxDecoration(
                              color: attended ? AppColors.primary : AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final label in _dayLabels)
                      Text(label, style: textTheme.labelSmall?.copyWith(fontSize: 8)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.successSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify and commit**

Run: `flutter analyze lib/features/home/presentation/screens/home_screen.dart`
Expected: this file analyzes without issue on its own (whole-project analyze still pending Task 17).

```bash
git add lib/features/home/presentation/screens/home_screen.dart
git commit -m "Add home screen"
```

---

## Task 9: Classes Feature — Domain + Fake Repository (with Reservation Mutation) + Provider

**Files:**
- Create: `lib/features/classes/domain/class_session.dart`
- Create: `lib/features/classes/domain/class_repository.dart`
- Create: `lib/features/classes/data/fake_class_repository.dart`
- Create: `lib/features/classes/presentation/providers/class_list_provider.dart`
- Test: `test/features/classes/data/fake_class_repository_test.dart`
- Test: `test/features/classes/presentation/providers/class_list_provider_test.dart`

`ClassSession.isReservedByMe` tracks whether the current (single, mock) user has reserved that specific session — this is what flips the "Yer Ayır" button to a disabled "Rezerve Edildi" state, independent of the raw `enrolledCount`/`capacity` numbers. `reserveSpot` is a no-op (throws, in the repository test) if the session is already full or already reserved — the UI never calls it in those states, but the repository enforces the invariant itself rather than trusting the caller.

- [ ] **Step 1: Write the failing test for `FakeClassRepository`**

```dart
// test/features/classes/data/fake_class_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/classes/data/fake_class_repository.dart';
import 'package:gym_app/features/classes/domain/class_session.dart';

void main() {
  test('getClassSessions returns the fixed mock list with a full and a non-full session', () async {
    final repository = FakeClassRepository();

    final sessions = await repository.getClassSessions();

    expect(sessions, isNotEmpty);
    expect(sessions.any((s) => s.enrolledCount < s.capacity), isTrue);
    expect(sessions.any((s) => s.enrolledCount == s.capacity), isTrue);
  });

  test('reserveSpot increments enrolledCount and marks the session as reserved by me', () async {
    final repository = FakeClassRepository();
    final before = await repository.getClassSessions();
    final target = before.firstWhere((s) => s.enrolledCount < s.capacity);

    await repository.reserveSpot(target.id);
    final after = await repository.getClassSessions();
    final updated = after.firstWhere((s) => s.id == target.id);

    expect(updated.enrolledCount, target.enrolledCount + 1);
    expect(updated.isReservedByMe, isTrue);
  });

  test('reserveSpot throws StateError for an already-full session', () async {
    final repository = FakeClassRepository();
    final sessions = await repository.getClassSessions();
    final fullSession = sessions.firstWhere((s) => s.enrolledCount == s.capacity);

    expect(() => repository.reserveSpot(fullSession.id), throwsStateError);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/classes/data/fake_class_repository_test.dart`
Expected: FAIL — `package:gym_app/features/classes/data/fake_class_repository.dart` not found.

- [ ] **Step 3: Implement `ClassCategory`, `ClassSession`, `ClassRepository`, `FakeClassRepository`**

```dart
// lib/features/classes/domain/class_session.dart
enum ClassCategory { bjj, fitness }

class ClassSession {
  const ClassSession({
    required this.id,
    required this.name,
    required this.category,
    required this.timeRange,
    required this.trainerName,
    required this.capacity,
    required this.enrolledCount,
    this.isReservedByMe = false,
  });

  final int id;
  final String name;
  final ClassCategory category;
  final String timeRange;
  final String trainerName;
  final int capacity;
  final int enrolledCount;
  final bool isReservedByMe;

  bool get isFull => enrolledCount >= capacity;

  ClassSession copyWith({int? enrolledCount, bool? isReservedByMe}) {
    return ClassSession(
      id: id,
      name: name,
      category: category,
      timeRange: timeRange,
      trainerName: trainerName,
      capacity: capacity,
      enrolledCount: enrolledCount ?? this.enrolledCount,
      isReservedByMe: isReservedByMe ?? this.isReservedByMe,
    );
  }
}
```

```dart
// lib/features/classes/domain/class_repository.dart
import 'class_session.dart';

abstract interface class ClassRepository {
  Future<List<ClassSession>> getClassSessions();
  Future<void> reserveSpot(int classId);
}
```

```dart
// lib/features/classes/data/fake_class_repository.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/class_repository.dart';
import '../domain/class_session.dart';

part 'fake_class_repository.g.dart';

class FakeClassRepository implements ClassRepository {
  List<ClassSession> _sessions = const [
    ClassSession(
      id: 1,
      name: 'BJJ Temel',
      category: ClassCategory.bjj,
      timeRange: '19:00–20:30',
      trainerName: 'Mert Demir',
      capacity: 12,
      enrolledCount: 8,
    ),
    ClassSession(
      id: 2,
      name: 'Fitness Grup',
      category: ClassCategory.fitness,
      timeRange: '18:00–19:00',
      trainerName: 'Selin Kaya',
      capacity: 16,
      enrolledCount: 10,
    ),
    ClassSession(
      id: 3,
      name: 'Çocuk BJJ',
      category: ClassCategory.bjj,
      timeRange: '17:00–18:00',
      trainerName: 'Emre Yılmaz',
      capacity: 12,
      enrolledCount: 12,
    ),
  ];

  @override
  Future<List<ClassSession>> getClassSessions() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_sessions);
  }

  @override
  Future<void> reserveSpot(int classId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final index = _sessions.indexWhere((s) => s.id == classId);
    final session = _sessions[index];
    if (session.isFull || session.isReservedByMe) {
      throw StateError('Class $classId cannot be reserved (full or already reserved).');
    }
    final updated = [..._sessions];
    updated[index] = session.copyWith(
      enrolledCount: session.enrolledCount + 1,
      isReservedByMe: true,
    );
    _sessions = updated;
  }
}

@riverpod
ClassRepository classRepository(Ref ref) => FakeClassRepository();
```

- [ ] **Step 4: Run code generation and verify tests pass**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/classes/data/fake_class_repository_test.dart
```
Expected: `fake_class_repository.g.dart` generated; 3 tests passed.

- [ ] **Step 5: Write the failing test for `classListProvider`**

```dart
// test/features/classes/presentation/providers/class_list_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/classes/data/fake_class_repository.dart';
import 'package:gym_app/features/classes/domain/class_repository.dart';
import 'package:gym_app/features/classes/domain/class_session.dart';
import 'package:gym_app/features/classes/presentation/providers/class_list_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockClassRepository extends Mock implements ClassRepository {}

void main() {
  late _MockClassRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _MockClassRepository();
    container = ProviderContainer(
      overrides: [classRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('build() loads sessions from the repository', () async {
    when(() => repository.getClassSessions()).thenAnswer(
      (_) async => const [
        ClassSession(
          id: 1,
          name: 'Test Ders',
          category: ClassCategory.bjj,
          timeRange: '10:00–11:00',
          trainerName: 'Test Eğitmen',
          capacity: 10,
          enrolledCount: 3,
        ),
      ],
    );

    final result = await container.read(classListProvider.future);

    expect(result, hasLength(1));
    expect(result.single.name, 'Test Ders');
  });

  test('reserveSpot calls the repository then refreshes the list', () async {
    when(() => repository.getClassSessions()).thenAnswer(
      (_) async => const [
        ClassSession(
          id: 1,
          name: 'Test Ders',
          category: ClassCategory.bjj,
          timeRange: '10:00–11:00',
          trainerName: 'Test Eğitmen',
          capacity: 10,
          enrolledCount: 3,
        ),
      ],
    );
    when(() => repository.reserveSpot(1)).thenAnswer((_) async {});

    await container.read(classListProvider.future);
    await container.read(classListProvider.notifier).reserveSpot(1);

    verify(() => repository.reserveSpot(1)).called(1);
    verify(() => repository.getClassSessions()).called(2);
  });
}
```

- [ ] **Step 6: Run test to verify it fails**

Run: `flutter test test/features/classes/presentation/providers/class_list_provider_test.dart`
Expected: FAIL — `class_list_provider.dart` not found.

- [ ] **Step 7: Implement `classListProvider`**

Unlike Branch's `addBranch` (which appends a locally-known result), reserving a spot re-fetches the whole list from the repository afterward — simpler, and correct here because `FakeClassRepository` is itself the source of truth for the mutation (no separate "what the server returned" vs. "what we already knew" gap to reconcile).

```dart
// lib/features/classes/presentation/providers/class_list_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/fake_class_repository.dart';
import '../../domain/class_session.dart';

part 'class_list_provider.g.dart';

@riverpod
class ClassList extends _$ClassList {
  @override
  Future<List<ClassSession>> build() {
    return ref.watch(classRepositoryProvider).getClassSessions();
  }

  Future<void> reserveSpot(int classId) async {
    final repository = ref.read(classRepositoryProvider);
    await repository.reserveSpot(classId);
    state = await AsyncValue.guard(repository.getClassSessions);
  }
}
```

- [ ] **Step 8: Run code generation and verify tests pass**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/classes
```
Expected: `class_list_provider.g.dart` generated; 5 tests passed (3 repository + 2 provider).

- [ ] **Step 9: Verify and commit**

Run: `flutter analyze lib/features/classes test/features/classes`
Expected: no issues.

```bash
git add lib/features/classes test/features/classes
git commit -m "Add class session domain, fake repository with reservation mutation, and provider"
```

---

## Task 10: Classes Screen (Dersler)

**Files:**
- Create: `lib/features/classes/presentation/screens/classes_screen.dart`

Category filtering happens client-side in the screen (a local `ConsumerState` field), not in the repository — the spec's "Tümü/BJJ/Fitness" chips filter the already-loaded list, they don't trigger a new fetch. The date strip is decorative in this scope (selecting a different day does not change which sessions are shown — the spec calls this out explicitly as a deliberate simplification, not a missing feature).

- [ ] **Step 1: Write `ClassesScreen`**

```dart
// lib/features/classes/presentation/screens/classes_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/class_session.dart';
import '../providers/class_list_provider.dart';

class ClassesScreen extends ConsumerStatefulWidget {
  const ClassesScreen({super.key});

  @override
  ConsumerState<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends ConsumerState<ClassesScreen> {
  ClassCategory? _selectedCategory;
  int _reservingId = -1;
  int _selectedDayIndex = 1;

  static const _weekDates = [
    ('22', 'Pzt'), ('23', 'Sal'), ('24', 'Çar'), ('25', 'Per'), ('26', 'Cum'),
  ];

  Future<void> _reserve(int classId) async {
    setState(() => _reservingId = classId);
    try {
      await ref.read(classListProvider.notifier).reserveSpot(classId);
    } finally {
      if (mounted) setState(() => _reservingId = -1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sessionsAsync = ref.watch(classListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.classesTitle)),
      body: sessionsAsync.when(
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
                  onPressed: () => ref.invalidate(classListProvider),
                  child: Text(l10n.commonRetry),
                ),
              ],
            ),
          ),
        ),
        data: (sessions) {
          final filtered = _selectedCategory == null
              ? sessions
              : sessions.where((s) => s.category == _selectedCategory).toList();

          return Column(
            children: [
              // Decorative date strip — per spec, selecting a different day does not
              // change which sessions are shown below (deliberate simplification, not
              // a missing feature).
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                child: Row(
                  children: [
                    for (var i = 0; i < _weekDates.length; i++)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedDayIndex = i),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: i == _selectedDayIndex ? AppColors.primary : AppColors.surface,
                              border: i == _selectedDayIndex ? null : Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _weekDates[i].$1,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: i == _selectedDayIndex
                                            ? AppColors.onPrimary
                                            : AppColors.onBackground,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                Text(
                                  _weekDates[i].$2,
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: i == _selectedDayIndex
                                            ? AppColors.onPrimary.withValues(alpha: 0.7)
                                            : AppColors.onBackgroundFaint,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text(l10n.classesFilterAll),
                      selected: _selectedCategory == null,
                      onSelected: (_) => setState(() => _selectedCategory = null),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ChoiceChip(
                      label: Text(l10n.classesCategoryBjj),
                      selected: _selectedCategory == ClassCategory.bjj,
                      onSelected: (_) => setState(() => _selectedCategory = ClassCategory.bjj),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ChoiceChip(
                      label: Text(l10n.classesCategoryFitness),
                      selected: _selectedCategory == ClassCategory.fitness,
                      onSelected: (_) => setState(() => _selectedCategory = ClassCategory.fitness),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) => _ClassCard(
                    session: filtered[index],
                    isReserving: _reservingId == filtered[index].id,
                    onReserve: () => _reserve(filtered[index].id),
                    l10n: l10n,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.session,
    required this.isReserving,
    required this.onReserve,
    required this.l10n,
  });

  final ClassSession session;
  final bool isReserving;
  final VoidCallback onReserve;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final categoryLabel =
        session.category == ClassCategory.bjj ? l10n.classesCategoryBjj : l10n.classesCategoryFitness;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(session.name, style: textTheme.titleMedium),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.successSurface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text(
                    categoryLabel,
                    style: textTheme.labelSmall?.copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${session.timeRange} · ${session.trainerName} · '
              '${l10n.classesCapacityLabel(session.enrolledCount, session.capacity)}',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            if (session.isReservedByMe)
              ElevatedButton(onPressed: null, child: Text(l10n.classesReservedButton))
            else if (session.isFull)
              OutlinedButton(onPressed: null, child: Text(l10n.classesWaitlistButton))
            else
              ElevatedButton(
                onPressed: isReserving ? null : onReserve,
                child: isReserving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                      )
                    : Text(l10n.classesReserveButton),
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify and commit**

Run: `flutter analyze lib/features/classes/presentation/screens/classes_screen.dart`
Expected: no issues in this file on its own.

```bash
git add lib/features/classes/presentation/screens/classes_screen.dart
git commit -m "Add classes screen"
```

---

## Task 11: Progress Feature — Domain + Fake Repository + Provider

**Files:**
- Create: `lib/features/progress/domain/progress_summary.dart`
- Create: `lib/features/progress/domain/progress_repository.dart`
- Create: `lib/features/progress/data/fake_progress_repository.dart`
- Create: `lib/features/progress/presentation/providers/progress_summary_provider.dart`
- Test: `test/features/progress/data/fake_progress_repository_test.dart`
- Test: `test/features/progress/presentation/providers/progress_summary_provider_test.dart`

`ProgressCategory` is defined independently here (not imported from `features/classes`) — each feature owns its domain vocabulary, per the architecture note in the spec; the BJJ/Fitness split happens to exist in two features but they don't share a type. Field names are deliberately category-agnostic (`achievementTitle`/`achievementQuote`, not `beltName`) since a "kuşak" (belt) concept only makes sense for BJJ — Fitness uses the same fields for a different kind of milestone text.

- [ ] **Step 1: Write the failing test for `FakeProgressRepository`**

```dart
// test/features/progress/data/fake_progress_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/progress/data/fake_progress_repository.dart';
import 'package:gym_app/features/progress/domain/progress_summary.dart';

void main() {
  test('getProgress returns different data for bjj and fitness categories', () async {
    final repository = FakeProgressRepository();

    final bjj = await repository.getProgress(ProgressCategory.bjj);
    final fitness = await repository.getProgress(ProgressCategory.fitness);

    expect(bjj.achievementTitle, isNot(equals(fitness.achievementTitle)));
    expect(bjj.techniqueValue, inInclusiveRange(0.0, 1.0));
    expect(fitness.techniqueValue, inInclusiveRange(0.0, 1.0));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/progress/data/fake_progress_repository_test.dart`
Expected: FAIL — `package:gym_app/features/progress/data/fake_progress_repository.dart` not found.

- [ ] **Step 3: Implement `ProgressCategory`, `ProgressSummary`, `ProgressRepository`, `FakeProgressRepository`**

```dart
// lib/features/progress/domain/progress_summary.dart
enum ProgressCategory { bjj, fitness }

class ProgressSummary {
  const ProgressSummary({
    required this.achievementTitle,
    required this.achievementQuote,
    required this.classesThisMonth,
    required this.techniqueValue,
    required this.attendanceValue,
    required this.conditionValue,
    required this.trainerNoteText,
    required this.trainerNoteAuthor,
    required this.trainerNoteDate,
  });

  final String achievementTitle;
  final String achievementQuote;
  final int classesThisMonth;
  final double techniqueValue;
  final double attendanceValue;
  final double conditionValue;
  final String trainerNoteText;
  final String trainerNoteAuthor;
  final String trainerNoteDate;
}
```

```dart
// lib/features/progress/domain/progress_repository.dart
import 'progress_summary.dart';

abstract interface class ProgressRepository {
  Future<ProgressSummary> getProgress(ProgressCategory category);
}
```

```dart
// lib/features/progress/data/fake_progress_repository.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/progress_repository.dart';
import '../domain/progress_summary.dart';

part 'fake_progress_repository.g.dart';

class FakeProgressRepository implements ProgressRepository {
  static const _bjj = ProgressSummary(
    achievementTitle: 'Beyaz Kuşak · 2. derece',
    achievementQuote: 'Yolculuk kuşakla değil, çabayla ölçülür.',
    classesThisMonth: 11,
    techniqueValue: 0.65,
    attendanceValue: 0.80,
    conditionValue: 0.50,
    trainerNoteText: 'Guard geçişlerinde belirgin ilerleme.',
    trainerNoteAuthor: 'Mert Demir',
    trainerNoteDate: '22.09.2026',
  );

  static const _fitness = ProgressSummary(
    achievementTitle: 'Kondisyon Seviyesi: Orta',
    achievementQuote: 'Küçük adımlar, büyük değişim.',
    classesThisMonth: 9,
    techniqueValue: 0.55,
    attendanceValue: 0.70,
    conditionValue: 0.75,
    trainerNoteText: 'Squat formunda gözle görülür gelişim.',
    trainerNoteAuthor: 'Selin Kaya',
    trainerNoteDate: '20.09.2026',
  );

  @override
  Future<ProgressSummary> getProgress(ProgressCategory category) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return category == ProgressCategory.bjj ? _bjj : _fitness;
  }
}

@riverpod
ProgressRepository progressRepository(Ref ref) => FakeProgressRepository();
```

- [ ] **Step 4: Run code generation and verify the repository test passes**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/progress/data/fake_progress_repository_test.dart
```
Expected: `fake_progress_repository.g.dart` generated; 1 test passed.

- [ ] **Step 5: Write the failing test for `progressSummaryProvider`**

`progressSummaryProvider` takes `ProgressCategory` as an argument — `riverpod_generator` auto-generates a family provider for any `@riverpod` function whose parameters (beyond `Ref`) form the family key, so `progressSummaryProvider(ProgressCategory.bjj)` and `progressSummaryProvider(ProgressCategory.fitness)` are two independently-cached provider instances with no extra code needed.

```dart
// test/features/progress/presentation/providers/progress_summary_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/progress/data/fake_progress_repository.dart';
import 'package:gym_app/features/progress/domain/progress_repository.dart';
import 'package:gym_app/features/progress/domain/progress_summary.dart';
import 'package:gym_app/features/progress/presentation/providers/progress_summary_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockProgressRepository extends Mock implements ProgressRepository {}

void main() {
  test('loads the summary for the requested category from the repository', () async {
    final repository = _MockProgressRepository();
    when(() => repository.getProgress(ProgressCategory.fitness)).thenAnswer(
      (_) async => const ProgressSummary(
        achievementTitle: 'Test Başlık',
        achievementQuote: 'Test Alıntı',
        classesThisMonth: 4,
        techniqueValue: 0.3,
        attendanceValue: 0.4,
        conditionValue: 0.5,
        trainerNoteText: 'Test Not',
        trainerNoteAuthor: 'Test Eğitmen',
        trainerNoteDate: '01.01.2026',
      ),
    );
    final container = ProviderContainer(
      overrides: [progressRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final summary = await container.read(progressSummaryProvider(ProgressCategory.fitness).future);

    expect(summary.achievementTitle, 'Test Başlık');
    expect(summary.classesThisMonth, 4);
  });
}
```

- [ ] **Step 6: Run test to verify it fails**

Run: `flutter test test/features/progress/presentation/providers/progress_summary_provider_test.dart`
Expected: FAIL — `progress_summary_provider.dart` not found.

- [ ] **Step 7: Implement `progressSummaryProvider`**

```dart
// lib/features/progress/presentation/providers/progress_summary_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/fake_progress_repository.dart';
import '../../domain/progress_summary.dart';

part 'progress_summary_provider.g.dart';

@riverpod
Future<ProgressSummary> progressSummary(Ref ref, ProgressCategory category) {
  return ref.watch(progressRepositoryProvider).getProgress(category);
}
```

- [ ] **Step 8: Run code generation and verify tests pass**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/progress
```
Expected: `progress_summary_provider.g.dart` generated; 2 tests passed.

- [ ] **Step 9: Verify and commit**

Run: `flutter analyze lib/features/progress test/features/progress`
Expected: no issues.

```bash
git add lib/features/progress test/features/progress
git commit -m "Add progress summary domain, fake repository and family provider"
```

---

## Task 12: Progress Screen (Gelişimim)

**Files:**
- Create: `lib/features/progress/presentation/screens/progress_screen.dart`

Uses `CircularStatGauge` (Task 4) for the three ring stats.

- [ ] **Step 1: Write `ProgressScreen`**

```dart
// lib/features/progress/presentation/screens/progress_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/circular_stat_gauge.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/progress_summary.dart';
import '../providers/progress_summary_provider.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  ProgressCategory _selectedCategory = ProgressCategory.bjj;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final summaryAsync = ref.watch(progressSummaryProvider(_selectedCategory));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.progressTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            child: Row(
              children: [
                Expanded(
                  child: _CategoryTab(
                    label: l10n.progressCategoryBjj,
                    selected: _selectedCategory == ProgressCategory.bjj,
                    onTap: () => setState(() => _selectedCategory = ProgressCategory.bjj),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _CategoryTab(
                    label: l10n.progressCategoryFitness,
                    selected: _selectedCategory == ProgressCategory.fitness,
                    onTap: () => setState(() => _selectedCategory = ProgressCategory.fitness),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: summaryAsync.when(
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
                        onPressed: () => ref.invalidate(progressSummaryProvider(_selectedCategory)),
                        child: Text(l10n.commonRetry),
                      ),
                    ],
                  ),
                ),
              ),
              data: (summary) => _ProgressContent(l10n: l10n, summary: summary),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          border: selected ? null : Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? AppColors.onPrimary : AppColors.onBackground,
              ),
        ),
      ),
    );
  }
}

class _ProgressContent extends StatelessWidget {
  const _ProgressContent({required this.l10n, required this.summary});

  final AppLocalizations l10n;
  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Icon(Icons.military_tech_outlined, color: AppColors.onBackgroundFaint, size: 32),
                const SizedBox(height: AppSpacing.sm),
                Text(summary.achievementTitle, style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '"${summary.achievementQuote}"',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.progressMonthLabel, style: textTheme.labelSmall),
                Text(l10n.progressClassesCount(summary.classesThisMonth), style: textTheme.titleMedium),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.progressAreasLabel, style: textTheme.labelSmall),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            CircularStatGauge(
              value: summary.techniqueValue,
              color: AppColors.primary,
              label: l10n.progressTechnique,
            ),
            CircularStatGauge(
              value: summary.attendanceValue,
              color: AppColors.secondary,
              label: l10n.progressAttendance,
            ),
            CircularStatGauge(
              value: summary.conditionValue,
              color: AppColors.onBackground,
              label: l10n.progressCondition,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.progressTrainerNoteLabel, style: textTheme.labelSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(summary.trainerNoteText, style: textTheme.bodyLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${summary.trainerNoteAuthor} · ${summary.trainerNoteDate}',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Verify and commit**

Run: `flutter analyze lib/features/progress/presentation/screens/progress_screen.dart`
Expected: no issues in this file on its own.

```bash
git add lib/features/progress/presentation/screens/progress_screen.dart
git commit -m "Add progress screen"
```

---

## Task 13: Membership Feature — Domain + Fake Repository (with Freeze Mutation) + Provider

**Files:**
- Create: `lib/features/membership/domain/membership_summary.dart`
- Create: `lib/features/membership/domain/membership_repository.dart`
- Create: `lib/features/membership/data/fake_membership_repository.dart`
- Create: `lib/features/membership/presentation/providers/membership_provider.dart`
- Test: `test/features/membership/data/fake_membership_repository_test.dart`
- Test: `test/features/membership/presentation/providers/membership_provider_test.dart`

"Üyeliği Yenile" (renew) has no repository method — per the spec it's a pure UI-level mock (a `SnackBar`, no state change), so nothing to put behind an interface. Only "Dondurma Talebi" (freeze) actually mutates state.

- [ ] **Step 1: Write the failing test for `FakeMembershipRepository`**

```dart
// test/features/membership/data/fake_membership_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/membership/data/fake_membership_repository.dart';
import 'package:gym_app/features/membership/domain/membership_summary.dart';

void main() {
  test('getMembership returns the fixed active membership with payment history', () async {
    final repository = FakeMembershipRepository();

    final summary = await repository.getMembership();

    expect(summary.status, MembershipStatus.active);
    expect(summary.paymentHistory, hasLength(3));
  });

  test('requestFreeze flips the status to frozen', () async {
    final repository = FakeMembershipRepository();

    await repository.requestFreeze();
    final summary = await repository.getMembership();

    expect(summary.status, MembershipStatus.frozen);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/membership/data/fake_membership_repository_test.dart`
Expected: FAIL — `package:gym_app/features/membership/data/fake_membership_repository.dart` not found.

- [ ] **Step 3: Implement `MembershipStatus`, `PaymentHistoryEntry`, `MembershipSummary`, `MembershipRepository`, `FakeMembershipRepository`**

```dart
// lib/features/membership/domain/membership_summary.dart
enum MembershipStatus { active, frozen }

class PaymentHistoryEntry {
  const PaymentHistoryEntry({required this.date, required this.amount});

  final String date;
  final String amount;
}

class MembershipSummary {
  const MembershipSummary({
    required this.packageName,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.price,
    required this.isPaid,
    required this.paymentHistory,
  });

  final String packageName;
  final MembershipStatus status;
  final String startDate;
  final String endDate;
  final String price;
  final bool isPaid;
  final List<PaymentHistoryEntry> paymentHistory;

  MembershipSummary copyWith({MembershipStatus? status}) {
    return MembershipSummary(
      packageName: packageName,
      status: status ?? this.status,
      startDate: startDate,
      endDate: endDate,
      price: price,
      isPaid: isPaid,
      paymentHistory: paymentHistory,
    );
  }
}
```

```dart
// lib/features/membership/domain/membership_repository.dart
import 'membership_summary.dart';

abstract interface class MembershipRepository {
  Future<MembershipSummary> getMembership();
  Future<void> requestFreeze();
}
```

```dart
// lib/features/membership/data/fake_membership_repository.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/membership_repository.dart';
import '../domain/membership_summary.dart';

part 'fake_membership_repository.g.dart';

class FakeMembershipRepository implements MembershipRepository {
  MembershipSummary _summary = const MembershipSummary(
    packageName: 'BJJ + Fitness Aylık',
    status: MembershipStatus.active,
    startDate: '01.09.2026',
    endDate: '30.09.2026',
    price: '₺2.500',
    isPaid: true,
    paymentHistory: [
      PaymentHistoryEntry(date: '01.09.2026', amount: '₺2.500'),
      PaymentHistoryEntry(date: '01.08.2026', amount: '₺2.500'),
      PaymentHistoryEntry(date: '01.07.2026', amount: '₺2.500'),
    ],
  );

  @override
  Future<MembershipSummary> getMembership() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _summary;
  }

  @override
  Future<void> requestFreeze() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _summary = _summary.copyWith(status: MembershipStatus.frozen);
  }
}

@riverpod
MembershipRepository membershipRepository(Ref ref) => FakeMembershipRepository();
```

- [ ] **Step 4: Run code generation and verify tests pass**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/membership/data/fake_membership_repository_test.dart
```
Expected: `fake_membership_repository.g.dart` generated; 2 tests passed.

- [ ] **Step 5: Write the failing test for `membershipProvider`**

```dart
// test/features/membership/presentation/providers/membership_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/membership/data/fake_membership_repository.dart';
import 'package:gym_app/features/membership/domain/membership_repository.dart';
import 'package:gym_app/features/membership/domain/membership_summary.dart';
import 'package:gym_app/features/membership/presentation/providers/membership_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

void main() {
  late _MockMembershipRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _MockMembershipRepository();
    container = ProviderContainer(
      overrides: [membershipRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  const activeSummary = MembershipSummary(
    packageName: 'Test Paket',
    status: MembershipStatus.active,
    startDate: '01.01.2026',
    endDate: '31.01.2026',
    price: '₺1.000',
    isPaid: true,
    paymentHistory: [],
  );

  test('build() loads the membership from the repository', () async {
    when(() => repository.getMembership()).thenAnswer((_) async => activeSummary);

    final summary = await container.read(membershipProvider.future);

    expect(summary.packageName, 'Test Paket');
  });

  test('requestFreeze calls the repository then refreshes', () async {
    when(() => repository.getMembership()).thenAnswer((_) async => activeSummary);
    when(() => repository.requestFreeze()).thenAnswer((_) async {});

    await container.read(membershipProvider.future);
    await container.read(membershipProvider.notifier).requestFreeze();

    verify(() => repository.requestFreeze()).called(1);
    verify(() => repository.getMembership()).called(2);
  });
}
```

- [ ] **Step 6: Run test to verify it fails**

Run: `flutter test test/features/membership/presentation/providers/membership_provider_test.dart`
Expected: FAIL — `membership_provider.dart` not found.

- [ ] **Step 7: Implement `membershipProvider`**

```dart
// lib/features/membership/presentation/providers/membership_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/fake_membership_repository.dart';
import '../../domain/membership_summary.dart';

part 'membership_provider.g.dart';

@riverpod
class Membership extends _$Membership {
  @override
  Future<MembershipSummary> build() {
    return ref.watch(membershipRepositoryProvider).getMembership();
  }

  Future<void> requestFreeze() async {
    final repository = ref.read(membershipRepositoryProvider);
    await repository.requestFreeze();
    state = await AsyncValue.guard(repository.getMembership);
  }
}
```

- [ ] **Step 8: Run code generation and verify tests pass**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/membership
```
Expected: `membership_provider.g.dart` generated; 4 tests passed (2 repository + 2 provider).

- [ ] **Step 9: Verify and commit**

Run: `flutter analyze lib/features/membership test/features/membership`
Expected: no issues.

```bash
git add lib/features/membership test/features/membership
git commit -m "Add membership domain, fake repository with freeze mutation, and provider"
```

---

## Task 14: Membership Screen (Üyeliğim)

**Files:**
- Create: `lib/features/membership/presentation/screens/membership_screen.dart`

- [ ] **Step 1: Write `MembershipScreen`**

```dart
// lib/features/membership/presentation/screens/membership_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/membership_summary.dart';
import '../providers/membership_provider.dart';

class MembershipScreen extends ConsumerStatefulWidget {
  const MembershipScreen({super.key});

  @override
  ConsumerState<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends ConsumerState<MembershipScreen> {
  bool _isFreezing = false;

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
                  : Text(l10n.membershipFreezeButton),
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
```

- [ ] **Step 2: Verify and commit**

Run: `flutter analyze lib/features/membership/presentation/screens/membership_screen.dart`
Expected: no issues in this file on its own.

```bash
git add lib/features/membership/presentation/screens/membership_screen.dart
git commit -m "Add membership screen"
```

---

## Task 15: Real `AppShell` — 4-Tab Floating Nav Bar

**Files:**
- Modify: `lib/core/widgets/app_shell.dart`

All 4 tab screens now exist. `AppShell` moves from the old `Widget child` shape (Mobile Foundation, single-route, pre-crash-fix) to `go_router`'s `StatefulShellRoute` shape: it receives a `StatefulNavigationShell`, which is itself the body (it manages which branch's `Navigator` is visible) and exposes `currentIndex`/`goBranch(index)` for the nav bar to drive. 4 real destinations means Flutter's `NavigationBar` `destinations.length >= 2` assertion (the crash from the Mobile Foundation plan's Task 10) is naturally satisfied — nothing special needs to be done to avoid it here.

The nav bar is wrapped in `Padding` + `ClipRRect` to render as a floating, rounded-corner bar with a gap from the screen edges (matching the brainstormed visual) — `AppTheme.dark`'s existing `navigationBarTheme` (surface background, primary-tinted indicator, selected/unselected icon-and-label color logic) already supplies all the actual styling, this task only changes the shape/wrapper and which destinations exist.

**Icon note:** `Icons.home`/`Icons.home_outlined`, `Icons.calendar_month`/`Icons.calendar_month_outlined`, `Icons.show_chart`/`Icons.show_chart_outlined`, and `Icons.person`/`Icons.person_outline` (not `person_outlined` — this one is an irregular older Material Icons name, unlike the newer `_outlined` suffix convention) are the icons used below. If `flutter analyze` reports any of these as undefined for the installed Flutter SDK version, substitute the closest valid icon with the same outlined/filled pairing — this is a cosmetic substitution, not a design decision to escalate.

- [ ] **Step 1: Rewrite `AppShell`**

```dart
// lib/core/widgets/app_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_spacing.dart';
import '../../l10n/generated/app_localizations.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(child: navigationShell),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: l10n.navHome,
              ),
              NavigationDestination(
                icon: const Icon(Icons.calendar_month_outlined),
                selectedIcon: const Icon(Icons.calendar_month),
                label: l10n.navClasses,
              ),
              NavigationDestination(
                icon: const Icon(Icons.show_chart_outlined),
                selectedIcon: const Icon(Icons.show_chart),
                label: l10n.navProgress,
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: l10n.navMembership,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify and commit**

This file alone won't fully analyze clean yet — it references nothing outside itself except already-existing l10n keys, so it should be fine on its own, but the whole-project `flutter analyze` still fails until Task 16 rewrites the router to actually construct `AppShell` with a `navigationShell`. Run: `flutter analyze lib/core/widgets/app_shell.dart` and confirm no issues in this file specifically.

```bash
git add lib/core/widgets/app_shell.dart
git commit -m "Rewrite AppShell for StatefulShellRoute 4-tab navigation"
```

---

## Task 16: Real Router — `/login` + 4-Branch `StatefulShellRoute`

**Files:**
- Modify: `lib/core/router/app_router.dart`

Replaces Task 1's temporary placeholder. The router itself watches `authStateProvider` and rebuilds (a fresh `GoRouter` instance) whenever it changes — `ref.watch(authStateProvider)` inside the `@riverpod` function means logging in or out causes `appRouterProvider` to emit a new `GoRouter`, and `MaterialApp.router` (already watching `appRouterProvider` in `main.dart`, unchanged) picks it up automatically. No `refreshListenable`/`Stream` plumbing needed — this is the simplest correct way to combine Riverpod auth state with go_router redirects.

**`main.dart` needs no changes** — it already does `ref.watch(appRouterProvider)`, references `AppTheme.dark`, and wires the l10n delegates; none of that is Branch- or route-specific.

- [ ] **Step 1: Rewrite `app_router.dart`**

```dart
// lib/core/router/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../widgets/app_shell.dart';
import '../../features/auth/presentation/providers/auth_state_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/classes/presentation/screens/classes_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/membership/presentation/screens/membership_screen.dart';
import '../../features/progress/presentation/screens/progress_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  final isAuthed = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: isAuthed ? '/home' : '/login',
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login';
      if (!isAuthed && !loggingIn) return '/login';
      if (isAuthed && loggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/home', builder: (context, state) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/classes', builder: (context, state) => const ClassesScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/progress', builder: (context, state) => const ProgressScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/membership', builder: (context, state) => const MembershipScreen()),
            ],
          ),
        ],
      ),
    ],
  );
}
```

- [ ] **Step 2: Run code generation**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `app_router.g.dart` regenerated, no conflicts.

- [ ] **Step 3: Verify the whole project now analyzes and tests cleanly**

Run:
```bash
flutter analyze
flutter test
```
Expected: `No issues found!`; every test across `test/core`, `test/features/auth`, `test/features/home`, `test/features/classes`, `test/features/progress`, `test/features/membership` passes (count: 2 core + 2 auth + 2 home + 5 classes + 2 progress + 4 membership = 17 tests — confirm the actual total matches this sum, don't worry if a task above added one extra test during its own TDD step, just confirm everything is green and accounted for).

This is the first point where the whole rewritten app compiles as one piece — `LoginScreen` → (fake login) → `authStateProvider` flips → router rebuilds → 4-tab shell renders.

- [ ] **Step 4: Commit**

```bash
git add lib/core/router/app_router.dart lib/core/router/app_router.g.dart
git commit -m "Add real router: login gate + 4-branch StatefulShellRoute"
```

---

## Task 17: Manual End-to-End Smoke Test

**Files:** none (verification-only task).

This is where the Mobile Foundation plan's own smoke test caught two real bugs (missing web platform, `NavigationBar` crash) that no automated test had caught — apply the same discipline here: actually run the app and look at it, don't just trust `flutter analyze`/`flutter test`.

- [ ] **Step 1: Run the app**

Use the PowerShell tool (Bash cannot invoke Flutter CLI correctly here):
```powershell
Set-Location "C:\Users\MBEYAZBULUT\Documents\GitHub\GymApp"
Start-Process -FilePath "flutter" -ArgumentList "run","-d","chrome","--web-port=8765" -RedirectStandardOutput "$env:TEMP\member_exp_stdout.log" -RedirectStandardError "$env:TEMP\member_exp_stderr.log" -WindowStyle Hidden -PassThru
```
Poll `http://localhost:8765/` until it returns 200, then wait for the log to show `Starting application from main method` followed by either normal idle output or an `EXCEPTION CAUGHT BY WIDGETS LIBRARY` block. If there's an exception block, this is a real bug — fix it, do not report success with a crash present.

- [ ] **Step 2: Verify the login → home flow**

Confirm from the log/no-crash state that the app is serving; since this is a headless verification (no visual browser driver available in this environment — note this honestly rather than claiming a screenshot was taken), verify structurally instead: re-read `lib/core/router/app_router.dart` and confirm `initialLocation` logic is correct for the logged-out default (`isAuthed` starts `false` per `AuthState.build()`, so `initialLocation` evaluates to `/login`), and that `LoginScreen`'s `_submit` calls `authStateProvider.notifier.logIn()` after a successful (always-successful) `FakeAuthRepository.login`. Cross-check this reasoning against the actual running app's absence of crash-log exceptions.

- [ ] **Step 3: Stop the process cleanly**

Find and stop only the `dart`/`dartaotruntime` processes this started (never touch unrelated `chrome.exe` processes — the user may have their own browser windows open):
```powershell
Get-Process | Where-Object { $_.ProcessName -match 'dart' } | Stop-Process -Force -ErrorAction SilentlyContinue
```

- [ ] **Step 4: Run the full automated suite one more time as a final gate**

Run:
```powershell
flutter analyze
flutter test
```
Expected: `No issues found!`, all tests passing — no regressions from the manual run (nothing should have changed, this task is verification-only).

- [ ] **Step 5: Update the mobile project memory and commit**

Edit `.claude/memory/project-mobile-foundation-status.md` in this repo (or create a new `project-member-experience-status.md` if that file has grown unwieldy — controller's judgment at execution time): record that the Member Experience plan is complete, the Branch feature is gone, the primary accent color changed to `#8BC34A`, and list any bugs found/fixed during this smoke test (matching how the Mobile Foundation plan's own Task 10 entry was written).

```bash
git add .claude/memory
git commit -m "Update mobile memory: Member Experience plan complete"
```
