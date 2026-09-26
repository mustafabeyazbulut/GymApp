import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/auth/data/real_auth_repository.dart';
import 'package:gym_app/features/auth/domain/auth_exceptions.dart';
import 'package:gym_app/features/auth/domain/auth_repository.dart';
import 'package:gym_app/features/auth/domain/me_result.dart';
import 'package:gym_app/features/auth/presentation/providers/current_user_provider.dart';
import 'package:gym_app/features/membership/presentation/widgets/edit_profile_sheet.dart';
import 'package:gym_app/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  // Backend aynı anda iki güncellemeyi 409 ConcurrentUpdate ile reddedebilir -
  // veri yenilenir ve backend'in mesajı gösterilir.
  testWidgets('profil güncellemesi 409 alırsa kullanıcı yenilenir ve backend mesajı gösterilir', (tester) async {
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
    when(() => repository.updateProfile(fullName: any(named: 'fullName'), email: any(named: 'email')))
        .thenThrow(const ConflictAuthException('Profil başka bir oturumda güncellendi.'));

    final container = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(repository)]);
    addTearDown(container.dispose);
    container.listen(currentUserProvider, (_, _) {});
    await container.read(currentUserProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showEditProfileSheet(context, currentFullName: 'Test User', currentEmail: null),
                child: const Text('aç'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();

    final l10n = lookupAppLocalizations(const Locale('tr'));
    await tester.tap(find.widgetWithText(ElevatedButton, l10n.profileEditSaveButton));
    await tester.pumpAndSettle();

    expect(find.text('Profil başka bir oturumda güncellendi.'), findsOneWidget);
    verify(() => repository.getMe()).called(2);
  });
}
