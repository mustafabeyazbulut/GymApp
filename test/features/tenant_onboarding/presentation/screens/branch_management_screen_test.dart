import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/auth/data/real_auth_repository.dart';
import 'package:gym_app/features/auth/domain/auth_repository.dart';
import 'package:gym_app/features/auth/domain/me_result.dart';
import 'package:gym_app/features/auth/presentation/providers/current_user_provider.dart';
import 'package:gym_app/features/tenant_onboarding/data/real_tenant_repository.dart';
import 'package:gym_app/features/tenant_onboarding/domain/branch_summary.dart';
import 'package:gym_app/features/tenant_onboarding/domain/tenant_repository.dart';
import 'package:gym_app/features/tenant_onboarding/presentation/screens/branch_management_screen.dart';
import 'package:gym_app/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockTenantRepository extends Mock implements TenantRepository {}

const _gymAdmin = MeAssignment(companyId: 1, companyName: 'A', branchId: null, role: 'GymAdmin');
const _branchManager = MeAssignment(companyId: 1, companyName: 'A', branchId: 9, role: 'BranchManager');

const _branches = [
  BranchSummary(id: 3, companyId: 1, name: 'Kadıköy', address: 'Adres 1', isActive: true),
  BranchSummary(id: 9, companyId: 1, name: 'Beşiktaş', address: 'Adres 2', isActive: true),
];

final _l10n = lookupAppLocalizations(const Locale('tr'));

Future<void> _pumpScreen(WidgetTester tester, MeAssignment assignment) async {
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
  // Backend şu an BranchManager'a da firmanın tüm şubelerini dönebiliyor -
  // ekranın savunma katmanı bunu kendi tarafında filtrelemeli.
  when(() => tenantRepository.getManagedBranches()).thenAnswer((_) async => _branches);

  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(authRepository),
    tenantRepositoryProvider.overrideWithValue(tenantRepository),
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
        home: const BranchManagementScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('GymAdmin firmanın tüm şubelerini görür ve şube ekleyebilir', (tester) async {
    await _pumpScreen(tester, _gymAdmin);

    expect(find.text('Kadıköy'), findsOneWidget);
    expect(find.text('Beşiktaş'), findsOneWidget);
    expect(find.byTooltip(_l10n.branchManagementAddButton), findsOneWidget);
  });

  testWidgets('BranchManager sadece atandığı şubeyi salt-okunur görür', (tester) async {
    await _pumpScreen(tester, _branchManager);

    expect(find.text('Beşiktaş'), findsOneWidget);
    expect(find.text('Kadıköy'), findsNothing);
    expect(find.byTooltip(_l10n.branchManagementAddButton), findsNothing);
    expect(find.byTooltip(_l10n.branchDeactivateButton), findsNothing);
  });
}
