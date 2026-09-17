# Tenant Onboarding (Mobile) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the two staff-facing screens the backend's new endpoints unlock — a Super-Admin-only "Yeni Firma Ekle" (create Company+Branch+GymAdmin) screen and a GymAdmin/BranchManager "Üye/Antrenör Ekle" screen — surfaced conditionally in the existing `AppDrawer` based on the logged-in user's real role, then retire the self-service Register screen since new accounts are staff-created from here on.

**Architecture:** One half of a two-repo feature. The backend half is planned separately at `C:\Users\MBEYAZBULUT\Documents\GitHub\GymAppApi\docs\superpowers\plans\2026-09-17-tenant-onboarding.md`. This plan's Tasks 3–4 (the two new screens) are hard-blocked on that plan's Tasks 6–9 (`POST /api/companies`, `POST /api/assignments/staff`) actually being deployed and reachable. This plan's Task 6 (remove Register) and that plan's Task 11 (remove the register endpoints) must happen in that order — **this plan's Task 6 first**, confirmed shipped, *then* the backend's Task 11 — otherwise there's a window with no way to create any account at all on a fresh database.

**Tech Stack:** Flutter, Riverpod (`riverpod_annotation` code-gen), `go_router`, `dio` (already the project's HTTP client — `ApiException.fromDioException` already exists in `lib/core/network/api_exception.dart` but currently has **zero real callers anywhere in the app** — the Branch proof-of-concept that first used it was deleted when Mobile Foundation was superseded; this plan's `TenantRepository` is its first real use), `intl_phone_field` (already a dependency, used by the screens' phone fields).

## PLAN COMPLETE (2026-09-17) — all 6 tasks done, plus one scope addition

All 6 tasks shipped; see each task's own "Step N: Commit" line below for its commit hash. Two things happened that weren't in the original text:

1. **Company Management screen (added mid-plan, not in the original scope).** User feedback while reviewing Task 3's live UI: going straight from the drawer into a bare "Yeni Firma Ekle" form was illogical — there needed to be somewhere to see and manage companies that already exist. Added, with the user's explicit go-ahead for the fuller scope (list + rename + activate/deactivate, not just a list):
   - **Backend** (`GymAppApi`, commit `b74bcfe`): `GET /api/companies`, `GET /api/companies/{id}`, `PATCH /api/companies/{id}` (rename), `PATCH /api/companies/{id}/active` (toggle), all `SuperAdminOnly`.
   - **Mobile** (commit `73387c2`): `CompanyManagementScreen` (list, branch count, Aktif/Pasif `StatusPill`) and `CompanyDetailScreen` (rename, active toggle, branch list) at `/admin/companies` and `/admin/companies/:id`. The drawer's admin item now opens this list instead of jumping straight to Create Company; "Yeni Firma Ekle" is reached from the list's app bar action instead.
   - **Design polish pass** (commit `7d4fb05`): the first version used bare `Material`/no border and `radiusMd`, inconsistent with the app's own locked visual language ([[feedback-visual-language]]) — cards need `color: AppColors.surface` + `Border.all(AppColors.border)` + `AppSpacing.radiusLg`, per `membership_screen.dart`'s own cards. Rebuilt both screens to that standard, added row icons and `StatusPill` (reused, not reinvented) for Aktif/Pasif, and reordered the drawer so the admin item(s) sit above a divider, ahead of Dil/Dondur/Sil, per further user feedback.
   - Verified genuinely end-to-end against the live `GymAppApi` backend via a `flutter build web --release` + Playwright-driven browser session (login as the seeded SuperAdmin, open the drawer, list companies, rename one, toggle it inactive, confirm the badge — all real HTTP calls, not mocked).
2. **Task 6 found two extra cleanup spots the plan's "Key facts" didn't anticipate** (see that task's own commit note): `forgot_password_screen.dart` was reusing `registerPasswordTooShort` for its own password field (renamed to `commonPasswordTooShort`, not deleted), and `dio_client.dart`'s `_noAuthPaths` still had a stale pre-OTP-rework `/api/auth/register` entry.

**Next step for whoever picks this up:** `GymAppApi`'s own Task 11 (retire the backend's `/api/auth/register/*` endpoints) was blocked on this plan's Task 6 shipping first — it now has. That backend task is safe to do now.

---

## Key facts (read before starting — verified by reading the actual current code, not memory)

- **`MeResult.assignments` already carries everything needed for role-aware UI** (`lib/features/auth/domain/me_result.dart`, unchanged by this plan except one addition in Task 1):
  ```dart
  class MeAssignment {
    final int? companyId; final String? companyName; final int? branchId; final String role;
  }
  class MeResult {
    final List<MeAssignment> assignments;
    bool get hasActiveMembership => assignments.isNotEmpty;
  }
  ```
  `role` is the backend's `AssignmentRole` enum serialized as a string: exactly one of `"SuperAdmin"`, `"GymAdmin"`, `"BranchManager"`, `"Trainer"`, `"Member"`.
- **The app is genuinely role-UI-greenfield today** — grepping all of `lib/` for role/SuperAdmin/GymAdmin/BranchManager/isAdmin today returns zero branching logic, only unrelated `trainerName` display-copy fields. No pattern to follow here beyond ordinary Riverpod/go_router conventions used elsewhere.
- **`AuthRepository` (`lib/features/auth/domain/auth_repository.dart`) has no company/assignment-creation method** — this is genuinely new mobile surface area, not an extension of anything Auth-shaped. Keep it in its own feature (`lib/features/tenant_onboarding/`), not bolted onto `AuthRepository`.
- **How a new repository should report errors** — copy the *plain* `ApiException` pattern (used nowhere yet, but built for exactly this), **not** `AuthRepository`'s bespoke `AuthException` hierarchy (that one exists to special-case OTP-wrong-code 401s, which does not apply here):
  ```dart
  try {
    await _dio.post<void>('/api/companies', data: {...});
  } on DioException catch (exception) {
    throw ApiException.fromDioException(exception);
  }
  ```
  `ApiException.fromDioException` reads the backend's PascalCase `{"Status":..,"Errors":[...]}` error body (confirmed in `lib/core/network/api_exception.dart`) and exposes `.message` for display.
- **`dioProvider`** (`lib/core/network/dio_client.dart`) already attaches the bearer token and handles silent 401-refresh-retry for every authenticated call — a new repository just does `ref.watch(dioProvider)`, nothing else to wire.
- **The exact screen/provider/repository/l10n conventions to copy** are `register_screen.dart` (form validation, `IntlPhoneField`, submit-button loading-spinner swap, `on ApiException`/`on AuthException catch` → `setState(() => _errorText = ...)`) and `real_auth_repository.dart` (constructor takes `Dio`, one `@riverpod` factory function at the bottom of the same file, `part '<file>.g.dart';`). Both read in full for this plan.
- **`AppDrawer`** (`lib/core/widgets/app_drawer.dart`, this session's own prior work) already watches `currentUserProvider` and lists items via the private `_DrawerItem` widget with `icon`, `label`, `onTap`, optional `color`/`showChevron`. Task 5 adds two more `_DrawerItem`s, conditionally, using the exact same widget — no new drawer-item component needed.
- **l10n:** `lib/l10n/app_tr.arb`/`app_en.arb`, keys added right after the existing `"drawerOpenMenuTooltip"` entry (confirmed present at `app_tr.arb:15-16`). Run `flutter gen-l10n` after editing (regenerates `lib/l10n/generated/`, gitignored, not committed).
- **Full deletion list for Task 6** (self-service registration) — confirmed by reading every one of these files in full: `lib/features/auth/presentation/screens/register_screen.dart` (whole file), the `requestRegistrationOtp`/`completeRegistration` methods in `lib/features/auth/domain/auth_repository.dart` and `lib/features/auth/data/real_auth_repository.dart`, the `/register` route + its `_publicRoutes` entry in `lib/core/router/app_router.dart`, the "Hesabın yok mu? Kayıt ol" `TextButton` in `lib/features/auth/presentation/screens/login_screen.dart`, and every `register*`/`Register*` l10n key. **No test file exercises any of this today** (confirmed: no `register_screen_test.dart`/`login_screen_test.dart` exist) — nothing to delete on the test side.

---

### Task 1: Role helpers on `MeResult`

**Files:**
- Modify: `lib/features/auth/domain/me_result.dart`

- [ ] **Step 1: Add two getters**

```dart
  bool get hasActiveMembership => assignments.isNotEmpty;

  bool get isSuperAdmin => assignments.any((a) => a.role == 'SuperAdmin');

  // The one Assignment (if any) that lets this user manage staff - a
  // GymAdmin oversees every branch of their company (branchId null on their
  // own assignment); a BranchManager is scoped to exactly one branch. Null
  // for a plain Member/Trainer, and for a SuperAdmin who isn't ALSO staff
  // somewhere (SuperAdmin uses "Yeni Firma Ekle" instead, see AppDrawer).
  MeAssignment? get staffAssignment {
    for (final assignment in assignments) {
      if (assignment.role == 'GymAdmin' || assignment.role == 'BranchManager') {
        return assignment;
      }
    }
    return null;
  }
```

(insert right after the existing `bool get hasActiveMembership => assignments.isNotEmpty;` line, inside the `MeResult` class.)

- [ ] **Step 2: Write a test**

Create `test/features/auth/domain/me_result_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/auth/domain/me_result.dart';

MeResult _withAssignments(List<MeAssignment> assignments) => MeResult(
      id: 1,
      fullName: 'Test',
      phone: '+905550000000',
      email: null,
      preferredLanguage: 'tr',
      isAccountFrozen: false,
      assignments: assignments,
    );

void main() {
  test('isSuperAdmin is true when any assignment is SuperAdmin', () {
    final me = _withAssignments([
      const MeAssignment(companyId: null, companyName: null, branchId: null, role: 'SuperAdmin'),
    ]);
    expect(me.isSuperAdmin, isTrue);
  });

  test('isSuperAdmin is false for a plain Member', () {
    final me = _withAssignments([
      const MeAssignment(companyId: 1, companyName: 'Co', branchId: 2, role: 'Member'),
    ]);
    expect(me.isSuperAdmin, isFalse);
  });

  test('staffAssignment returns the GymAdmin assignment', () {
    final gymAdmin = const MeAssignment(companyId: 1, companyName: 'Co', branchId: null, role: 'GymAdmin');
    final me = _withAssignments([gymAdmin]);
    expect(me.staffAssignment, same(gymAdmin));
  });

  test('staffAssignment returns the BranchManager assignment', () {
    final branchManager = const MeAssignment(companyId: 1, companyName: 'Co', branchId: 5, role: 'BranchManager');
    final me = _withAssignments([branchManager]);
    expect(me.staffAssignment, same(branchManager));
  });

  test('staffAssignment is null for a plain Member or Trainer', () {
    final me = _withAssignments([
      const MeAssignment(companyId: 1, companyName: 'Co', branchId: 2, role: 'Member'),
      const MeAssignment(companyId: 1, companyName: 'Co', branchId: 2, role: 'Trainer'),
    ]);
    expect(me.staffAssignment, isNull);
  });
}
```

- [ ] **Step 2b: Run test to verify it fails first**

Run: `flutter test test/features/auth/domain/me_result_test.dart`
Expected: FAIL — `isSuperAdmin`/`staffAssignment` don't exist yet (compile error), confirming the test actually exercises new code once Step 1 lands.

(Since Step 1's code must exist for the file to compile at all, do Step 1 and this test together, then run once — the "write failing test first" ordering is satisfied by writing the test file before re-reading Step 1's diff, not by a separate red run against already-passing code.)

- [ ] **Step 3: Run test to verify it passes**

Run: `flutter test test/features/auth/domain/me_result_test.dart`
Expected: PASS, 5/5.

- [x] **Step 4: Commit** — done, commit `05913e7`.

```bash
git add lib/features/auth/domain/me_result.dart test/features/auth/domain/me_result_test.dart
git commit -m "Add isSuperAdmin/staffAssignment role helpers to MeResult"
```

---

### Task 2: `TenantRepository` — talks to the two new backend endpoints

**Files:**
- Create: `lib/features/tenant_onboarding/domain/branch_option.dart`
- Create: `lib/features/tenant_onboarding/domain/tenant_repository.dart`
- Create: `lib/features/tenant_onboarding/data/real_tenant_repository.dart`
- Test: `test/features/tenant_onboarding/data/real_tenant_repository_test.dart`

- [ ] **Step 1: Write the domain model and interface**

```dart
// lib/features/tenant_onboarding/domain/branch_option.dart
class BranchOption {
  const BranchOption({required this.id, required this.name});

  factory BranchOption.fromJson(Map<String, dynamic> json) =>
      BranchOption(id: json['id'] as int, name: json['name'] as String);

  final int id;
  final String name;
}
```

```dart
// lib/features/tenant_onboarding/domain/tenant_repository.dart
import 'branch_option.dart';

abstract interface class TenantRepository {
  // Company + Branch + a Gym Admin (new or existing user, matched by phone)
  // in one call - Super Admin only, enforced server-side.
  Future<void> createCompany({
    required String companyName,
    required String branchName,
    required String branchAddress,
    required String gymAdminFullName,
    required String gymAdminPhone,
    String? gymAdminEmail,
  });

  // The branches visible to the caller - once the backend's real tenant
  // context is in place, a GymAdmin sees only their own company's branches.
  // Used to populate the branch picker in AddStaffMemberScreen for a
  // GymAdmin (a BranchManager already has a single fixed branch and never
  // needs this).
  Future<List<BranchOption>> listBranches();

  // A new Member/Trainer (new or existing user, matched by phone) attached
  // to one branch - Gym Admin/Branch Manager/Super Admin only, enforced
  // server-side (a Branch Manager is further restricted to their own
  // branch, a Gym Admin to their own company - both re-checked server-side
  // regardless of what branchId is sent here).
  Future<void> addStaffMember({
    required String fullName,
    required String phone,
    String? email,
    required String role, // 'Member' or 'Trainer'
    required int branchId,
  });
}
```

- [ ] **Step 2: Write the failing tests**

```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/api_exception.dart';
import 'package:gym_app/features/tenant_onboarding/data/real_tenant_repository.dart';

void main() {
  late Dio dio;
  late DioAdapter adapterlessDio;

  test('createCompany posts to /api/companies with the given fields', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/companies');
      expect(options.data, {
        'companyName': 'Test Gym',
        'branchName': 'Merkez',
        'branchAddress': 'Adres',
        'gymAdminFullName': 'Ada Admin',
        'gymAdminPhone': '+905551112233',
        'gymAdminEmail': null,
      });
      return ResponseBody.fromString('{}', 201, headers: {'content-type': ['application/json']});
    });
    final repository = RealTenantRepository(dio);

    await repository.createCompany(
      companyName: 'Test Gym',
      branchName: 'Merkez',
      branchAddress: 'Adres',
      gymAdminFullName: 'Ada Admin',
      gymAdminPhone: '+905551112233',
    );
  });

  test('createCompany rethrows a DioException as ApiException', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      return ResponseBody.fromString(
        '{"Status":403,"Errors":["Bu işlem için yetkiniz yok."]}',
        403,
        headers: {'content-type': ['application/json']},
      );
    });
    final repository = RealTenantRepository(dio);

    await expectLater(
      () => repository.createCompany(
        companyName: 'x', branchName: 'x', branchAddress: 'x',
        gymAdminFullName: 'x', gymAdminPhone: 'x',
      ),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Bu işlem için yetkiniz yok.')),
    );
  });

  test('listBranches parses the branch list', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/branches');
      return ResponseBody.fromString(
        '[{"id":1,"name":"Merkez","address":"a","isActive":true}]',
        200,
        headers: {'content-type': ['application/json']},
      );
    });
    final repository = RealTenantRepository(dio);

    final branches = await repository.listBranches();

    expect(branches, hasLength(1));
    expect(branches.single.name, 'Merkez');
  });

  test('addStaffMember posts to /api/assignments/staff with the given fields', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/assignments/staff');
      expect(options.data, {
        'fullName': 'New Trainer',
        'phone': '+905550003333',
        'email': null,
        'role': 'Trainer',
        'branchId': 10,
      });
      return ResponseBody.fromString('{}', 201, headers: {'content-type': ['application/json']});
    });
    final repository = RealTenantRepository(dio);

    await repository.addStaffMember(
      fullName: 'New Trainer',
      phone: '+905550003333',
      role: 'Trainer',
      branchId: 10,
    );
  });
}

typedef _ResponseBuilder = ResponseBody Function(RequestOptions options);

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._respond);

  final _ResponseBuilder _respond;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = _respond(options);
    if (body.statusCode >= 400) {
      throw DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: body.statusCode,
          data: jsonDecode(await body.stream.transform(utf8.decoder).join()),
        ),
      );
    }
    return body;
  }
}
```

Add the two missing imports at the top of the test file: `import 'dart:convert';` and `import 'dart:typed_data';`.

- [ ] **Step 3: Run tests to verify they fail**

Run: `flutter test test/features/tenant_onboarding/data/real_tenant_repository_test.dart`
Expected: FAIL — `RealTenantRepository` doesn't exist yet.

- [ ] **Step 4: Write the implementation**

```dart
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/branch_option.dart';
import '../domain/tenant_repository.dart';

part 'real_tenant_repository.g.dart';

class RealTenantRepository implements TenantRepository {
  RealTenantRepository(this._dio);

  final Dio _dio;

  @override
  Future<void> createCompany({
    required String companyName,
    required String branchName,
    required String branchAddress,
    required String gymAdminFullName,
    required String gymAdminPhone,
    String? gymAdminEmail,
  }) async {
    try {
      await _dio.post<void>('/api/companies', data: {
        'companyName': companyName,
        'branchName': branchName,
        'branchAddress': branchAddress,
        'gymAdminFullName': gymAdminFullName,
        'gymAdminPhone': gymAdminPhone,
        'gymAdminEmail': gymAdminEmail,
      });
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<List<BranchOption>> listBranches() async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/branches');
      return response.data!
          .cast<Map<String, dynamic>>()
          .map(BranchOption.fromJson)
          .toList();
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<void> addStaffMember({
    required String fullName,
    required String phone,
    String? email,
    required String role,
    required int branchId,
  }) async {
    try {
      await _dio.post<void>('/api/assignments/staff', data: {
        'fullName': fullName,
        'phone': phone,
        'email': email,
        'role': role,
        'branchId': branchId,
      });
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }
}

@riverpod
TenantRepository tenantRepository(Ref ref) => RealTenantRepository(ref.watch(dioProvider));
```

- [ ] **Step 5: Generate the Riverpod code and run tests**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter test test/features/tenant_onboarding/data/real_tenant_repository_test.dart`
Expected: PASS, 4/4.

- [x] **Step 6: Commit** — done, commit `95594a4`. (`CompanyDetailDto.data.jsonDecode` type-inference fix during writing: `utf8.decoder.bind(body.stream).join()` instead of `.transform(utf8.decoder)`, which the SDK's stricter generics rejected — see the test file.)

```bash
git add lib/features/tenant_onboarding/ test/features/tenant_onboarding/
git commit -m "Add TenantRepository for company creation and staff-member management"
```

---

### Task 3: "Yeni Firma Ekle" screen (Super Admin)

**Files:**
- Create: `lib/features/tenant_onboarding/presentation/screens/create_company_screen.dart`
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/l10n/app_tr.arb`, `lib/l10n/app_en.arb`

- [ ] **Step 1: Add l10n keys**

In `lib/l10n/app_tr.arb`, right after the existing `"drawerOpenMenuTooltip": "Menüyü aç", "@drawerOpenMenuTooltip": {},` line:

```json
  "drawerCreateCompany": "Yeni Firma Ekle",
  "@drawerCreateCompany": {},
  "createCompanyTitle": "Yeni Firma Ekle",
  "@createCompanyTitle": {},
  "createCompanyNameLabel": "Firma Adı",
  "@createCompanyNameLabel": {},
  "createCompanyBranchNameLabel": "İlk Şube Adı",
  "@createCompanyBranchNameLabel": {},
  "createCompanyBranchAddressLabel": "Şube Adresi",
  "@createCompanyBranchAddressLabel": {},
  "createCompanyGymAdminNameLabel": "Firma Yöneticisi Ad Soyad",
  "@createCompanyGymAdminNameLabel": {},
  "createCompanyGymAdminPhoneLabel": "Firma Yöneticisi Telefon",
  "@createCompanyGymAdminPhoneLabel": {},
  "createCompanyGymAdminEmailLabel": "Firma Yöneticisi E-posta (opsiyonel)",
  "@createCompanyGymAdminEmailLabel": {},
  "createCompanySubmitButton": "Firmayı Oluştur",
  "@createCompanySubmitButton": {},
  "createCompanySuccessMessage": "Firma oluşturuldu. Yönetici, telefonuyla 'Şifremi Unuttum' akışını kullanarak şifresini belirleyebilir.",
  "@createCompanySuccessMessage": {},
```

In `lib/l10n/app_en.arb`, right after the existing `"drawerOpenMenuTooltip": "Open menu",` line:

```json
  "drawerCreateCompany": "Add New Company",
  "createCompanyTitle": "Add New Company",
  "createCompanyNameLabel": "Company Name",
  "createCompanyBranchNameLabel": "First Branch Name",
  "createCompanyBranchAddressLabel": "Branch Address",
  "createCompanyGymAdminNameLabel": "Company Admin Full Name",
  "createCompanyGymAdminPhoneLabel": "Company Admin Phone",
  "createCompanyGymAdminEmailLabel": "Company Admin Email (optional)",
  "createCompanySubmitButton": "Create Company",
  "createCompanySuccessMessage": "Company created. The admin can set their password via 'Forgot Password' using their phone number.",
```

- [ ] **Step 2: Write the screen**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/real_tenant_repository.dart';

class CreateCompanyScreen extends ConsumerStatefulWidget {
  const CreateCompanyScreen({super.key});

  @override
  ConsumerState<CreateCompanyScreen> createState() => _CreateCompanyScreenState();
}

class _CreateCompanyScreenState extends ConsumerState<CreateCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _branchNameController = TextEditingController();
  final _branchAddressController = TextEditingController();
  final _gymAdminNameController = TextEditingController();
  final _gymAdminEmailController = TextEditingController();
  String? _gymAdminPhone;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _companyNameController.dispose();
    _branchNameController.dispose();
    _branchAddressController.dispose();
    _gymAdminNameController.dispose();
    _gymAdminEmailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_gymAdminPhone == null || _gymAdminPhone!.trim().isEmpty) {
      setState(() => _errorText = l10n.commonFieldRequired);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      await ref.read(tenantRepositoryProvider).createCompany(
            companyName: _companyNameController.text.trim(),
            branchName: _branchNameController.text.trim(),
            branchAddress: _branchAddressController.text.trim(),
            gymAdminFullName: _gymAdminNameController.text.trim(),
            gymAdminPhone: _gymAdminPhone!,
            gymAdminEmail: _gymAdminEmailController.text.trim().isEmpty
                ? null
                : _gymAdminEmailController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.createCompanySuccessMessage)));
      Navigator.of(context).pop();
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() => _errorText = exception.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createCompanyTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _companyNameController,
                  decoration: InputDecoration(labelText: l10n.createCompanyNameLabel),
                  validator: (value) => (value == null || value.trim().isEmpty) ? l10n.commonFieldRequired : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _branchNameController,
                  decoration: InputDecoration(labelText: l10n.createCompanyBranchNameLabel),
                  validator: (value) => (value == null || value.trim().isEmpty) ? l10n.commonFieldRequired : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _branchAddressController,
                  decoration: InputDecoration(labelText: l10n.createCompanyBranchAddressLabel),
                  validator: (value) => (value == null || value.trim().isEmpty) ? l10n.commonFieldRequired : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _gymAdminNameController,
                  decoration: InputDecoration(labelText: l10n.createCompanyGymAdminNameLabel),
                  validator: (value) => (value == null || value.trim().isEmpty) ? l10n.commonFieldRequired : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                IntlPhoneField(
                  initialCountryCode: 'TR',
                  decoration: InputDecoration(labelText: l10n.createCompanyGymAdminPhoneLabel),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (phone) => _gymAdminPhone = phone.completeNumber,
                  validator: (phone) => (phone == null || phone.number.trim().isEmpty) ? l10n.commonFieldRequired : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _gymAdminEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: l10n.createCompanyGymAdminEmailLabel),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(_errorText!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.error)),
                ],
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                        )
                      : Text(l10n.createCompanySubmitButton),
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

