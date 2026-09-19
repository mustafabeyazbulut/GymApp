import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/locale/app_locale_provider.dart';
import 'package:gym_app/core/widgets/app_drawer.dart';
import 'package:gym_app/features/auth/data/real_auth_repository.dart';
import 'package:gym_app/features/auth/domain/auth_repository.dart';
import 'package:gym_app/features/auth/domain/me_result.dart';
import 'package:gym_app/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('dil seçimi, çekmece kapatılsa bile arayüz dilini hemen değiştirir', (tester) async {
    final repository = _MockAuthRepository();
    when(() => repository.getMe()).thenAnswer((_) async => const MeResult(
          id: 1, fullName: 'Test User', phone: '+905551112233', email: null, preferredLanguage: 'tr',
          isAccountFrozen: false, assignments: [], packageAssignments: [],
        ));
    when(() => repository.updatePreferredLanguage(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp(
            locale: ref.watch(appLocaleProvider),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                appBar: AppBar(
                  title: Text(AppLocalizations.of(context)!.appTitle),
                  leading: Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                ),
                drawer: const AppDrawer(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(tester.element(find.byType(AppBar)));

    // Çekmeceyi aç, "Dil" satırına dokun.
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.language));
    await tester.pumpAndSettle();

    // Dialog açıldı - "Türkçe" seçeneğine dokun.
    expect(find.text('Türkçe'), findsWidgets);
    await tester.tap(find.text('Türkçe').last);
    await tester.pumpAndSettle();

    // Kritik bug buradaydı: çekmece dialogdan ÖNCE (closeThenRun ile)
    // kapatılınca, dialog sonucu döndüğünde _AppDrawerState çoktan
    // dispose olmuş oluyor ve "if (!mounted) return" her zaman erken
    // çıkıp setLocale'i hiç çalıştırmıyordu.
    expect(container.read(appLocaleProvider), const Locale('tr'));

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.language));
    await tester.pumpAndSettle();
    expect(find.text('English'), findsWidgets);
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();

    expect(container.read(appLocaleProvider), const Locale('en'));
  });
}
