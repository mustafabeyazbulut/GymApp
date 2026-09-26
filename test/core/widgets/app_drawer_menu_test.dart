import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/providers/active_staff_company_provider.dart';
import 'package:gym_app/core/widgets/app_drawer.dart';
import 'package:gym_app/features/auth/data/real_auth_repository.dart';
import 'package:gym_app/features/auth/domain/auth_repository.dart';
import 'package:gym_app/features/auth/domain/me_result.dart';
import 'package:gym_app/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

const _gymAdminA = MeAssignment(companyId: 1, companyName: 'A', branchId: null, role: 'GymAdmin');
const _branchManagerB = MeAssignment(companyId: 2, companyName: 'B', branchId: 9, role: 'BranchManager');
const _superAdmin = MeAssignment(companyId: null, companyName: null, branchId: null, role: 'SuperAdmin');

final _l10n = lookupAppLocalizations(const Locale('tr'));

Future<void> _pumpOpenDrawer(
  WidgetTester tester, {
  required List<MeAssignment> assignments,
  int? activeCompanyId,
}) async {
  // Çekmece bir ListView - tüm satırların test sırasında gerçekten
  // oluşturulması için yüzeyi uzatıyoruz.
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final repository = _MockAuthRepository();
  when(() => repository.getMe()).thenAnswer((_) async => MeResult(
        id: 1,
        fullName: 'Test User',
        phone: '+905551112233',
        email: null,
        preferredLanguage: 'tr',
        isAccountFrozen: false,
        assignments: assignments,
        packageAssignments: const [],
      ));

  final container = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(repository)]);
  addTearDown(container.dispose);
  if (activeCompanyId != null) {
    // autoDispose provider - dinleyici olmadan seçim hemen sıfırlanırdı.
    container.listen(activeStaffCompanyIdProvider, (_, _) {});
    container.read(activeStaffCompanyIdProvider.notifier).select(activeCompanyId);
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            appBar: AppBar(
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),
            drawer: const AppDrawer(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
}

List<String> get _gymOperationLabels => [
      _l10n.drawerBranchManagement,
      _l10n.drawerAddStaffMember,
      _l10n.drawerStaffManagement,
      _l10n.drawerPackageManagement,
      _l10n.drawerCreateClassSession,
      _l10n.drawerDoorAccess,
      _l10n.drawerAnalytics,
      _l10n.drawerReports,
    ];

void main() {
  testWidgets('GymAdmin tüm personel menülerini görür, firma yönetimini görmez', (tester) async {
    await _pumpOpenDrawer(tester, assignments: [_gymAdminA]);

    for (final label in _gymOperationLabels) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text(_l10n.drawerCompanyManagement), findsNothing);
  });

  testWidgets('BranchManager kapı erişimini görmez, diğer personel menülerini görür', (tester) async {
    await _pumpOpenDrawer(tester, assignments: [_branchManagerB]);

    expect(find.text(_l10n.drawerDoorAccess), findsNothing);
    for (final label in _gymOperationLabels.where((l) => l != _l10n.drawerDoorAccess)) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('personel ataması olmayan SuperAdmin sadece firma yönetimini görür', (tester) async {
    await _pumpOpenDrawer(tester, assignments: [_superAdmin]);

    expect(find.text(_l10n.drawerCompanyManagement), findsOneWidget);
    for (final label in _gymOperationLabels) {
      expect(find.text(label), findsNothing, reason: label);
    }
  });

  testWidgets('rolsüz üye hiçbir personel menüsünü görmez ama herkese açık girişleri görür', (tester) async {
    await _pumpOpenDrawer(tester, assignments: const []);

    expect(find.text(_l10n.drawerCompanyManagement), findsNothing);
    for (final label in _gymOperationLabels) {
      expect(find.text(label), findsNothing, reason: label);
    }
    expect(find.text(_l10n.drawerConfirmInvitation), findsOneWidget);
    expect(find.text(_l10n.drawerContentLibrary), findsOneWidget);
  });

  testWidgets('menü aktif firmadaki role göre değişir', (tester) async {
    await _pumpOpenDrawer(tester, assignments: [_gymAdminA, _branchManagerB], activeCompanyId: 2);

    // Aktif firma B (BranchManager) - A'daki GymAdmin'lik kapı erişimini açmamalı.
    expect(find.text(_l10n.drawerDoorAccess), findsNothing);
    expect(find.text(_l10n.drawerPackageManagement), findsOneWidget);
  });
}