- [ ] **Step 3: Add the route**

In `lib/core/router/app_router.dart`, add the import:

```dart
import '../../features/tenant_onboarding/presentation/screens/create_company_screen.dart';
```

and a new top-level `GoRoute` (alongside the existing `/notifications` one, inside the authenticated area so it's *not* added to `_publicRoutes`):

```dart
      GoRoute(
        path: '/admin/create-company',
        builder: (context, state) => const CreateCompanyScreen(),
      ),
```

- [ ] **Step 4: Run static analysis**

Run: `flutter gen-l10n && flutter analyze`
Expected: `No issues found!`

- [x] **Step 5: Commit** — done jointly with Task 4 in commit `8dc4fc6` (both routes wired in the same `app_router.dart` pass). **Partly superseded**: per user feedback, this screen is no longer reached directly from the drawer — see "PLAN COMPLETE" note above, item 1 (Company Management screen).

```bash
git add lib/features/tenant_onboarding/presentation/screens/create_company_screen.dart lib/core/router/app_router.dart lib/l10n/app_tr.arb lib/l10n/app_en.arb
git commit -m "Add Create Company screen and route"
```

---

### Task 4: "Üye/Antrenör Ekle" screen (Gym Admin / Branch Manager)

**Files:**
- Create: `lib/features/tenant_onboarding/presentation/screens/add_staff_member_screen.dart`
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/l10n/app_tr.arb`, `lib/l10n/app_en.arb`

A Branch Manager's own `staffAssignment.branchId` is always set (they're scoped to exactly one branch) — the branch field is a fixed, disabled text, no picker. A Gym Admin's own `staffAssignment.branchId` is `null` (they oversee every branch of their company) — they get a `DropdownButtonFormField<BranchOption>` populated via `TenantRepository.listBranches()`.

- [ ] **Step 1: Add l10n keys**

In `lib/l10n/app_tr.arb`, right after the `createCompanySuccessMessage` key added in Task 3:

```json
  "drawerAddStaffMember": "Üye/Antrenör Ekle",
  "@drawerAddStaffMember": {},
  "addStaffMemberTitle": "Üye/Antrenör Ekle",
  "@addStaffMemberTitle": {},
  "addStaffMemberNameLabel": "Ad Soyad",
  "@addStaffMemberNameLabel": {},
  "addStaffMemberPhoneLabel": "Telefon",
  "@addStaffMemberPhoneLabel": {},
  "addStaffMemberEmailLabel": "E-posta (opsiyonel)",
  "@addStaffMemberEmailLabel": {},
  "addStaffMemberRoleLabel": "Rol",
  "@addStaffMemberRoleLabel": {},
  "addStaffMemberRoleMember": "Üye",
  "@addStaffMemberRoleMember": {},
  "addStaffMemberRoleTrainer": "Antrenör",
  "@addStaffMemberRoleTrainer": {},
  "addStaffMemberBranchLabel": "Şube",
  "@addStaffMemberBranchLabel": {},
  "addStaffMemberSubmitButton": "Ekle",
  "@addStaffMemberSubmitButton": {},
  "addStaffMemberSuccessMessage": "Eklendi. Kişi, telefonuyla 'Şifremi Unuttum' akışını kullanarak şifresini belirleyebilir.",
  "@addStaffMemberSuccessMessage": {},
```

In `lib/l10n/app_en.arb`, right after the `createCompanySuccessMessage` key added in Task 3:

```json
  "drawerAddStaffMember": "Add Member/Trainer",
  "addStaffMemberTitle": "Add Member/Trainer",
  "addStaffMemberNameLabel": "Full Name",
  "addStaffMemberPhoneLabel": "Phone",
  "addStaffMemberEmailLabel": "Email (optional)",
  "addStaffMemberRoleLabel": "Role",
  "addStaffMemberRoleMember": "Member",
  "addStaffMemberRoleTrainer": "Trainer",
  "addStaffMemberBranchLabel": "Branch",
  "addStaffMemberSubmitButton": "Add",
  "addStaffMemberSuccessMessage": "Added. They can set their password via 'Forgot Password' using their phone number.",
```

- [ ] **Step 2: Write the screen**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/real_tenant_repository.dart';
import '../../domain/branch_option.dart';

class AddStaffMemberScreen extends ConsumerStatefulWidget {
  const AddStaffMemberScreen({super.key});

  @override
  ConsumerState<AddStaffMemberScreen> createState() => _AddStaffMemberScreenState();
}

class _AddStaffMemberScreenState extends ConsumerState<AddStaffMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _phone;
  String _role = 'Member';
  int? _selectedBranchId;
  bool _isSubmitting = false;
  String? _errorText;
  List<BranchOption>? _branchOptions;
  bool _isLoadingBranches = false;

  @override
  void initState() {
    super.initState();
    // A Branch Manager's own branch is fixed; a Gym Admin (branchId == null
    // on their own assignment) picks from their company's branches.
    final myAssignment = ref.read(currentUserProvider).asData?.value?.staffAssignment;
    if (myAssignment?.branchId != null) {
      _selectedBranchId = myAssignment!.branchId;
    } else {
      _loadBranches();
    }
  }

  Future<void> _loadBranches() async {
    setState(() => _isLoadingBranches = true);
    try {
      final branches = await ref.read(tenantRepositoryProvider).listBranches();
      if (!mounted) return;
      setState(() {
        _branchOptions = branches;
        _selectedBranchId = branches.isNotEmpty ? branches.first.id : null;
      });
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() => _errorText = exception.message);
    } finally {
      if (mounted) setState(() => _isLoadingBranches = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_phone == null || _phone!.trim().isEmpty || _selectedBranchId == null) {
      setState(() => _errorText = l10n.commonFieldRequired);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      await ref.read(tenantRepositoryProvider).addStaffMember(
            fullName: _nameController.text.trim(),
            phone: _phone!,
            email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
            role: _role,
            branchId: _selectedBranchId!,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.addStaffMemberSuccessMessage)));
      Navigator.of(context).pop();
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() => _errorText = exception.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final myAssignment = ref.watch(currentUserProvider).asData?.value?.staffAssignment;
    final fixedBranchId = myAssignment?.branchId;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addStaffMemberTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: l10n.addStaffMemberNameLabel),
                  validator: (value) => (value == null || value.trim().isEmpty) ? l10n.commonFieldRequired : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                IntlPhoneField(
                  initialCountryCode: 'TR',
                  decoration: InputDecoration(labelText: l10n.addStaffMemberPhoneLabel),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (phone) => _phone = phone.completeNumber,
                  validator: (phone) => (phone == null || phone.number.trim().isEmpty) ? l10n.commonFieldRequired : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: l10n.addStaffMemberEmailLabel),
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: InputDecoration(labelText: l10n.addStaffMemberRoleLabel),
                  items: [
                    DropdownMenuItem(value: 'Member', child: Text(l10n.addStaffMemberRoleMember)),
                    DropdownMenuItem(value: 'Trainer', child: Text(l10n.addStaffMemberRoleTrainer)),
                  ],
                  onChanged: (value) => setState(() => _role = value!),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (fixedBranchId != null)
                  TextFormField(
                    enabled: false,
                    initialValue: myAssignment?.companyName ?? l10n.addStaffMemberBranchLabel,
                    decoration: InputDecoration(labelText: l10n.addStaffMemberBranchLabel),
                  )
                else if (_isLoadingBranches)
                  const Center(child: CircularProgressIndicator(color: AppColors.primary))
                else
                  DropdownButtonFormField<int>(
                    initialValue: _selectedBranchId,
                    decoration: InputDecoration(labelText: l10n.addStaffMemberBranchLabel),
                    items: (_branchOptions ?? const <BranchOption>[])
                        .map((branch) => DropdownMenuItem(value: branch.id, child: Text(branch.name)))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedBranchId = value),
                  ),
                if (_errorText != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(_errorText!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.error)),
                ],
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                        )
                      : Text(l10n.addStaffMemberSubmitButton),
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

- [ ] **Step 3: Add the route**

In `lib/core/router/app_router.dart`, add the import:

```dart
import '../../features/tenant_onboarding/presentation/screens/add_staff_member_screen.dart';
```

and the route, alongside the one added in Task 3:

```dart
      GoRoute(
        path: '/admin/add-staff-member',
        builder: (context, state) => const AddStaffMemberScreen(),
      ),
```

- [ ] **Step 4: Run static analysis**

Run: `flutter gen-l10n && flutter analyze`
Expected: `No issues found!`

- [x] **Step 5: Commit** — done, commit `8dc4fc6`.

```bash
git add lib/features/tenant_onboarding/presentation/screens/add_staff_member_screen.dart lib/core/router/app_router.dart lib/l10n/app_tr.arb lib/l10n/app_en.arb
git commit -m "Add Add Staff Member screen and route"
```

---

### Task 5: Surface both screens in `AppDrawer`, conditionally by role

**Files:**
- Modify: `lib/core/widgets/app_drawer.dart`

- [ ] **Step 1: Add the imports**

```dart
import 'package:go_router/go_router.dart';
```

(likely already needed elsewhere in the file — check before duplicating.)

- [ ] **Step 2: Add the two conditional items**

In `AppDrawer.build`, after reading `currentUser` and before the closing `Divider`+Logout section, add a `closeThenPush` helper (same shape as the existing `closeThenRun`) and the two new items, gated on the role helpers from Task 1:

```dart
    void closeThenPush(String location) {
      Navigator.pop(context);
      context.push(location);
    }
```

Then, inside the `ListView`'s `children`, right after the Language/Freeze/Delete items and before the trailing empty state:

```dart
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
```

- [ ] **Step 3: Run static analysis and the existing drawer-adjacent tests**

Run: `flutter analyze && flutter test`
Expected: `No issues found!`, full suite still green (no drawer widget test exists today to update — this is additive UI).

- [x] **Step 4: Commit** — done, commit `3486031`. Later reordered (commit `7d4fb05`) per user feedback: the admin items (now "Firma Yönetimi") sit above a divider, ahead of Dil/Dondur/Sil, not interleaved with them.

```bash
git add lib/core/widgets/app_drawer.dart
git commit -m "Show Create Company / Add Staff Member in the drawer, based on the caller's real role"
```

---

### Task 6: Retire self-service registration

**Files:**
- Delete: `lib/features/auth/presentation/screens/register_screen.dart`
- Modify: `lib/features/auth/domain/auth_repository.dart`
- Modify: `lib/features/auth/data/real_auth_repository.dart`
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/features/auth/presentation/screens/login_screen.dart`
- Modify: `lib/l10n/app_tr.arb`, `lib/l10n/app_en.arb`

**Do this task LAST, only after the two new screens (Tasks 3–4) are confirmed working against a real backend that already has Tasks 6–9 of the backend plan deployed** — this is the only way left afterward to create a brand-new account chain (Super Admin → Company → Gym Admin → staff → Member/Trainer). Do **not** delete the backend's register endpoints (that plan's own Task 11) until this task has already shipped.

