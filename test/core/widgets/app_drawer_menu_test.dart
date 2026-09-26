import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/providers/active_staff_assignment_provider.dart';
import 'package:gym_app/core/widgets/app_drawer.dart';
import 'package:gym_app/features/auth/data/real_auth_repository.dart';
import 'package:gym_app/features/auth/domain/auth_repository.dart';
import 'package:gym_app/features/auth/domain/me_result.dart';
import 'package:gym_app/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MemoryStore implements ActiveAssignmentStore {
  _MemoryStore([this.stored]);

  int? stored;

  @override
  Future<int?> read() async => stored;

  @override
  Future<void> write(int? assignmentId) async => stored = assignmentId;
}

const _gymAdminA = MeAssignment(id: 1, companyId: 1, companyName: 'A', branchId: null, role: 'GymAdmin');
const _branchManagerB = MeAssignment(
  id: 2,
  companyId: 2,
  companyName: 'B',
  branchId: 9,
  branchName: 'Kadıköy',
  role: 'BranchManager',
);
const _superAdmin = MeAssignment(id: 3, companyId: null, companyName: null, branchId: null, role: 'SuperAdmin');
const _trainerB = MeAssignment(
  id: 4,
  companyId: 2,
  companyName: 'B',
  branchId: 10,
  branchName: 'Beşiktaş',
  role: 'Trainer',
);

final _l10n = lookupAppLocalizations(const Locale('tr'));

Future<ProviderContainer> _pumpOpenDrawer(
  WidgetTester tester, {
  required List<MeAssignment> assignments,
  int? storedSelection,
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

  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(repository),
    activeAssignmentStoreProvider.overrideWithValue(_MemoryStore(storedSelection)),
  ]);
  addTearDown(container.dispose);

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
  return container;
}

