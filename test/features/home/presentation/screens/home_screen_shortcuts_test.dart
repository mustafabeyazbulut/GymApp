import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_app/features/auth/data/real_auth_repository.dart';
import 'package:gym_app/features/auth/domain/auth_repository.dart';
import 'package:gym_app/features/auth/domain/me_result.dart';
import 'package:gym_app/features/home/presentation/screens/home_screen.dart';
import 'package:gym_app/features/invitations/presentation/providers/invitations_provider.dart';
import 'package:gym_app/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:gym_app/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

final _l10n = lookupAppLocalizations(const Locale('tr'));

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final repository = _MockAuthRepository();
  when(() => repository.getMe()).thenAnswer((_) async => const MeResult(
        id: 1,
        fullName: 'Test User',
        phone: '+905551112233',
        email: null,
        preferredLanguage: 'tr',
        isAccountFrozen: false,
        assignments: [],
        packageAssignments: [],
      ));
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/progress', builder: (context, state) => const Text('ilerleme-ekrani')),
      GoRoute(path: '/content-library', builder: (context, state) => const Text('icerik-ekrani')),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        hasUnreadNotificationsProvider.overrideWith((ref) => false),
        pendingInvitationCountProvider.overrideWith((ref) => 0),
      ],
      child: MaterialApp.router(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('paketsiz üye boş durumun altında iki kısayol kartı görür', (tester) async {
    await _pump(tester);

    expect(find.text(_l10n.membershipEmptyStateTitle), findsOneWidget);
    expect(find.text(_l10n.personalTrackingTitle), findsOneWidget);
    expect(find.text(_l10n.homeShortcutGeneralContentTitle), findsOneWidget);
  });

  testWidgets('Kişisel Takibim kısayolu İlerleme sekmesine götürür', (tester) async {
    await _pump(tester);

    await tester.tap(find.text(_l10n.personalTrackingTitle));
    await tester.pumpAndSettle();

    expect(find.text('ilerleme-ekrani'), findsOneWidget);
  });

  testWidgets('Genel İçerik kısayolu İçerik Kütüphanesi\'ne götürür', (tester) async {
    await _pump(tester);

    await tester.tap(find.text(_l10n.homeShortcutGeneralContentTitle));
    await tester.pumpAndSettle();

    expect(find.text('icerik-ekrani'), findsOneWidget);
  });
}
