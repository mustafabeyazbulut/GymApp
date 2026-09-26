import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/auth/data/real_auth_repository.dart';
import 'package:gym_app/features/auth/domain/auth_repository.dart';
import 'package:gym_app/features/auth/domain/me_result.dart';
import 'package:gym_app/features/invitations/presentation/providers/invitations_provider.dart';
import 'package:gym_app/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:gym_app/features/personal_tracking/data/real_personal_log_repository.dart';
import 'package:gym_app/features/personal_tracking/domain/personal_log_repository.dart';
import 'package:gym_app/features/progress/domain/progress_summary.dart';
import 'package:gym_app/features/progress/presentation/providers/progress_summary_provider.dart';
import 'package:gym_app/features/progress/presentation/screens/progress_screen.dart';
import 'package:gym_app/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockPersonalLogRepository extends Mock implements PersonalLogRepository {}

final _l10n = lookupAppLocalizations(const Locale('tr'));

MePackageAssignment _package({String status = 'Active'}) => MePackageAssignment(
      id: 1,
      companyId: 1,
      companyName: 'Test Gym',
      branchId: 9,
      packageId: 5,
      packageName: 'Aylık',
      category: null,
      price: 1000,
      status: status,
      startDate: DateTime(2026, 1, 1),
      endDate: null,
      sessionCount: null,
      remainingSessions: null,
      maxFreezeDays: null,
      totalFrozenDays: 0,
    );

Future<void> _pump(WidgetTester tester, List<MePackageAssignment> packages) async {
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
        assignments: const [],
        packageAssignments: packages,
      ));
  final personalLogRepository = _MockPersonalLogRepository();
  when(() => personalLogRepository.list(from: any(named: 'from'), to: any(named: 'to')))
      .thenAnswer((_) async => const []);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        personalLogRepositoryProvider.overrideWithValue(personalLogRepository),
        hasUnreadNotificationsProvider.overrideWith((ref) => false),
        pendingInvitationCountProvider.overrideWith((ref) => 0),
        progressSummaryProvider.overrideWith(
          (ref) async => const ProgressSummary(classesThisMonth: 3, attendanceValue: 0.5, notes: []),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ProgressScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('paketsiz üye boş durum yerine doğrudan Kişisel Takibim\'i görür', (tester) async {
    await _pump(tester, const []);

    expect(find.text(_l10n.personalLogAddButton), findsOneWidget);
    expect(find.text(_l10n.membershipEmptyStateTitle), findsNothing);
    expect(find.text(_l10n.progressTrainerSectionTitle), findsNothing);
  });

  testWidgets('paketi geçersiz üye de sadece Kişisel Takibim\'i görür', (tester) async {
    await _pump(tester, [_package(status: 'Frozen')]);

    expect(find.text(_l10n.personalLogAddButton), findsOneWidget);
    expect(find.text(_l10n.progressTrainerSectionTitle), findsNothing);
  });

  testWidgets('geçerli paketli üye Antrenörümden ve Kişisel Takibim sekmelerini görür', (tester) async {
    await _pump(tester, [_package()]);

    expect(find.text(_l10n.progressTrainerSectionTitle), findsOneWidget);
    expect(find.text(_l10n.personalTrackingTitle), findsOneWidget);
    // Varsayılan sekme Antrenörümden: gelişim özeti görünür.
    expect(find.text(_l10n.progressClassesCount(3)), findsOneWidget);

    await tester.tap(find.text(_l10n.personalTrackingTitle));
    await tester.pumpAndSettle();

    expect(find.text(_l10n.personalLogAddButton), findsOneWidget);
  });
}
