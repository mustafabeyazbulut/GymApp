import 'me_result.dart';

abstract interface class AuthRepository {
  // Two-step registration: request-otp sends a code to phone (and email, if
  // given) but creates nothing yet; completeRegistration only creates the
  // account once both codes are proven correct. Phone is required (matches
  // the backend User entity's required+unique Phone column); email is
  // optional. login() keeps a single `identifier` field since the backend
  // accepts either phone or email there.
  Future<void> requestRegistrationOtp({required String phone, String? email});

  Future<void> completeRegistration({
    required String fullName,
    required String phone,
    required String phoneCode,
    String? email,
    String? emailCode,
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

  Future<void> deleteAccount();

  Future<void> updatePreferredLanguage(String language);

  // Distinct from any membership/package freeze - this temporarily disables
  // the account's own login access (Instagram-style "deactivate
  // temporarily"). Login itself still succeeds afterward; the app gates
  // navigation behind a reactivation screen once getMe() reports
  // isAccountFrozen.
  Future<void> freezeAccount();

  Future<void> reactivateAccount();
}
