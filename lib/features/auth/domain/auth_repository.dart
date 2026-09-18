import 'me_result.dart';

abstract interface class AuthRepository {
  // İki adımlı kayıt: request-otp telefona (ve verilmişse e-postaya) bir kod
  // gönderir ama henüz hiçbir şey oluşturmaz; completeRegistration ise ancak
  // her iki kod da doğru kanıtlandığında hesabı oluşturur. Phone zorunludur
  // (backend'deki User entity'sinin zorunlu+benzersiz Phone kolonuyla eşleşir);
  // email opsiyoneldir. login() tek bir `identifier` alanını korur, çünkü
  // backend orada telefon veya e-postadan herhangi birini kabul eder.
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

  // Geri alınamaz olduğu için, aşağıdaki freeze/unfreeze ile aynı şekilde önce
  // 6 haneli bir kodla hesabın telefonuna sahip olunduğunun kanıtlanmasını gerektirir.
  Future<void> requestDeleteAccountOtp();

  Future<void> deleteAccount({required String code});

  Future<void> updatePreferredLanguage(String language);

  // Herhangi bir üyelik/paket dondurmasından farklıdır - bu, hesabın kendi
  // giriş erişimini geçici olarak devre dışı bırakır (Instagram tarzı
  // "geçici olarak devre dışı bırak"). Login işlemi yine de başarılı olur;
  // getMe() isAccountFrozen bildirdiğinde uygulama navigasyonu bir yeniden
  // etkinleştirme ekranının arkasında tutar. Hem dondurma hem de yeniden
  // etkinleştirme, önce 6 haneli bir kodla hesabın telefonuna sahip olunduğunun
  // kanıtlanmasını gerektirir (requestFreezeOtp/requestUnfreezeOtp kodu gönderir,
  // freezeAccount/reactivateAccount ise onu tüketir).
  Future<void> requestFreezeOtp();

  Future<void> freezeAccount({required String code});

  Future<void> requestUnfreezeOtp();

  Future<void> reactivateAccount({required String code});
}
