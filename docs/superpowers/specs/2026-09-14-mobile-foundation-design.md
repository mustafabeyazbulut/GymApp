# Mobile Foundation — Tasarım

## Genel Bakış

GymApp Flutter mobil uygulamasının ilk aşaması: proje iskeleti, mimari
kurulum (state management, routing, API client), localization altyapısı ve
backend'in şu an çalışan tek gerçek özelliğini (Branch create/list) gösteren
bir ispat ekranı. Bu, backend tarafında uygulanan "Backend Foundation"
planının mobil karşılığıdır — aynı prensip: önce iskeleti ve mimariyi tek bir
gerçek özellik üzerinden uçtan uca kanıtla, sonra üzerine inşa et.

Ürünün tam kapsamı `C:\Users\MBEYAZBULUT\Desktop\GymAppApi\2026-09-09-gym-yonetim-sistemi-design.md`
dosyasında tanımlıdır (roller, paket modeli, veri modeli, Faz 1/Faz 2
ayrımı). Bu spec o dokümanı tekrar etmez, sadece mobil tarafın **ilk**
diliminin (Mobile Foundation) teknik tasarımını içerir.

## Neden bu kapsamda başlıyoruz

Backend'de şu an sadece kimlik doğrulamasız `GET/POST /api/branches`
endpoint'i çalışıyor (bkz. `docs/mobile-api/README.md` backend reposunda).
Auth (telefon+şifre+SMS OTP, JWT, context/rol seçimi) backend'de henüz
yapılmadı. Bu yüzden mobilde login ekranından başlamak şu an anlamsız
olur — bağlanacağı gerçek bir API yok. Bunun yerine mimariyi ve görsel
tasarım sistemini, backend'in gerçekten desteklediği tek özellik (Branch)
üzerinden kuruyoruz. Auth, Dersler, Gelişimim, Üyeliğim ekranları bu planın
**kapsamı dışında** — kendi backend'leri hazır olduğunda ayrı planlarla
gelecekler.

## Mimari

```
lib/
  core/
    theme/           # AppTheme, renkler, tipografi (tek merkezi tanım)
    router/           # go_router konfigürasyonu
    network/          # Dio client, interceptor'lar, ApiException
    l10n/              # (generated) flutter_localizations çıktısı
  features/
    branches/
      data/            # BranchRepository (Dio çağrıları), DTO'lar
      domain/          # Branch modeli, repository arayüzü
      presentation/    # Ekranlar, Riverpod provider'lar, widget'lar
main.dart
l10n.yaml
```

**Neden feature-first:** Backend'deki `Features/<Feature>/{Commands,Queries}`
vertical-slice deseninin mobil karşılığı. Her feature kendi
data/domain/presentation katmanlarını taşır — bir feature'a bakan biri o
feature'ın tamamını (network çağrısından ekrana kadar) tek klasörde bulur.
Yeni bir feature (ör. Dersler) eklenirken mevcut feature'lara dokunulmaz.

### State Management: Riverpod

