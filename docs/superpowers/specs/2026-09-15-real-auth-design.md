# Real Auth (Mobil) — Tasarım

## Genel Bakış

GymApp'te sahte (`FakeAuthRepository`, her zaman başarılı) girişin yerini gerçek, backend-entegre bir Auth akışının alması: Giriş, Kayıt Ol, Şifremi Unuttum ekranları + bunları destekleyen gerçek `AuthRepository`, kalıcı oturum (token secure storage), ve zaten kodlanmış 4 ekranın (Ana Sayfa/Dersler/Gelişimim/Üyeliğim) yeni görsel dile taşınması.

Backend tarafının tam tasarımı (endpoint'ler, veri modeli, JWT/refresh/reset stratejisi, tenantsız-kullanıcı modeli): `C:\Users\MBEYAZBULUT\Documents\GitHub\GymAppApi\docs\superpowers\specs\2026-09-15-real-auth-design.md` — burada tekrar edilmiyor, sadece mobilin o API'yi nasıl tükettiği anlatılıyor.

## Neden bu tasarım / süreç

Görsel yön önce bir frontend-design (HTML mockup, kod yazılmadan) turuyla netleşti — 3 iterasyon: v1 (gradient hero + istatistik satırı) ve v2 (üst hero/desen + alt sheet) kullanıcı tarafından reddedildi ("çok kötü" — hero/desen alanı, ŞUBE/ÜYE/PUAN satırı, genel yeşil/siyah atmosfer VE genel kompozisyon, hepsi işaretlendi), v3 — düz zemin, ince alt-çizgi form alanları, yeşilin sadece odak/buton gibi işlevsel noktalarda kullanılması — onaylandı. Onaylanan mockup: https://claude.ai/artifact/MZ3o6pBqNd2rYawmG97hNS (login'in 5 durumu + 4 ekranın aynı dilde önizlemesi).

Sonra kullanıcı "bu tasarımı uygulayacağız, en başından başla" dedi ve bu (superpowers:brainstorming ile) gerçek backend-entegre auth'un tasarım oturumuna dönüştü. Oturumda netleşen en önemli karar: **açık üyelik modeli** — bkz. backend spec'in "Neden bu tasarım" bölümü. Mobil tarafın buradaki karşılığı: kayıt ekranında hiçbir firma/tenant seçimi YOK, kullanıcı sade bir Üye olarak kayıt olur; bir tenant onu bağlayana kadar uygulama "henüz aktif üyeliğin yok" bilgilendirici boş durumunu gösterir.

## Kapsam Dışı

- Gerçek Package/Membership/Ders verisi — 4 ekran hâlâ kendi `Fake...Repository`'sinden mock veri okumaya devam ediyor. Bu plan sadece görsel dili ve auth/tenant-bağlantı durumunu gerçekleştiriyor.
- Rol/şube context-seçimi ekranı — mobil sadece Üye deneyimi, backend spec'in belirttiği gibi.
- Gerçek SMS/e-posta gönderimi (backend'de soyutlanmış/sahte) — mobil tarafta bunun görünen etkisi yok, sadece "kod gönderildi" ekranı gösterilir.

## Görsel Dil (onaylandı, değişmeyecek)

- Düz, tek katmanlı koyu zemin (`AppColors.background`) — gradient/glow/desen/doku YOK.
- İnce (1px) alt-çizgili form alanları — dolgulu/kutu `TextFormField` görünümü YOK. Odaklanınca alt çizgi `AppColors.primary`'ye döner (1.5px).
- Yeşil (`#8BC34A`) SADECE işlevsel noktalarda: odak çizgisi, birincil buton, seçili durum pill/tab/chip'leri. Ambiyans/dekorasyon amaçlı asla kullanılmaz.
- Hata durumu: alt çizgiler kırmızıya (`AppColors.error`) döner + tek satır düz metin hata (kutu/banner yok).
- Ağ hatası: ince, gölgesiz bir alt şerit (mevcut `SnackBar` kullanımıyla — Dersler/Üyeliğim ekranlarındaki gibi — tutarlı, ayrı bir "toast kartı" bileşeni icat edilmiyor).
- **4 mevcut ekran bu dile taşınıyor:** `Card` widget'ının dolgulu/yuvarlak-köşe görünümü yerine, ince kenarlıklı düz yüzey (`AppColors.surface` zemin + `AppColors.border` 1px kenarlık, dolgu yok/az) kullanılacak şekilde stil güncellenir. **Ekranların verisi/mantığı/provider'ları değişmez** — sadece `Card`/dekorasyon katmanı.

## Mimari Değişiklikler

```
lib/
  core/
    network/
      dio_client.dart        # access token'ı Authorization header'ına ekleyen interceptor eklenir;
                              # 401 alınca otomatik /api/auth/refresh dener, başarısızsa authStateProvider'ı false yapar
      secure_token_store.dart # YENİ — flutter_secure_storage sarmalayıcısı (access+refresh token oku/yaz/sil)
  features/
    auth/
      domain/
        auth_repository.dart      # YENİDEN TASARLANIR — aşağıya bkz.
      data/
        real_auth_repository.dart # YENİ — Dio ile gerçek backend'e bağlanır, FakeAuthRepository silinir
      presentation/
        screens/
          login_screen.dart          # mevcut, sadece gerçek repository'ye bağlanır (görsel zaten onaylı)
          register_screen.dart       # YENİ
          forgot_password_screen.dart # YENİ (kod iste + kodu gir + yeni şifre, tek akış içinde 2 adım)
        providers/
          auth_state_provider.dart   # genişler: sadece bool değil, "giriş yapılmadı / giriş yapıldı, tenant yok / giriş yapıldı, tenant var" gibi 3 durumlu olabilir — bkz. "Router ve Boş Durum"
```

### `AuthRepository` — yeni arayüz

```dart
abstract interface class AuthRepository {
  Future<void> register({required String fullName, required String identifier, required String password});
  Future<void> login({required String identifier, required String password});
  Future<void> logout();
  Future<void> forgotPassword({required String identifier});
  Future<void> resetPassword({required String identifier, required String code, required String newPassword});
  Future<MeResult> getMe(); // profil + aktif Assignment var mı bilgisi
}

sealed class AuthException implements Exception {}
class InvalidCredentialsException extends AuthException {}
class NetworkAuthException extends AuthException {}
// vb. — mockup'ta tasarlanan iki hata durumuna (hatalı kimlik / bağlantı sorunu) birebir karşılık gelir
```

Token'ların kendisi `AuthRepository`'nin dışında, `SecureTokenStore` + `DioClient`'ın interceptor'ı tarafından yönetilir — `login`/`register` başarılı olduğunda dönen token çifti oraya yazılır, ekran/provider katmanı token'ı hiç görmez.

## Router ve Boş Durum

Mevcut `authStateProvider` bool (`false`/`true`) — bunun üstüne bir kavram daha ekleniyor: giriş yapılmış ama `getMe()`'den dönen Assignment listesi boşsa, Home/Classes/Progress/Membership ekranlarının her biri (ya da ortak bir sarmalayıcı widget) **"Henüz aktif üyeliğin yok"** boş-durumunu gösterir — bu bir hata değil, bilgilendirici bir durum (ikon + kısa açıklama, "Bir gym'e üye olduğunda burada göreceksin" gibi bir metin). Router'ın kendisi (`/login` ↔ shell yönlendirmesi) değişmez — sadece giriş yapılmış/yapılmamış ayrımına bakar, tenant durumuna bakmaz; tenant durumunu ekranların kendisi ele alır (ileride gerçek Package/Membership backend'i geldiğinde zaten oradan aynı sinyali okuyacaklar).

## Oturum Kalıcılığı

Access+refresh token `flutter_secure_storage`'da saklanır (iOS'ta Keychain, Android'de EncryptedSharedPreferences/Keystore — paket bunu platform başına otomatik hallediyor, ekstra kod gerekmiyor). Uygulama açılışında (`main.dart` içinde bir başlangıç kontrolü): token varsa sessizce `/api/auth/refresh` denenir; başarılıysa `authStateProvider` `true` ile başlar (kullanıcı login ekranını görmez), başarısızsa (token yok/geçersiz) `false` ile başlar (mevcut davranış).

## Mağaza Yayın Standartları (Android + iOS)

Uygulama gerçek App Store/Play Store'da yayınlanacağı için, self-servis kayıt eklenmesiyle birlikte gelen bir mağaza zorunluluğu var — bkz. backend spec'in "App Store / Play Store Yayın Standartları" bölümü (Apple Guideline 5.1.1(v): hesap oluşturma varsa hesap silme de olmalı).

- **"Hesabımı Sil" — YENİ, Üyeliğim ekranına eklenir** (şu an bir Ayarlar ekranı yok; en yakın/mantıklı yer profil bilgisinin olduğu Üyeliğim). Kırmızı/destructive stilde bir metin butonu (birincil CTA değil — yanlışlıkla basılmaması gereken, geri dönüşü olmayan bir aksiyon), basınca bir onay diyaloğu ("Bu işlem geri alınamaz, emin misin?"), onaylanırsa backend'in `DELETE /api/auth/me`'sini çağırır, başarılıysa token'lar temizlenir ve `/login`'e döner.
- Kayıt ekranında bir "Kullanım Koşulları/Gizlilik Politikası" linki (metin olarak, tıklanabilir) standart mağaza beklentisi — ama gerçek metin/sayfa bu planın kapsamı dışı (backend spec'te de not edildi, ayrı bir hukuki iş). Bu planda sadece link **yeri** ayrılır (gerçek URL geldiğinde tek satır değişir); şimdilik gerçek bir URL yoksa link gösterilmez, tasarım varsayımsal bir yer tutucu içermez.
- `flutter_secure_storage` seçimi zaten platform-native güvenli depolamayı (Keychain/Keystore) kullanıyor — App Store/Play Store'un "kimlik bilgilerini düz metin saklama" beklentisini karşılıyor, ekstra bir iş gerekmiyor.

## Test Stratejisi

Member Experience planındaki desenle aynı: her yeni repository/provider için mocktail ile testler; `SecureTokenStore` gerçek cihaz depolamasına bağlı olduğu için testlerde sahte bir implementasyon enjekte edilir. Yeni ekranların (Register/Forgot Password) keyboard-overflow riski Login'in Task 6 code-quality bulgusuyla aynı şekilde kontrol edilir (Column+Spacer yerine SingleChildScrollView).

## Açık Notlar

- 4 ekranın restyle'ı ile auth wiring'i aynı planda ama bağımsız görevler — restyle görevleri auth'un bitmesini beklemeden paralel/herhangi bir sırada yapılabilir (veri/mantık bağımlılığı yok).
- `_Pill`/`_StatusPill` gibi tekrarlanan pill bileşenlerinin ortak bir widget'a çıkarılması (Member Experience planının Task 14'ünde ertelenmiş bir iyileştirme, bkz. [[project-member-experience-status]]) restyle sırasında doğal bir fırsat — plan yazılırken değerlendirilsin.
