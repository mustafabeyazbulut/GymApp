import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/auth/presentation/providers/auth_state_provider.dart';

void main() {
  test('starts logged out, logIn sets true, logOut sets false', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(authStateProvider), false);

    container.read(authStateProvider.notifier).logIn();
    expect(container.read(authStateProvider), true);

    container.read(authStateProvider.notifier).logOut();
    expect(container.read(authStateProvider), false);
  });
}
