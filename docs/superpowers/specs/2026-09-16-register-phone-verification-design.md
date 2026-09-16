# Kayıtta Telefon ve E-posta Doğrulama (Mobil) — Tasarım

## Genel Bakış

Register ekranı şu anda tek adımda çalışıyor: form doldurulup gönderilince hesap hemen oluşuyor, telefon/e-posta hiç doğrulanmıyor. Bu spec, Register ekranını Forgot Password ekranındaki gibi **2 adımlı** bir akışa çeviriyor: önce kod(lar) istenir, sonra kod(lar) girilerek kayıt tamamlanır.

Backend tarafının tam tasarımı (endpoint'ler, veri modeli, rate limit stratejisi): `C:\Users\MBEYAZBULUT\Documents\GitHub\GymAppApi\docs\superpowers\specs\2026-09-16-register-phone-verification-design.md` — burada tekrar edilmiyor, sadece mobilin o API'yi nasıl tükettiği anlatılıyor.

Bu, [[reference-real-auth-design-pointer]] ile tamamlanmış Real Auth özelliğinin üzerine gelen küçük bir iyileştirme.

## Kapsam Dışı

- Şifre tekrarı alanı — kullanıcı bu turda kapsam dışı bıraktı.
- Login/Forgot Password ekranlarındaki "kimlik" (identifier) alanı değişmiyor — hâlâ serbest metin (telefon veya e-posta), ülke kodu seçici eklenmiyor. Sadece Register'daki telefon alanı bu spec'in kapsamında.
- **Dil değiştirme (uygulama genelinde bir dil seçici):** ayrı, bağımsız bir istek olarak not edildi — bu spec'in konusu değil, kullanıcının kararıyla ayrı bir brainstorming turunda ele alınacak.
- Ayrı bir "resend" butonu/endpoint'i — resend, Adım 2'de "numarayı/e-postayı değiştir" ile Adım 1'e dönüp tekrar göndermek üzerinden yapılır (backend spec'teki "Aynı Numara/E-posta ile Tekrar Deneme" bölümüyle tutarlı).

## Ekran Akışı — Register (2 Adım)

Mevcut `ForgotPasswordScreen`'in `_Step` enum + tek `Form`/iki bölüm deseni birebir tekrar kullanılır:

