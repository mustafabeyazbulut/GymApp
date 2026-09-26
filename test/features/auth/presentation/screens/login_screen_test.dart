import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/fake_token_store.dart';
import 'package:gym_app/core/network/secure_token_store.dart';
import 'package:gym_app/features/auth/data/real_auth_repository.dart';
import 'package:gym_app/features/auth/domain/auth_repository.dart';
import 'package:gym_app/features/auth/presentation/screens/login_screen.dart';
import 'package:gym_app/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

final _l10n = lookupAppLocalizations(const Locale('tr'));

Future<_MockAuthRepository> _pump(WidgetTester tester) async {
  tester.platformDispatcher.localeTestValue = const Locale('tr', 'TR');
  addTearDown(tester.platformDispatcher.clearLocaleTestValue);
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final repository = _MockAuthRepository();
  when(() => repository.login(identifier: any(named: 'identifier'), password: any(named: 'password')))
      .thenAnswer((_) async {});

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        tokenStoreProvider.overrideWithValue(FakeTokenStore()),
      ],
      child: MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LoginScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

Future<void> _submit(WidgetTester tester, String identifier) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), identifier);
  await tester.enterText(fields.at(1), 'sifre1234');
  await tester.tap(find.text(_l10n.loginSubmitButton));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('telefonla girişte numara E.164 biçiminde gönderilir', (tester) async {
    final repository = await _pump(tester);

    await _submit(tester, '05551234567');

    verify(() => repository.login(identifier: '+905551234567', password: 'sifre1234')).called(1);
  });

  testWidgets('e-postayla giriş bozulmaz, e-posta olduğu gibi gönderilir', (tester) async {
    final repository = await _pump(tester);

    await _submit(tester, 'ayse@test.com');

    verify(() => repository.login(identifier: 'ayse@test.com', password: 'sifre1234')).called(1);
  });

  testWidgets('geçersiz numarayla giriş isteği gönderilmez', (tester) async {
    final repository = await _pump(tester);

    await _submit(tester, '123');

    expect(find.text(_l10n.phoneInvalidError), findsOneWidget);
    verifyNever(() => repository.login(identifier: any(named: 'identifier'), password: any(named: 'password')));
  });
}
