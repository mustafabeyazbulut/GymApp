import 'dart:ui';

import 'package:intl/intl.dart';

/// Kullanıcının yazdığı ondalık sayıyı uygulamanın diline göre çözer.
///
/// Türkçede ondalık ayırıcı virgüldür; Türkçe klavyede nokta da sık
/// yazıldığı ve vücut ölçülerinde binlik ayırıcı kullanılmadığı için ikisi
/// de ondalık kabul edilir. İngilizcede sadece nokta ondalıktır (virgül
/// binlik ayırıcı olduğundan "72,4" belirsizdir, geçersiz sayılır).
/// Geçersiz girişte null döner.
double? parseLocalizedDecimal(String input, Locale locale) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;
  final usesDecimalComma = locale.languageCode == 'tr';
  if (!usesDecimalComma && trimmed.contains(',')) return null;
  final normalized = usesDecimalComma ? trimmed.replaceAll(',', '.') : trimmed;
  if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(normalized)) return null;
  return double.parse(normalized);
}

/// Sayıyı dile göre ondalık ayırıcıyla, en fazla [maxFractionDigits]
/// basamakla ve gereksiz sıfırlar olmadan yazar (72,4 / 72.4 / 80).
String formatLocalizedDecimal(double value, Locale locale, {int maxFractionDigits = 1}) {
  final format = NumberFormat.decimalPattern(locale.languageCode)
    ..minimumFractionDigits = 0
    ..maximumFractionDigits = maxFractionDigits;
  return format.format(value);
}
