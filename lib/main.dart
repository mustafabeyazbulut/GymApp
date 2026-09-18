import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/locale/app_locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/current_user_provider.dart';
import 'l10n/generated/app_localizations.dart';

void main() {
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
