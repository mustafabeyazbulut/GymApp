import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/format/localized_decimal.dart';

void main() {
  const tr = Locale('tr');
  const en = Locale('en');

  group('parseLocalizedDecimal', () {
    test('Türkçede virgül ondalık ayırıcıdır', () {
      expect(parseLocalizedDecimal('72,4', tr), 72.4);
    });

    // Türkçe klavyede nokta da sık yazılır; ölçülerde binlik ayırıcı kullanılmaz.
    test('Türkçede nokta da ondalık olarak kabul edilir', () {
      expect(parseLocalizedDecimal('72.4', tr), 72.4);
    });

    test('İngilizcede nokta ondalıktır, virgül geçersizdir', () {
      expect(parseLocalizedDecimal('72.4', en), 72.4);
      expect(parseLocalizedDecimal('72,4', en), isNull);
    });

    test('tam sayı ve boşluklar', () {
      expect(parseLocalizedDecimal(' 80 ', tr), 80);
    });

    test('boş, harf veya birden fazla ayırıcı geçersizdir', () {
      expect(parseLocalizedDecimal('', tr), isNull);
      expect(parseLocalizedDecimal('abc', tr), isNull);
      expect(parseLocalizedDecimal('1,2,3', tr), isNull);
      expect(parseLocalizedDecimal('1.2.3', en), isNull);
    });
  });

  group('formatLocalizedDecimal', () {
    test('dile göre ayırıcıyla ve gereksiz sıfırsız yazar', () {
      expect(formatLocalizedDecimal(72.4, tr), '72,4');
      expect(formatLocalizedDecimal(72.4, en), '72.4');
      expect(formatLocalizedDecimal(80, tr), '80');
    });
  });
}