- **Adım 1 (`requestOtp`):** Ad Soyad, Telefon, E-posta (opsiyonel), Şifre alanları — mevcut Register formunun aynısı, Telefon alanı hariç (bkz. "Telefon Alanı — Ülke Kodu Seçici" aşağıda). "Kod Gönder" butonu → `requestRegistrationOtp(phone, email)` çağrılır. Başarılıysa Adım 2'ye geçilir; e-posta girilmişse hem telefona hem e-postaya kod gittiğini belirten bir mesaj (`SnackBar`, ForgotPassword'daki `forgotPasswordCodeSentMessage` deseniyle aynı), girilmemişse sadece telefona gittiğini belirten mesaj.
- **Adım 2 (`completeRegistration`):** Ad Soyad/Telefon/E-posta/Şifre alanları `enabled: false` olarak görünmeye devam eder (ForgotPassword'daki identifier alanı gibi — kullanıcı ne girdiğini görür ama değiştiremez, değiştirmek isterse geri dönmesi gerekir). Altına **Telefon Kodu** alanı eklenir; e-posta girildiyse ayrıca **E-posta Kodu** alanı da eklenir (girilmediyse hiç gösterilmez). Her iki kod alanı da: `keyboardType: TextInputType.number`, `inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)]` — rakam dışında hiçbir karakter fiziksel olarak girilemez, 6 haneden uzun da yazılamaz. "Kayıt Ol" butonu → `completeRegistration(fullName, phone, phoneCode, email, emailCode, password)` çağrılır. Başarılıysa token'lar kaydedilir, `authStateProvider.logIn()` çağrılır, `/home`'a geçilir (mevcut Register'ın başarı davranışı, aynen).
- **Geri/değiştir:** Adım 2'de bir "Bilgileri değiştir" `TextButton`'ı (ForgotPassword'daki `forgotPasswordChangeIdentifier` deseniyle aynı) — Adım 1'e döner, tüm alanları tekrar `enabled: true` yapar, kod alanlarını temizler. Adım 1'de mevcut "Zaten hesabın var mı?" linki aynen kalır.

## Telefon Alanı — Ülke Kodu Seçici

Kullanıcının kararı: telefon alanı tüm ülkeleri desteklemeli, başında diğer uygulamalardaki gibi bir ülke kodu seçici (bayrak + çevirme kodu) olmalı — serbest metin alanı değil. Mevcut kod tabanında buna hazır bir bileşen yok, `intl_phone_field` paketi (pub.dev, `flutter pub add intl_phone_field`) eklenir: bayrak + aranabilir ülke listesi + çevirme kodu prefiksi + ulusal numara girişi tek bir widget'ta, klavye otomatik `TextInputType.phone` ve rakam dışı karakterleri kendi içinde reddeder, seçili ülkenin numara uzunluğuna göre format doğrulaması yapar (paketin kendi `validator`/`onChanged(PhoneNumber)` API'si). Varsayılan ülke Türkiye (+90) — kullanıcı değiştirebilir. `onChanged`'dan gelen `PhoneNumber.completeNumber` (E.164 formatı, örn. `+905321234567`) hem `requestRegistrationOtp`'a hem `completeRegistration`'a `phone` olarak gönderilen değerdir; backend'e her zaman `+` ile başlayan E.164 formatında gider (bkz. backend spec'in güncellenen `Phone` validasyon kuralı).

**Geriye dönük not:** Real Auth planında kayıt olmuş mevcut kullanıcıların telefon numaraları E.164 formatında değil (ülke kodu seçici o zaman yoktu) — bu, Login/Forgot Password'daki serbest metin "identifier" alanını etkilemiyor (o alan hâlâ ne yazıldıysa onu gönderiyor), sadece yeni kayıtlar bundan sonra E.164 formatında saklanacak.

## `AuthRepository` Değişikliği

```dart
abstract interface class AuthRepository {
  // register(...) KALDIRILDI, yerine:
  Future<void> requestRegistrationOtp({required String phone, String? email});
  Future<void> completeRegistration({
    required String fullName,
    required String phone,
    required String phoneCode,
    String? email,
    String? emailCode,
    required String password,
  });
  // login/logout/forgotPassword/resetPassword/getMe/deleteAccount değişmiyor
}
```

`RealAuthRepository`: `requestRegistrationOtp` → `POST /api/auth/register/request-otp` `{phone, email}`; `completeRegistration` → `POST /api/auth/register/complete` `{fullName, phone, phoneCode, email, emailCode, password}`, dönen `{accessToken, refreshToken}` mevcut `_storeTokenPair` ile aynı şekilde saklanır.

Hata haritalama (`_mapException`) mevcut haliyle yeterli — 409 (`ConflictAuthException`, zaten kayıtlı telefon/e-posta), 429 (mevcut `RateLimitedAuthException`, gönderim limiti aşıldığında da aynı mesaj kullanılır, ayrı bir exception tipi eklenmiyor — YAGNI), 400/diğer (`GenericAuthException`, örn. yanlış kod) zaten kapsıyor.

## Test Stratejisi

Task 3'ün (`RealAuthRepository` testleri) deseniyle aynı: `http_mock_adapter` ile her iki yeni metod için başarı + 409 + 429 + yanlış-kod senaryoları. Register ekranı için widget testi yok (Member Experience/Real Auth planlarında zaten kararlaştırıldığı gibi, bu repoda feature ekranlarının hiçbirinde widget testi yok, iş mantığı repository testleriyle kapsanıyor).

## Açık Notlar

- Adım 2'de iki kod alanı varken hangisinin yanlış olduğunu ayırt eden bir hata mesajı backend'den `InvalidContactVerificationCodeException`'ın mesaj metnine bağlı — mesajın "telefon kodu" / "e-posta kodu" ayrımını net yapması gerekiyor, aksi halde kullanıcı hangi alanı düzelteceğini anlayamaz. Plan yazılırken backend mesaj metinleri buna göre netleştirilsin.
