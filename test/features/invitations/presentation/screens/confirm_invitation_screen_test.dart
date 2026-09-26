import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_app/features/invitations/presentation/screens/confirm_invitation_screen.dart';
import 'package:gym_app/l10n/generated/app_localizations.dart';

void main() {
  // SMS kodu 10 dakika geçerli, davet ise 7 gün listede kalıyor - süresi
  // dolmuş koddaki kullanıcı Davetlerim'e yönlendirilir.
  testWidgets('süre dolumu ipucu gösterilir ve Davetlerim\'e götürür', (tester) async {
    final l10n = lookupAppLocalizations(const Locale('tr'));
    final router = GoRouter(
      initialLocation: '/confirm-invitation',
      routes: [
        GoRoute(path: '/confirm-invitation', builder: (context, state) => const ConfirmInvitationScreen()),
        GoRoute(path: '/invitations', builder: (context, state) => const Text('davetlerim-ekrani')),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.confirmInvitationExpiredCodeHint), findsOneWidget);
    await tester.tap(find.text(l10n.confirmInvitationExpiredCodeHint));
    await tester.pumpAndSettle();

    expect(find.text('davetlerim-ekrani'), findsOneWidget);
  });
}
