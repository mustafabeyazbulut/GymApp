import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/providers/active_staff_assignment_provider.dart';
import 'package:gym_app/core/widgets/staff_permission_gate.dart';
import 'package:gym_app/features/auth/data/real_auth_repository.dart';
import 'package:gym_app/features/auth/domain/auth_repository.dart';
import 'package:gym_app/features/auth/domain/me_result.dart';
import 'package:gym_app/features/auth/domain/staff_permissions.dart';
import 'package:gym_app/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MemoryStore implements ActiveAssignmentStore {
  @override
  Future<int?> read() async => null;

  @override
  Future<void> write(int? assignmentId) async {}
}

const _gymAdmin = MeAssignment(id: 1, companyId: 1, companyName: 'A', branchId: null, role: 'GymAdmin');
const _branchManager = MeAssignment(id: 2, companyId: 1, companyName: 'A', branchId: 9, role: 'BranchManager');
const _trainer = MeAssignment(id: 3, companyId: 1, companyName: 'A', branchId: 9, role: 'Trainer');

final _l10n = lookupAppLocalizations(const Locale('tr'));

MeResult _me(List<MeAssignment> assignments) => MeResult(
      id: 1,
      fullName: 'Test User',
      phone: '+905551112233',
      email: null,
      preferredLanguage: 'tr',
      isAccountFrozen: false,
      assignments: assignments,
      packageAssignments: const [],
    );

Future<ProviderContainer> _pump(
  WidgetTester tester,
  Future<MeResult> Function() getMe, {
  bool Function(StaffPermissions permissions)? isAllowed,
}) async {
  final repository = _MockAuthRepository();
  when(() => repository.getMe()).thenAnswer((_) => getMe());
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(repository),
    activeAssignmentStoreProvider.overrideWithValue(_MemoryStore()),
  ]);
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StaffPermissionGate(
          isAllowed: isAllowed ?? (permissions) => permissions.canManageDoorAccess,
          child: const Text('korunan ekran'),
        ),
      ),
    ),
  );
  return container;
}

void main() {
  testWidgets('yetkisi olan kullanıcı korunan ekranı görür', (tester) async {
    await _pump(tester, () async => _me([_gymAdmin]));
    await tester.pumpAndSettle();

    expect(find.text('korunan ekran'), findsOneWidget);
    expect(find.text(_l10n.staffAccessDeniedTitle), findsNothing);
  });

  testWidgets('yetkisi olmayan kullanıcı yetkisiz durumunu görür, ekran hiç oluşturulmaz', (tester) async {
    await _pump(tester, () async => _me([_branchManager]));
    await tester.pumpAndSettle();

    expect(find.text('korunan ekran'), findsNothing);
    expect(find.text(_l10n.staffAccessDeniedTitle), findsOneWidget);
    expect(find.text(_l10n.staffAccessDeniedBody), findsOneWidget);
  });

  testWidgets('kullanıcı yüklenirken ekran oluşturulmaz', (tester) async {
    final completer = Completer<MeResult>();
    await _pump(tester, () => completer.future);
    await tester.pump();

    expect(find.text('korunan ekran'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(_me([_gymAdmin]));
    await tester.pumpAndSettle();
    expect(find.text('korunan ekran'), findsOneWidget);
  });

  testWidgets('antrenör programı sadece aktif görev Trainer iken açılır', (tester) async {
    final container = await _pump(
      tester,
      () async => _me([_gymAdmin, _trainer]),
      isAllowed: (permissions) => permissions.canViewTrainerSchedule,
    );
    await tester.pumpAndSettle();

    // Varsayılan görev GymAdmin - başka görevdeki antrenörlük yetmez.
    expect(find.text('korunan ekran'), findsNothing);
    expect(find.text(_l10n.staffAccessDeniedTitle), findsOneWidget);

    container.read(activeStaffAssignmentProvider.notifier).select(_trainer.id!);
    await tester.pumpAndSettle();
    expect(find.text('korunan ekran'), findsOneWidget);
  });

  testWidgets('aktif görev Trainer iken yönetim ekranları kapalı', (tester) async {
    final container = await _pump(
      tester,
      () async => _me([_branchManager, _trainer]),
      isAllowed: (permissions) => permissions.canManagePackages,
    );
    await tester.pumpAndSettle();
    expect(find.text('korunan ekran'), findsOneWidget);

    container.read(activeStaffAssignmentProvider.notifier).select(_trainer.id!);
    await tester.pumpAndSettle();
    expect(find.text('korunan ekran'), findsNothing);
    expect(find.text(_l10n.staffAccessDeniedTitle), findsOneWidget);
  });
}