`flutter_riverpod` + `riverpod_generator` (code-gen ile `@riverpod`
annotation'ları). Gerekçe: tip güvenliği (compile-time hata yakalama),
test edilebilirlik (provider'lar override edilebilir), ve DI'ı da çözer —
ayrı bir dependency injection kütüphanesi gerekmez (Dio client, repository'ler
provider olarak sağlanır).

### Routing: go_router

Deep-link desteği ve ileride rol bazlı yönlendirme (ör. Super Admin'in
"Yeni Firma Ekle" ekranına, normal kullanıcının ana ekrana yönlendirilmesi)
için Flutter ekibinin resmi önerdiği çözüm. Bu planda sadece tek bir route
(Branch listesi) tanımlanır; router yapısı ileride auth/rol guard'ları
eklemeye hazır şekilde kurulur ama guard'ların kendisi bu planın kapsamında
değildir (auth yok).

### API Client: Dio

- Base URL, platforma göre farklı (Android emulator'de host makineye
  `10.0.2.2` üzerinden erişilir, gerçek loopback `localhost` değildir;
  Chrome'da `localhost` çalışır) — `core/network/api_config.dart`'ta
  `Platform.isAndroid` kontrolüyle çözülür.
- Backend'in `ExceptionMiddleware`'i her hatayı `{"status": int, "errors":
  string[]}` şeklinde döndürüyor (bkz. GymAppApi
  `Presentation/GymAppApi.WebApi/Middleware/ExceptionMiddleware.cs`) — Dio
  interceptor bu şekli merkezi olarak `ApiException(status, errors)`'a
  çevirir, her repository bunu tekrar parse etmez.
- Auth token enjeksiyonu bu planda yok (auth henüz yok); interceptor zinciri
  ileride token eklemeye hazır şekilde kurulur (boş bir `AuthInterceptor`
  yer tutucu olarak eklenmez — YAGNI, gerçekten auth planı geldiğinde
  eklenir).

### Localization

`flutter_localizations` + ARB dosyaları (`lib/l10n/app_tr.arb` başlangıç,
`app_en.arb` iskelet/boş) — tasarım dokümanındaki karara birebir uyumlu:
hiçbir ekranda sabit metin kullanılmaz, en baştan `AppLocalizations` üzerinden
çevrilir.

## Görsel Tasarım Sistemi

Kullanıcının paylaştığı ekran görüntüsünden (geçici marka adı "MAT & MOVE")
çıkarılan koyu tema, marka rengi netleşene kadar placeholder olarak kullanılır
— tek `AppTheme` dosyasında tanımlı, değiştirmek tek satır:

| Token | Yaklaşık değer | Kullanım |
|---|---|---|
| `background` | `#0D0D0F` | Ana arka plan |
| `surface` | `#1A1A1D` | Kart, panel yüzeyleri |
| `primary` (accent) | `#C6FF3D` | Birincil aksiyon butonları, aktif sekme/nav ikonu |
| `secondary` (accent) | teal/camgöbeği tonu | İkincil vurgular (ileride Gelişimim grafiklerinde) |
| `onBackground` / `onSurface` | beyaz/gri tonları | Metin |

Bileşen stili: yuvarlak köşeli kartlar, alt navigasyon bar (bottom nav),
büyük dokunma alanlı birincil butonlar (lime zemin, koyu metin — kontrast
için). Bu planda sadece Branch listesi/ekleme ekranı bu temayla giydirilir;
Dersler/Gelişimim/Üyeliğim gibi diğer ekranlardaki spesifik bileşenler
(radyal grafik, tarih seçici vb.) o ekranların kendi planlarında ele alınır.

**Kalite çıtası (bkz. [[feedback-design-quality-bar]] proje memory'si — kullanıcının
açık talebi):** Referans mockup'ın renk paletini kopyalamak yetmez; **zanaat
seviyesi** de birebir aynı olmalı. Bu, "proof of concept" olan Branch ekranı
için de geçerlidir — mimari kanıtlama amaçlı olması, görsel olarak taslak
kalitede olabileceği anlamına gelmez. Somut karşılıkları:

- **Kartlar:** `12–16px` köşe yarıçapı, hafif derinlik (subtle shadow/elevation,
  düz/flat değil), cömert iç padding (`16px`+), kart içi hiyerarşi (başlık —
  yardımcı metin — aksiyon) net ayrılmış.
- **Tipografi:** Tek bir Google Fonts ailesi (ör. Inter/Manrope — mockup'taki
  gibi modern, geometrik bir sans-serif; kesin seçim ilk ekran implementasyonunda
  yapılır) ile ağırlık hiyerarşisi kurulur (başlıklar semibold/bold, gövde metni
  regular, yardımcı metin daha düşük opaklıkta gri) — Flutter'ın stok Material
  tipografisi (Roboto varsayılanı) kullanılmaz.
- **İkonlar:** Tek bir tutarlı ikon seti (ör. `phosphor_flutter` veya
  `heroicons` gibi outline/duotone bir paket — mockup'taki ince çizgili
  ikonlara yakın); farklı ekranlarda farklı ikon stillerinin karışması
  (bazısı Material filled, bazısı outline) kabul edilmez.
- **Butonlar/CTA:** Birincil aksiyon = dolu lime zemin + koyu (neredeyse
  siyah) metin, `12px+` köşe yarıçapı, belirgin dokunma alanı (min `48px`
  yükseklik). İkincil aksiyon = outline veya düşük opaklıklı koyu zemin.
- **Rozet/etiket (badge/pill):** Durum etiketleri (ör. "Aktif") küçük,
  yuvarlak köşeli, düşük-opaklık renkli zemin üzerinde kısa metin —
  mockup'taki "Aktif" rozetiyle aynı desende.
- **Alt navigasyon:** İkon + kısa etiket, aktif sekme lime renkle vurgulanır,
  pasif sekmeler soluk gri; mockup'taki 4 sekmeli (Ana Sayfa/Dersler/
  Gelişimim/Profil benzeri) yapı bu planda henüz tek route olsa da, nav bar
  bileşeninin kendisi bu kaliteyle kurulur (ileride yeni route eklemek sadece
  yeni bir `NavigationDestination` eklemek olmalı).
- **Boşluk ritmi (spacing):** Rastgele padding/margin değerleri yerine
  `AppTheme`/`AppSpacing` içinde tanımlı sabit bir ölçek (ör. 4/8/12/16/24/32)
  kullanılır — mockup'taki düzenli, nefes alan yerleşimin kaynağı budur.

Bu madde, ilgili implementasyon planındaki her UI task'ının code-quality
review adımında (fonksiyonel doğruluğun yanında) açıkça kontrol edilmelidir —
"çalışıyor ama taslak görünüyor" bir ekran tamamlanmış sayılmaz.

## İlk Ekran: Branch Listesi (proof-of-concept)

- Şube listesi: `GET /api/branches` → kart listesi (isim, adres, aktif/pasif
  durumu)
- Yeni şube ekle: basit form (CompanyId, Name, Address) → `POST
  /api/branches` → başarılıysa listeye eklenir; backend'in
  `CompanyNotFoundException`'ı (404) ve FluentValidation hataları (422)
  kullanıcıya `ApiException.errors` üzerinden gösterilir
- Bu ekran gerçek bir ürün özelliği değil — backend Task 12'deki gibi,
  sadece mimarinin uçtan uca (UI → Riverpod → Dio → gerçek Postgres →
  ExceptionMiddleware) çalıştığını kanıtlamak için var. Gerçek "Yeni Firma/
  Şube Ekle" akışı ileride Tenant Onboarding planıyla gelecek.

## Platform ve Ortam

- **Yerel geliştirme/test:** Android emulator (bu makinede birden fazla
  hazır AVD var: `Cnc_Tablet_8in`, `pixel_2_pie_9_0_-_api_28`,
  `pixel_5_-_api_33`) + Chrome (hızlı iterasyon için).
- **iOS:** Bu makinede Mac/Xcode olmadığı için test edilemez; ileride CI
  (Codemagic/Fastlane, bkz. ürün tasarım dokümanındaki "CI/CD ve Dağıtım"
  bölümü) veya bir Mac ile eklenir. Bu plan iOS'u derlemeye/imzalamaya
  çalışmaz.
- **Backend bağlantısı (yerel geliştirme):** GymAppApi `dotnet run` ile
  `http://localhost:5195`'te çalışıyor (bkz. GymAppApi progress memory).
  Android emulator'den bu adrese `10.0.2.2:5195` üzerinden erişilir.

## Repo

`C:\Users\MBEYAZBULUT\Desktop\GymApp` — GymAppApi'den bağımsız, ayrı git
reposu (bu spec'in yazıldığı commit ile başlar). Kullanıcı bu repoyu bir
remote'a (GitHub vb.) aktarıp oradan devam edecek; bu yüzden repo içi
dokümantasyon (bu spec + proje memory) kendi başına anlaşılır ve backend
reposuna mutlak Windows yollarıyla referans verir (iki repo ayrı
makineler/session'lar arasında taşınabileceği için, mümkün olduğunca
bağlamı kendi içinde taşır).

## Kapsam Dışı (bu plan için)

- Auth/JWT/OTP, rol bazlı yönlendirme guard'ları
- Dersler, Gelişimim, Üyeliğim ve diğer Faz 2 ekranları (backend'leri yok)
- iOS build/imzalama
- Gerçek marka renkleri/logo (placeholder kullanılıyor)
- Push notification (FCM) entegrasyonu
- Offline/cache stratejisi

## Test Stratejisi

Backend'deki TDD disiplini mobilde de korunur: `BranchRepository` ve
Riverpod provider'ları için widget/unit testler (`flutter_test` +
`mocktail` ile Dio mock'lanır) — gerçek network çağrısı yapılmadan,
backend'in döndüğü JSON şekline göre.