- [ ] **Step 1: Delete the screen**

```bash
git rm lib/features/auth/presentation/screens/register_screen.dart
```

- [ ] **Step 2: Remove the two methods from `AuthRepository` and `RealAuthRepository`**

Remove from `lib/features/auth/domain/auth_repository.dart`:

```dart
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
```

Remove the matching two `@override` implementations from `lib/features/auth/data/real_auth_repository.dart` (`requestRegistrationOtp`, `completeRegistration`).

- [ ] **Step 3: Remove the route and the public-route entry**

In `lib/core/router/app_router.dart`, remove the `RegisterScreen` import, the `/register` `GoRoute`, and `'/register'` from `_publicRoutes` (leaving `{'/login', '/forgot-password'}`).

- [ ] **Step 4: Remove the sign-up link from `LoginScreen`**

Remove the `TextButton(onPressed: () => context.push('/register'), child: Text(l10n.loginNoAccount))` (or equivalent) from `lib/features/auth/presentation/screens/login_screen.dart`.

- [ ] **Step 5: Remove now-unused l10n keys**

Remove every `register*`/`@register*` key from both `lib/l10n/app_tr.arb` and `lib/l10n/app_en.arb`: `registerTitle`, `registerFullNameLabel`, `registerPhoneLabel`, `registerEmailLabel`, `registerEmailInvalid`, `registerPasswordLabel`, `registerSubmitButton`, `registerHaveAccount`, `registerPasswordTooShort`, `registerConfirmPasswordLabel`, `registerPasswordMismatch`, `registerSendCodeButton`, `registerCodeSentPhoneOnlyMessage`, `registerCodeSentBothMessage`, `registerPhoneCodeLabel`, `registerEmailCodeLabel`, `registerChangeDetails`. Also remove `loginNoAccount` (only used by the link removed in Step 4).

