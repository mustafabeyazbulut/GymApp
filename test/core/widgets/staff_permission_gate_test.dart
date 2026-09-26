import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/widgets/staff_permission_gate.dart';
import 'package:gym_app/features/auth/data/real_auth_repository.dart';
import 'package:gym_app/features/auth/domain/auth_repository.dart';
import 'package:gym_app/features/auth/domain/me_result.dart';
import 'package:gym_app/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

const _gymAdmin = MeAssignment(companyId: 1, companyName: 'A', branchId: null, role: 'GymAdmin');
const _branchManager = MeAssignment(companyId: 1, companyName: 'A', branchId: 9, role: 'BranchManager');

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

Future<void> _pump(WidgetTester tester, Future<MeResult> Function() getMe) async {
  final repository = _MockAuthRepository();
  when(() => repository.getMe()).thenAnswer((_) => getMe());

  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StaffPermissionGate(
          isAllowed: (permissions) => permissions.canManageDoorAccess,
          child: const Text('korunan ekran'),
        ),
      ),
    ),
  );
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
}
