import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/providers/active_staff_assignment_provider.dart';
import 'package:gym_app/features/auth/data/real_auth_repository.dart';
import 'package:gym_app/features/auth/domain/auth_repository.dart';
import 'package:gym_app/features/auth/domain/me_result.dart';
import 'package:gym_app/features/auth/presentation/providers/current_user_provider.dart';
import 'package:gym_app/features/package_management/data/real_package_repository.dart';
import 'package:gym_app/features/package_management/domain/package_repository.dart';
import 'package:gym_app/features/package_management/presentation/screens/create_package_screen.dart';
import 'package:gym_app/features/tenant_onboarding/data/real_tenant_repository.dart';
import 'package:gym_app/features/tenant_onboarding/domain/branch_option.dart';
import 'package:gym_app/features/tenant_onboarding/domain/tenant_repository.dart';
import 'package:gym_app/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockTenantRepository extends Mock implements TenantRepository {}

class _MockPackageRepository extends Mock implements PackageRepository {}

class _MemoryStore implements ActiveAssignmentStore {
  @override
  Future<int?> read() async => null;

  @override
  Future<void> write(int? assignmentId) async {}
}

const _gymAdmin = MeAssignment(id: 1, companyId: 3, companyName: 'Test Gym', branchId: null, role: 'GymAdmin');
const _branchManager = MeAssignment(
  id: 2,
  companyId: 3,
  companyName: 'Test Gym',
  branchId: 9,
  branchName: 'Kadıköy',
  role: 'BranchManager',
);

final _l10n = lookupAppLocalizations(const Locale('tr'));

Future<_MockPackageRepository> _pumpScreen(WidgetTester tester, MeAssignment assignment) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final authRepository = _MockAuthRepository();
  when(() => authRepository.getMe()).thenAnswer((_) async => MeResult(
        id: 1,
        fullName: 'Test User',
        phone: '+905551112233',
        email: null,
        preferredLanguage: 'tr',
        isAccountFrozen: false,
        assignments: [assignment],
        packageAssignments: const [],
      ));
  final tenantRepository = _MockTenantRepository();
  when(() => tenantRepository.listBranches()).thenAnswer(
    (_) async => const [BranchOption(id: 9, name: 'Kadıköy'), BranchOption(id: 10, name: 'Beşiktaş')],
  );
  final packageRepository = _MockPackageRepository();
  when(() => packageRepository.getPackages()).thenAnswer((_) async => const []);
  when(() => packageRepository.createPackage(
        companyId: any(named: 'companyId'),
        branchId: any(named: 'branchId'),
        name: any(named: 'name'),
        description: any(named: 'description'),
        type: any(named: 'type'),
        durationDays: any(named: 'durationDays'),
        sessionCount: any(named: 'sessionCount'),
        price: any(named: 'price'),
        maxFreezeDays: any(named: 'maxFreezeDays'),
      )).thenAnswer((_) async {});

  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(authRepository),
    tenantRepositoryProvider.overrideWithValue(tenantRepository),
    packageRepositoryProvider.overrideWithValue(packageRepository),
    activeAssignmentStoreProvider.overrideWithValue(_MemoryStore()),
  ]);
  addTearDown(container.dispose);
  container.listen(currentUserProvider, (_, _) {});
  await container.read(currentUserProvider.future);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CreatePackageScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return packageRepository;
}

Future<void> _fillRequiredFields(WidgetTester tester) async {
  await tester.enterText(find.widgetWithText(TextFormField, _l10n.createPackageNameLabel), 'Aylık');
  await tester.enterText(find.widgetWithText(TextFormField, _l10n.createPackageDurationDaysLabel), '30');
  await tester.enterText(find.widgetWithText(TextFormField, _l10n.createPackagePriceLabel), '1000');
}

Future<void> _submit(WidgetTester tester) async {
  final button = find.widgetWithText(ElevatedButton, _l10n.createPackageSubmitButton);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  // Firma geneli (şubesiz) paket yoktur - ana senaryo Karar 5.
  testWidgets('GymAdmin şube listesinde "Tüm şubeler" seçeneği yok, varsayılan seçim yok', (tester) async {
    await _pumpScreen(tester, _gymAdmin);

    expect(find.text(_l10n.createPackageAllBranchesOption), findsNothing);
    expect(find.text('Kadıköy'), findsNothing);

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    expect(find.text('Kadıköy'), findsWidgets);
    expect(find.text('Beşiktaş'), findsWidgets);
    expect(find.text(_l10n.createPackageAllBranchesOption), findsNothing);
  });

  testWidgets('GymAdmin şube seçmeden kaydedemez', (tester) async {
    final repository = await _pumpScreen(tester, _gymAdmin);
    await _fillRequiredFields(tester);

    await _submit(tester);

    expect(find.text(_l10n.createPackageBranchRequired), findsOneWidget);
    verifyNever(() => repository.createPackage(
          companyId: any(named: 'companyId'),
          branchId: any(named: 'branchId'),
          name: any(named: 'name'),
          description: any(named: 'description'),
          type: any(named: 'type'),
          durationDays: any(named: 'durationDays'),
          sessionCount: any(named: 'sessionCount'),
          price: any(named: 'price'),
          maxFreezeDays: any(named: 'maxFreezeDays'),
        ));
  });

  testWidgets('GymAdmin seçtiği şubeye paket oluşturur', (tester) async {
    final repository = await _pumpScreen(tester, _gymAdmin);
    await _fillRequiredFields(tester);
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beşiktaş').last);
    await tester.pumpAndSettle();

    await _submit(tester);

    verify(() => repository.createPackage(
          companyId: 3,
          branchId: 10,
          name: 'Aylık',
          description: null,
          type: 'Duration',
          durationDays: 30,
          sessionCount: null,
          price: 1000,
          maxFreezeDays: null,
        )).called(1);
  });

  testWidgets('BranchManager\'da şube kilitli, kendi şubesine oluşturur', (tester) async {
    final repository = await _pumpScreen(tester, _branchManager);
    expect(find.widgetWithText(TextFormField, 'Kadıköy'), findsOneWidget);
    await _fillRequiredFields(tester);

    await _submit(tester);

    verify(() => repository.createPackage(
          companyId: 3,
          branchId: 9,
          name: 'Aylık',
          description: null,
          type: 'Duration',
          durationDays: 30,
          sessionCount: null,
          price: 1000,
          maxFreezeDays: null,
        )).called(1);
  });
}