Future<void> _selectTask(WidgetTester tester, String label) async {
  await tester.tap(find.text(_l10n.drawerActiveTaskLabel));
  await tester.pumpAndSettle();
  await tester.tap(find.descendant(of: find.byType(SimpleDialog), matching: find.text(label)));
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

void _expectNoGymOperations() {
  for (final label in _gymOperationLabels) {
    expect(find.text(label), findsNothing, reason: label);
  }
}

String get _trainerLabel => 'B · Beşiktaş · ${_l10n.staffManagementRoleTrainer}';
String get _branchManagerLabel => 'B · Kadıköy · ${_l10n.staffManagementRoleBranchManager}';
String get _gymAdminLabel => 'A · ${_l10n.drawerActiveTaskCompanyWide} · ${_l10n.staffManagementRoleGymAdmin}';

void main() {
  testWidgets('GymAdmin tüm personel menülerini görür, firma yönetimini ve seçiciyi görmez', (tester) async {
    await _pumpOpenDrawer(tester, assignments: [_gymAdminA]);

    for (final label in _gymOperationLabels) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text(_l10n.drawerCompanyManagement), findsNothing);
    expect(find.text(_l10n.drawerTrainerSchedule), findsNothing);
    expect(find.text(_l10n.drawerActiveTaskLabel), findsNothing);
  });

  testWidgets('BranchManager kapı erişimini görmez, diğer personel menülerini görür', (tester) async {
    await _pumpOpenDrawer(tester, assignments: [_branchManagerB]);

    expect(find.text(_l10n.drawerDoorAccess), findsNothing);
    for (final label in _gymOperationLabels.where((l) => l != _l10n.drawerDoorAccess)) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('sadece antrenör: programını görür, yönetim menülerini görmez', (tester) async {
    await _pumpOpenDrawer(tester, assignments: [_trainerB]);

    expect(find.text(_l10n.drawerTrainerSchedule), findsOneWidget);
    expect(find.text(_l10n.drawerActiveTaskLabel), findsNothing);
    _expectNoGymOperations();
  });

  testWidgets('personel ataması olmayan SuperAdmin sadece firma yönetimini görür, seçici yok', (tester) async {
    await _pumpOpenDrawer(tester, assignments: [_superAdmin]);

    expect(find.text(_l10n.drawerCompanyManagement), findsOneWidget);
    expect(find.text(_l10n.drawerActiveTaskLabel), findsNothing);
    _expectNoGymOperations();
  });

  testWidgets('rolsüz üye hiçbir personel menüsünü görmez ama herkese açık girişleri görür', (tester) async {
    await _pumpOpenDrawer(tester, assignments: const []);

    expect(find.text(_l10n.drawerCompanyManagement), findsNothing);
    expect(find.text(_l10n.drawerTrainerSchedule), findsNothing);
    _expectNoGymOperations();
    expect(find.text(_l10n.drawerConfirmInvitation), findsOneWidget);
    expect(find.text(_l10n.drawerContentLibrary), findsOneWidget);
  });

  group('Aktif Görev seçicisi', () {
    testWidgets('BranchManager + Trainer: tüm görevleri "Firma · Şube · Rol" olarak listeler', (tester) async {
      await _pumpOpenDrawer(tester, assignments: [_trainerB, _branchManagerB]);

      // Varsayılan BranchManager - alt başlıkta görünür.
      expect(find.text(_l10n.drawerActiveTaskLabel), findsOneWidget);
      expect(find.text(_branchManagerLabel), findsOneWidget);

      await tester.tap(find.text(_l10n.drawerActiveTaskLabel));
      await tester.pumpAndSettle();
      final dialog = find.byType(SimpleDialog);
      expect(find.descendant(of: dialog, matching: find.text(_branchManagerLabel)), findsOneWidget);
      expect(find.descendant(of: dialog, matching: find.text(_trainerLabel)), findsOneWidget);
    });

    testWidgets('Trainer seçilince menü antrenöre, BranchManager seçilince yönetime döner', (tester) async {
      final container = await _pumpOpenDrawer(tester, assignments: [_trainerB, _branchManagerB]);

      expect(find.text(_l10n.drawerPackageManagement), findsOneWidget);
      expect(find.text(_l10n.drawerTrainerSchedule), findsNothing);

      await _selectTask(tester, _trainerLabel);
      expect(container.read(activeStaffAssignmentProvider), _trainerB.id);
      expect(find.text(_l10n.drawerTrainerSchedule), findsOneWidget);
      _expectNoGymOperations();

      await _selectTask(tester, _branchManagerLabel);
      expect(find.text(_l10n.drawerPackageManagement), findsOneWidget);
      expect(find.text(_l10n.drawerTrainerSchedule), findsNothing);
    });

    testWidgets('çok şubeli BranchManager: şube adlarıyla ayrışır, en küçük Id varsayılandır', (tester) async {
      const besiktasManager = MeAssignment(
        id: 7,
        companyId: 2,
        companyName: 'B',
        branchId: 10,
        branchName: 'Beşiktaş',
        role: 'BranchManager',
      );
      await _pumpOpenDrawer(tester, assignments: [besiktasManager, _branchManagerB]);

      expect(find.text(_branchManagerLabel), findsOneWidget);
      await _selectTask(tester, 'B · Beşiktaş · ${_l10n.staffManagementRoleBranchManager}');
      expect(find.text('B · Beşiktaş · ${_l10n.staffManagementRoleBranchManager}'), findsOneWidget);
    });

    testWidgets('GymAdmin satırında şube yerine "Firma geneli" yazar', (tester) async {
      await _pumpOpenDrawer(tester, assignments: [_gymAdminA, _branchManagerB]);

      expect(find.text(_gymAdminLabel), findsOneWidget);
    });

    testWidgets('kalıcı saklanan seçimle açılır', (tester) async {
      await _pumpOpenDrawer(tester, assignments: [_trainerB, _branchManagerB], storedSelection: _trainerB.id);

      expect(find.text(_trainerLabel), findsOneWidget);
      expect(find.text(_l10n.drawerTrainerSchedule), findsOneWidget);
    });

    testWidgets('SuperAdmin + GymAdmin: Sistem Sahibi en üstte ve varsayılan; geçişte menü değişir', (tester) async {
      final container = await _pumpOpenDrawer(tester, assignments: [_gymAdminA, _superAdmin]);

      // Varsayılan: Sistem Sahibi - sadece firma yönetimi.
      expect(find.text(_l10n.drawerActiveTaskSystemOwner), findsOneWidget);
      expect(find.text(_l10n.drawerCompanyManagement), findsOneWidget);
      _expectNoGymOperations();

      await tester.tap(find.text(_l10n.drawerActiveTaskLabel));
      await tester.pumpAndSettle();
      final options = find.descendant(of: find.byType(SimpleDialog), matching: find.byType(SimpleDialogOption));
      expect(
        find.descendant(of: options.first, matching: find.text(_l10n.drawerActiveTaskSystemOwner)),
        findsOneWidget,
      );
      await tester.tap(find.descendant(of: find.byType(SimpleDialog), matching: find.text(_gymAdminLabel)));
      await tester.pumpAndSettle();

      expect(container.read(activeStaffAssignmentProvider), _gymAdminA.id);
      expect(find.text(_l10n.drawerCompanyManagement), findsNothing);
      expect(find.text(_l10n.drawerPackageManagement), findsOneWidget);
      expect(find.text(_l10n.drawerDoorAccess), findsOneWidget);

      await _selectTask(tester, _l10n.drawerActiveTaskSystemOwner);
      expect(find.text(_l10n.drawerCompanyManagement), findsOneWidget);
      _expectNoGymOperations();
    });
  });
}
