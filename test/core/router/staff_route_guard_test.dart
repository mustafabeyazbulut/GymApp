import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/fake_token_store.dart';
import 'package:gym_app/core/network/secure_token_store.dart';
import 'package:gym_app/core/providers/active_staff_assignment_provider.dart';
import 'package:gym_app/core/router/app_router.dart';
import 'package:gym_app/features/auth/data/real_auth_repository.dart';
import 'package:gym_app/features/auth/domain/auth_repository.dart';
import 'package:gym_app/features/auth/domain/me_result.dart';
import 'package:gym_app/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:gym_app/features/door_access/presentation/screens/door_access_screen.dart';
import 'package:gym_app/features/invitations/data/real_invitation_repository.dart';
import 'package:gym_app/features/invitations/domain/invitation_repository.dart';
import 'package:gym_app/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:gym_app/features/platform_reports/presentation/screens/platform_reports_screen.dart';
import 'package:gym_app/features/trainer_schedule/presentation/screens/trainer_schedule_screen.dart';
import 'package:gym_app/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockInvitationRepository extends Mock implements InvitationRepository {}

class _MemoryStore implements ActiveAssignmentStore {
  @override
  Future<int?> read() async => null;

  @override
  Future<void> write(int? assignmentId) async {}
}

final _l10n = lookupAppLocalizations(const Locale('tr'));

Future<void> _pumpAppAndPush(WidgetTester tester, List<MeAssignment> assignments, String location) async {
  final tokenStore = FakeTokenStore();
  await tokenStore.saveTokens(accessToken: 'a', refreshToken: 'r');
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

  final invitationRepository = _MockInvitationRepository();
  when(() => invitationRepository.getMyInvitations()).thenAnswer((_) async => const []);

  final container = ProviderContainer(overrides: [
    tokenStoreProvider.overrideWithValue(tokenStore),
    invitationRepositoryProvider.overrideWithValue(invitationRepository),
    authRepositoryProvider.overrideWithValue(repository),
    activeAssignmentStoreProvider.overrideWithValue(_MemoryStore()),
    hasUnreadNotificationsProvider.overrideWith((ref) => false),
  ]);
  addTearDown(container.dispose);
  await container.read(authStateProvider.future);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: ref.watch(appRouterProvider),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  container.read(appRouterProvider).push(location);
  await tester.pumpAndSettle();
}

// Rotaya doğrudan gidildiğinde (deep link / web URL) menüdeki gizleme
// devre dışı kalır - bu yüzden koruma rota seviyesinde de olmalı.
void main() {
  testWidgets('BranchManager /staff/door-access rotasına doğrudan gidince yetkisiz durumu görür', (tester) async {
    await _pumpAppAndPush(
      tester,
      const [MeAssignment(id: 1, companyId: 1, companyName: 'A', branchId: 9, role: 'BranchManager')],
      '/staff/door-access',
    );

    expect(find.byType(DoorAccessScreen), findsNothing);
    expect(find.text(_l10n.staffAccessDeniedTitle), findsOneWidget);
  });

  testWidgets('Sistem Sahibi olmayan kullanıcı /admin/platform-reports rotasında yetkisiz durumu görür',
      (tester) async {
    await _pumpAppAndPush(
      tester,
      const [MeAssignment(id: 1, companyId: 1, companyName: 'A', branchId: null, role: 'GymAdmin')],
      '/admin/platform-reports',
    );

    expect(find.byType(PlatformReportsScreen), findsNothing);
    expect(find.text(_l10n.staffAccessDeniedTitle), findsOneWidget);
  });

  testWidgets('aktif görevi Trainer olmayan kullanıcı /trainer/schedule rotasında yetkisiz durumu görür',
      (tester) async {
    // Antrenörlüğü var ama varsayılan aktif görev BranchManager.
    await _pumpAppAndPush(
      tester,
      const [
        MeAssignment(id: 1, companyId: 1, companyName: 'A', branchId: 9, role: 'Trainer'),
        MeAssignment(id: 2, companyId: 1, companyName: 'A', branchId: 10, role: 'BranchManager'),
      ],
      '/trainer/schedule',
    );

    expect(find.byType(TrainerScheduleScreen), findsNothing);
    expect(find.text(_l10n.staffAccessDeniedTitle), findsOneWidget);
  });
}
