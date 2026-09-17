import 'me_result.dart';

abstract interface class AuthRepository {
  // login() keeps a single `identifier` field since the backend accepts
  // either phone or email there. Accounts are staff-created now (see
  // TenantRepository.createCompany/addStaffMember) - self-service
  // registration has been retired.
  Future<void> login({required String identifier, required String password});

  Future<void> logout();

  Future<void> forgotPassword({required String identifier});

  Future<void> resetPassword({
    required String identifier,
    required String code,
    required String newPassword,
  });

  Future<MeResult> getMe();

  // Irreversible, so it requires proving control of the account's phone
  // first via a 6-digit code, same as freeze/unfreeze below.
  Future<void> requestDeleteAccountOtp();

  Future<void> deleteAccount({required String code});

  Future<void> updatePreferredLanguage(String language);

  // Distinct from any membership/package freeze - this temporarily disables
  // the account's own login access (Instagram-style "deactivate
  // temporarily"). Login itself still succeeds afterward; the app gates
  // navigation behind a reactivation screen once getMe() reports
  // isAccountFrozen. Both freezing and reactivating require proving control
  // of the account's phone first via a 6-digit code (requestFreezeOtp/
  // requestUnfreezeOtp send it, freezeAccount/reactivateAccount consume it).
  Future<void> requestFreezeOtp();

  Future<void> freezeAccount({required String code});

  Future<void> requestUnfreezeOtp();

  Future<void> reactivateAccount({required String code});
}
