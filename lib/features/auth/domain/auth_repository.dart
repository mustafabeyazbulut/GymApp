import 'me_result.dart';

abstract interface class AuthRepository {
  // Phone is required (matches the backend User entity's required+unique
  // Phone column); email is optional. login() keeps a single `identifier`
  // field since the backend accepts either phone or email there.
  Future<void> register({
    required String fullName,
    required String phone,
    String? email,
    required String password,
  });

  Future<void> login({required String identifier, required String password});

  Future<void> logout();

  Future<void> forgotPassword({required String identifier});

  Future<void> resetPassword({
    required String identifier,
    required String code,
    required String newPassword,
  });

  Future<MeResult> getMe();
}
