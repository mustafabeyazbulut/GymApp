import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/format/money_format.dart';

void main() {
  test('Türkçede ₺1.234,50 biçimi', () {
    expect(formatMoney(1234.5, 'TRY', const Locale('tr')), '₺1.234,50');
  });

  test('İngilizcede ₺1,234.50 biçimi', () {
    expect(formatMoney(1234.5, 'TRY', const Locale('en')), '₺1,234.50');
  });

  test('sıfır ve büyük tutarlar', () {
    expect(formatMoney(0, 'TRY', const Locale('tr')), '₺0,00');
    expect(formatMoney(1250000, 'TRY', const Locale('tr')), '₺1.250.000,00');
  });

  test('bilinmeyen para biriminde kodu sembol olarak kullanır', () {
    expect(formatMoney(10, 'XYZ', const Locale('en')), contains('10.00'));
  });
}
