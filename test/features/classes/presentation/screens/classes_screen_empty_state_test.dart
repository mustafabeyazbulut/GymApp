import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/auth/data/real_auth_repository.dart';
import 'package:gym_app/features/auth/domain/auth_repository.dart';
import 'package:gym_app/features/auth/domain/me_result.dart';
import 'package:gym_app/features/classes/presentation/screens/classes_screen.dart';
import 'package:gym_app/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:gym_app/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

final _l10n = lookupAppLocalizations(const Locale('tr'));

MePackageAssignment _package({String status = 'Active', DateTime? endDate, int? remainingSessions}) =>
    MePackageAssignment(
      id: 1,
      companyId: 1,
      companyName: 'Test Gym',
      branchId: 9,
      packageId: 5,
      packageName: 'Aylık',
      category: 'GroupClass',
      price: 1000,
      status: status,
      startDate: DateTime(2026, 1, 1),
      endDate: endDate,
      sessionCount: remainingSessions == null ? null : 10,
      remainingSessions: remainingSessions,
      maxFreezeDays: null,
      totalFrozenDays: 0,
    );

Future<void> _pump(WidgetTester tester, List<MePackageAssignment> packages) async {
  final repository = _MockAuthRepository();
  when(() => repository.getMe()).thenAnswer((_) async => MeResult(
        id: 1,
        fullName: 'Test User',
        phone: '+905551112233',
        email: null,
        preferredLanguage: 'tr',
        isAccountFrozen: false,
        assignments: const [],
        packageAssignments: packages,
      ));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        hasUnreadNotificationsProvider.overrideWith((ref) => false),
      ],
      child: MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ClassesScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('paketsiz üye "Paketin yok" boş durumunu görür', (tester) async {
    await _pump(tester, const []);

    expect(find.text(_l10n.packageStatusNoPackageTitle), findsOneWidget);
    expect(find.text(_l10n.packageStatusNoPackageBody), findsOneWidget);
    expect(find.text(_l10n.groupClassEmptyMessage), findsNothing);
  });

  testWidgets('donmuş paketli üye "Paketin geçerli değil" ve nedenini görür', (tester) async {
    await _pump(tester, [_package(status: 'Frozen')]);

    expect(find.text(_l10n.packageStatusInvalidTitle), findsOneWidget);
    expect(find.text(_l10n.packageStatusInvalidFrozen), findsOneWidget);
  });

  testWidgets('süresi dolmuş paketli üye süre dolumu nedenini görür', (tester) async {
    await _pump(tester, [_package(endDate: DateTime(2026, 1, 31))]);

    expect(find.text(_l10n.packageStatusInvalidTitle), findsOneWidget);
    expect(find.text(_l10n.packageStatusInvalidExpired), findsOneWidget);
  });

  testWidgets('hakkı bitmiş paketli üye hak bitimi nedenini görür', (tester) async {
    await _pump(tester, [_package(remainingSessions: 0)]);

    expect(find.text(_l10n.packageStatusInvalidNoSessions), findsOneWidget);
  });
}
