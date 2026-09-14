import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/auth/data/fake_auth_repository.dart';

void main() {
  test('login completes without throwing for any non-empty credentials', () async {
    final repository = FakeAuthRepository();

    await expectLater(
      repository.login(identifier: 'elnara@example.com', password: 'anything'),
      completes,
    );
  });
}
