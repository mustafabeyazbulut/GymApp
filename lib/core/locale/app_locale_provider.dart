import 'package:flutter/widgets.dart' show Locale;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_locale_provider.g.dart';

@riverpod
class AppLocale extends _$AppLocale {
  @override
  Locale? build() => null; // null = cihazın sistem locale'ini takip et

  void setLocale(Locale locale) => state = locale;

  // Hesabın kendi preferredLanguage değeri öğrenildiğinde (ör. login
  // sonrası) bir kez çağrılır - yalnızca kullanıcı bu oturumda henüz manuel
  // bir dil seçmemişse uygulanır, böylece uygulama içi manuel bir seçimin
  // üzerine asla yazmaz.
  void seedFromAccount(String languageCode) {
    if (state == null) {
      state = Locale(languageCode);
    }
  }
}
