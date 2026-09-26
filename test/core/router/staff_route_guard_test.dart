import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/fake_token_store.dart';
import 'package:gym_app/core/network/secure_token_store.dart';
import 'package:gym_app/core/router/app_router.dart';
import 'package:gym_app/features/auth/data/real_auth_repository.dart';
import 'package:gym_app/features/auth/domain/auth_repository.dart';
import 'package:gym_app/features/auth/domain/me_result.dart';
import 'package:gym_app/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:gym_app/features/door_access/presentation/screens/door_access_screen.dart';
import 'package:gym_app/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:gym_app/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

final _l10n = lookupAppLocalizations(const Locale('tr'));

// Rotaya doğrudan gidildiğinde (deep link / web URL) menüdeki gizleme
// devre dışı kalır - bu yüzden koruma rota seviyesinde de olmalı.
void main() {
  testWidgets('BranchManager /staff/door-access rotasına doğrudan gidince yetkisiz durumu görür', (tester) async {
    final tokenStore = FakeTokenStore();
    await tokenStore.saveTokens(accessToken: 'a', refreshToken: 'r');
    final repository = _MockAuthRepository();
    when(() => repository.getMe()).thenAnswer((_) async => const MeResult(
          id: 1,
          fullName: 'Test User',
          phone: '+905551112233',
          email: null,
          preferredLanguage: 'tr',
          isAccountFrozen: false,
          assignments: [MeAssignment(companyId: 1, companyName: 'A', branchId: 9, role: 'BranchManager')],
          packageAssignments: [],
        ));

    final container = ProviderContainer(overrides: [
      tokenStoreProvider.overrideWithValue(tokenStore),
      authRepositoryProvider.overrideWithValue(repository),
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

    container.read(appRouterProvider).push('/staff/door-access');
    await tester.pumpAndSettle();

    expect(find.byType(DoorAccessScreen), findsNothing);
    expect(find.text(_l10n.staffAccessDeniedTitle), findsOneWidget);
  });
}
