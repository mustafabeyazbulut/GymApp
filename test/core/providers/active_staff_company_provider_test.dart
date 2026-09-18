import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/providers/active_staff_company_provider.dart';

void main() {
  test('defaults to null and updates on select', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(activeStaffCompanyIdProvider), isNull);

    container.read(activeStaffCompanyIdProvider.notifier).select(5);

    expect(container.read(activeStaffCompanyIdProvider), 5);
  });
}
