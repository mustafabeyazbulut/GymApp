import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/providers/active_staff_assignment_provider.dart';
import 'package:gym_app/features/auth/data/real_auth_repository.dart';
import 'package:gym_app/features/auth/domain/auth_repository.dart';
import 'package:gym_app/features/auth/domain/me_result.dart';
import 'package:gym_app/features/auth/presentation/providers/current_user_provider.dart';
import 'package:gym_app/features/tenant_onboarding/data/real_tenant_repository.dart';
import 'package:gym_app/features/tenant_onboarding/domain/branch_option.dart';
import 'package:gym_app/features/tenant_onboarding/domain/tenant_repository.dart';
import 'package:gym_app/features/tenant_onboarding/presentation/screens/add_staff_member_screen.dart';
import 'package:gym_app/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockTenantRepository extends Mock implements TenantRepository {}

const _gymAdmin = MeAssignment(companyId: 1, companyName: 'A', branchId: null, role: 'GymAdmin');
const _branchManager = MeAssignment(companyId: 1, companyName: 'A', branchId: 9, role: 'BranchManager');

final _l10n = lookupAppLocalizations(const Locale('tr'));

class _MemoryStore implements ActiveAssignmentStore {
  @override
  Future<int?> read() async => null;

  @override
  Future<void> write(int? assignmentId) async {}
}

Future<_MockTenantRepository> _pumpScreen(
  WidgetTester tester,
  MeAssignment assignment, {
  List<MeAssignment> otherAssignments = const [],
  int? selectedAssignmentId,
}) async {
  final authRepository = _MockAuthRepository();
  when(() => authRepository.getMe()).thenAnswer((_) async => MeResult(
        id: 1,
        fullName: 'Test User',
        phone: '+905551112233',
        email: null,
        preferredLanguage: 'tr',
        isAccountFrozen: false,
        assignments: [assignment, ...otherAssignments],
        packageAssignments: const [],
      ));
  final tenantRepository = _MockTenantRepository();
  when(() => tenantRepository.listBranches())
      .thenAnswer((_) async => const [BranchOption(id: 9, name: 'Kadıköy')]);

  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(authRepository),
    tenantRepositoryProvider.overrideWithValue(tenantRepository),
    activeAssignmentStoreProvider.overrideWithValue(_MemoryStore()),
  ]);
  addTearDown(container.dispose);
  // Ekran currentUserProvider'ı initState'te senkron okuyor - uygulamada
  // bu noktada zaten yüklenmiş oluyor.
  container.listen(currentUserProvider, (_, _) {});
  await container.read(currentUserProvider.future);
  if (selectedAssignmentId != null) {
    container.read(activeStaffAssignmentProvider.notifier).select(selectedAssignmentId);
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AddStaffMemberScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tenantRepository;
}

void main() {
  // Önceden kilitli alanda firma adı görünüyordu.
  testWidgets('BranchManager\'ın kilitli şube alanı aktif görevin şube adını gösterir', (tester) async {
    const kadikoy = MeAssignment(
      id: 2,
      companyId: 1,
      companyName: 'Test Gym',
      branchId: 9,
      branchName: 'Kadıköy',
      role: 'BranchManager',
    );
    const besiktas = MeAssignment(
      id: 3,
      companyId: 1,
      companyName: 'Test Gym',
      branchId: 10,
      branchName: 'Beşiktaş',
      role: 'BranchManager',
    );

    final tenantRepository =
        await _pumpScreen(tester, kadikoy, otherAssignments: [besiktas], selectedAssignmentId: besiktas.id);

    expect(find.widgetWithText(TextFormField, 'Beşiktaş'), findsOneWidget);
    expect(find.text('Test Gym'), findsNothing);
    expect(find.text('Kadıköy'), findsNothing);
    verifyNever(() => tenantRepository.listBranches());
  });

  testWidgets('başlık Personel Ekle, varsayılan rol Antrenör ve Üye seçeneği yok', (tester) async {
    await _pumpScreen(tester, _gymAdmin);

    expect(find.text(_l10n.addStaffMemberTitle), findsOneWidget);
    expect(find.text(_l10n.addStaffMemberRoleTrainer), findsOneWidget);

    await tester.tap(find.text(_l10n.addStaffMemberRoleTrainer));
    await tester.pumpAndSettle();

    expect(find.text('Üye'), findsNothing);
  });

  testWidgets('GymAdmin, Antrenör ve Şube Müdürü rollerini seçebilir', (tester) async {
    await _pumpScreen(tester, _gymAdmin);

    await tester.tap(find.text(_l10n.addStaffMemberRoleTrainer));
    await tester.pumpAndSettle();

    expect(find.text(_l10n.addStaffMemberRoleBranchManager), findsOneWidget);
  });

  testWidgets('BranchManager sadece Antrenör ekleyebilir', (tester) async {
    await _pumpScreen(tester, _branchManager);

    await tester.tap(find.text(_l10n.addStaffMemberRoleTrainer));
    await tester.pumpAndSettle();

    expect(find.text(_l10n.addStaffMemberRoleBranchManager), findsNothing);
  });
}
