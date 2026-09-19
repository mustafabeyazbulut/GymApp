import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/locale/app_locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/domain/auth_exceptions.dart';
import 'features/auth/presentation/providers/auth_state_provider.dart';
import 'features/auth/presentation/providers/current_user_provider.dart';
import 'l10n/generated/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Home ekranının haftalık devam grafiği DateFormat.E(locale) ile lokal
  // gün kısaltmaları (Pzt/Sal/... veya Mon/Tue/...) üretiyor - intl bunu
  // önceden yüklenmiş locale verisi olmadan atar (LocaleDataException).
  await initializeDateFormatting();
  runApp(const ProviderScope(child: GymApp()));
}

class GymApp extends ConsumerWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(appRouterProvider);

    // Uygulamanın locale'ini, bu oturumda hesabın kendi preferredLanguage
    // değeri ilk öğrenildiğinde (ör. login sonrası) başlangıç değeriyle
    // ayarlar - bunun kullanıcının uygulama içinde manuel olarak seçtiği bir
    // dilin üzerine neden asla yazmadığı için AppLocale.seedFromAccount'ın
    // doc comment'ine bakın.
    ref.listen(currentUserProvider, (previous, next) {
      final language = next.value?.preferredLanguage;
      if (language != null) {
        ref.read(appLocaleProvider.notifier).seedFromAccount(language);
      }
      // Oturum gerçekten geçersizse (ör. dio_client.dart'ın refresh-and-retry
      // akışı da başarısız oldu) currentUserProvider bir SessionExpiredException
      // ile hata durumuna düşer, ama tokenStore.clear() sadece interceptor
      // içinde çağrılır - authStateProvider'ın kendi (kimlik durumunu ve
      // router'ın /login yönlendirmesini süren) state'i bundan HABERSİZ
      // kalır. Bu yüzden kullanıcı, kimliği boş/"?" görünen, hiçbir menü
      // öğesi çalışmayan yarı-oturum-açık bir Home ekranında sıkışıp
      // kalıyordu - logOut() burada çağrılıp router'ın gerçekten /login'e
      // yönlendirmesi sağlanıyor.
      //
      // KRİTİK: logOut() bu ref.listen'i BOZAN bir currentUserProvider
      // invalidate() çağırıyor - listener burada hala aktif olduğundan bu,
      // provider'ı HEMEN yeniden inşa ediyor (getMe() tekrar çağrılıyor).
      // Hiç token yokken (ör. zaten /login ekranındayken - bu widget HER
      // rotada, /login dahil, build ediliyor) bu da yine 401/SessionExpired
      // üretip logOut()'u tekrar tetikliyor - authState kontrolü olmadan bu,
      // backend'i /api/auth/me ile bombalayan SONSUZ bir döngüye dönüşüyordu
      // (canlı testte 190+ art arda istek gözlemlendi). Sadece GERÇEKTEN
      // oturum açıkken (authState true) tepki vererek döngü bir kez sonra
      // kendiliğinden kırılıyor.
      final wasAuthenticated = ref.read(authStateProvider).value ?? false;
      if (wasAuthenticated && next.hasError && next.error is SessionExpiredException) {
        ref.read(authStateProvider.notifier).logOut();
      }
    });

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      locale: ref.watch(appLocaleProvider),
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