- [ ] **Step 6: Regenerate and verify**

Run: `flutter gen-l10n && flutter analyze && flutter test`
Expected: `No issues found!`, full suite green — a red here almost certainly means a leftover reference to a removed l10n key or the removed methods; grep for it before assuming anything else.

- [x] **Step 7: Commit** — done, commit `3034443`. Also cleaned up two things the plan didn't anticipate: `registerPasswordTooShort` was reused by `forgot_password_screen.dart` (renamed to `commonPasswordTooShort` and kept, not deleted), and a stale pre-OTP-rework `/api/auth/register` entry in `dio_client.dart`'s `_noAuthPaths` (removed).

```bash
git add -A
git commit -m "Retire self-service registration - accounts are now staff-created"
```

---

## Self-review notes (from writing this plan)

- **Spec coverage:** Super Admin's "Yeni Firma Ekle" mobile screen → Task 3. Staff's "add Member/Trainer" mobile screen → Task 4. Role-aware entry points (only the relevant role sees each screen) → Task 5, backed by Task 1's real role data. Retiring self-servis kayıt on mobile → Task 6.
- **Explicitly out of scope, flagged rather than silently dropped:** a "Şirket/Şube Seç" context-switcher UI for a user with more than one Assignment (mirrors the same deferral in the backend plan's `TenantResolutionService`) — not needed yet since nothing in either plan lets a normal Member/Trainer end up with two assignments, only staff-creation flows which are inherently single-company per action.
- **Placeholder scan:** every screen step above has complete, real widget code; every repository step has a complete implementation; no "TODO"/"handle errors appropriately" left anywhere.
