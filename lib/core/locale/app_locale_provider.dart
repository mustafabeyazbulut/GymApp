import 'package:flutter/widgets.dart' show Locale;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_locale_provider.g.dart';

@riverpod
class AppLocale extends _$AppLocale {
  @override
  Locale? build() => null; // null = follow the device's system locale

  void setLocale(Locale locale) => state = locale;

  // Called once the account's own preferredLanguage becomes known (e.g.
  // after login) - only applies it if the viewer hasn't already picked a
  // language this session, so it never overwrites a manual in-app choice.
  void seedFromAccount(String languageCode) {
    if (state == null) {
      state = Locale(languageCode);
    }
  }
}
