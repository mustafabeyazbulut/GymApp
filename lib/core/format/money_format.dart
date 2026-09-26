import 'dart:ui';

import 'package:intl/intl.dart';

/// Tutarı uygulamanın diline göre para birimi simgesiyle yazar:
/// tr → ₺1.234,50, en → ₺1,234.50. [currency] ISO kodudur (ör. "TRY").
String formatMoney(num amount, String currency, Locale locale) {
  final localeName = locale.languageCode == 'tr' ? 'tr_TR' : 'en_US';
  final symbol = NumberFormat.simpleCurrency(locale: localeName, name: currency).currencySymbol;
  return NumberFormat.currency(locale: localeName, symbol: symbol, decimalDigits: 2).format(amount);
}
