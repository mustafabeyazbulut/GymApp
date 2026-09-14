import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/branches/domain/branch.dart';

void main() {
  test('two Branch instances with the same field values are equal', () {
    const a = Branch(id: 1, companyId: 1, name: 'Merkez', address: 'Adres', isActive: true);
    const b = Branch(id: 1, companyId: 1, name: 'Merkez', address: 'Adres', isActive: true);

    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  });

  test('a different id makes two Branch instances unequal', () {
    const a = Branch(id: 1, companyId: 1, name: 'Merkez', address: 'Adres', isActive: true);
    const b = Branch(id: 2, companyId: 1, name: 'Merkez', address: 'Adres', isActive: true);

    expect(a, isNot(equals(b)));
  });
}
