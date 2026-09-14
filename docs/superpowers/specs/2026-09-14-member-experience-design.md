# Member Experience (Mock Data) — Tasarım

## Genel Bakış

GymApp Flutter uygulamasının, kullanıcının paylaştığı "MAT & MOVE" referans mockup'ındaki 5 ekranını (Giriş, Ana Sayfa, Dersler, Gelişimim, Üyeliğim) **gerçek backend olmadan, sahte (mock/local) veriyle** inşa etmesi. Bu, `docs/superpowers/plans/2026-09-14-mobile-foundation.md` planının (mimari iskelet + tek gerçek-backend'li Branch ekranı) üzerine gelen, o planı tamamlayıcı değil **onun yerini alan** bir sonraki adım — kullanıcı Branch ekranını beğenmedi ve gerçek ürün deneyimini görmek istediğini açıkça belirtti.

Görsel tasarım, bir tarayıcı tabanlı brainstorming aracıyla (superpowers visual companion) iteratif olarak kullanıcıyla birlikte netleştirildi (v1 → v2 → v3, kullanıcı onayı: v3). Bu spec o onaylanmış v3 tasarımını teknik bir uygulamaya çevirir.

## Neden bu kapsam

Backend (GymAppApi) şu an sadece unauthenticated `GET/POST /api/branches` endpoint'ine sahip; Auth, Paket/Üyelik, Ders Programı, Gelişim Takibi modüllerinin hiçbiri yok. Kullanıcı, "önce mimariyi kanıtla, ekranları backend'e göre kademeli ekle" stratejisinden memnun kalmadı — gerçek ürünü şimdi görmek istiyor. Bu yüzden: her ekran için gerçek domain modelleri + repository arayüzü tanımlanır, ama şimdilik sabit/mock veri döndüren bir `Fake...Repository` implementasyonu kullanılır (Branch feature'ının `domain/data/presentation` deseniyle birebir aynı). Backend'ler hazır olduğunda sadece repository implementasyonu değişecek; ekranlar/provider'lar dokunulmadan kalacak.

## Kapsam Dışı (bu plan için)

- **Branch feature'ı komple kaldırılıyor** — `lib/features/branches/`, `test/features/branches/`, router'daki `/branches`, `/branches/new` route'ları, `lib/core/widgets/app_shell.dart`'ın eski hâli. Kullanıcı: "önce ana tasarımı çıkaralım daha sonra onu nereye koyacağımıza karar veririz ama tasarım o olamaz, sil bence." Şube/admin yönetimi konusu ayrı, gelecekteki bir işe bırakılıyor.
- Gerçek kimlik doğrulama (JWT/OTP/backend çağrısı) — giriş tamamen sahte, herhangi bir değerle başarılı sayılır.
- Oturum kalıcılığı — uygulama her açılışta Giriş ekranıyla başlar (kullanıcı seçimi).
- Gerçek fotoğraf/medya içeriği — görsel dil ikon + gradient kart yüzeyleriyle çözüldü (rastgele stok fotoğraf servisleri kullanıcı tarafından reddedildi, alakasız/tutarsız görsel döndürüyorlardı).
- Çizgi/alan grafikleri (mockup'ın orijinalinde olan "Devam Grafiği" çizgi grafiği v3'te sadeleştirme sürecinde kaldırıldı, kullanıcı onayladı) — sadece basit çubuk grafik (haftalık devam) ve donut/dairesel gösterge (gelişim yüzdeleri) var.
- iOS build/imzalama, push notification, offline/cache — Mobile Foundation'daki mevcut kapsam dışı kararlar geçerliliğini koruyor.
- Web platformu birincil hedef değil ama artık kurulu (`flutter run -d chrome`/`-d web-server` çalışıyor, Mobile Foundation'ın Task 10'unda eklendi) — otomatik smoke testler için kullanılabilir.

## Mimari

```
lib/
  core/
    theme/            # AppColors güncelleniyor (bkz. Görsel Tasarım), diğerleri sabit
    network/          # dokunulmuyor (kullanılmıyor ama silinmiyor — Dio/ApiException altyapısı gelecekte gerçek backend'e geçişte kullanılacak)
    router/
      app_router.dart # baştan yazılıyor: /login + StatefulShellRoute (4 sekme)
    widgets/
      app_shell.dart  # baştan yazılıyor: gerçek 4 sekmeli NavigationBar (artık >=2 destination var, önceki çökme sorunu doğal olarak çözülüyor)
  features/
    auth/
      domain/          # AuthRepository arayüzü
      data/            # FakeAuthRepository (in-memory bool state)
      presentation/    # LoginScreen + authStateProvider
    home/
      domain/          # HomeSummary modeli
      data/            # FakeHomeRepository
      presentation/    # HomeScreen (Ana Sayfa)
    classes/
      domain/          # ClassSession modeli, ClassRepository arayüzü
      data/            # FakeClassRepository (in-memory liste, reserveSpot mutasyonu)
      presentation/    # ClassesScreen (Dersler)
    progress/
      domain/          # ProgressSummary, TrainerNote modelleri
      data/            # FakeProgressRepository
      presentation/    # ProgressScreen (Gelişimim)
    membership/
      domain/          # MembershipInfo, PaymentHistoryEntry modelleri
      data/            # FakeMembershipRepository (requestFreeze/renew mutasyonları)
      presentation/    # MembershipScreen (Üyeliğim)
  l10n/                # yeni ARB anahtarları eklenecek (mevcut branch anahtarları kaldırılacak)
```

**Neden 5 ayrı feature (tek "member_experience" yerine):** Her ekranın kendi domain modeli, repository'si ve state'i var — birbirinden bağımsız okunabilir/test edilebilir. Branch feature'ındaki desenin doğrudan devamı. Ortak hiçbir iş mantığı olmadığından (sadece ortak UI bileşenleri — kart, pill, nav — `core/widgets`'ta kalır) tek bir mega-feature'a sıkıştırmak sınırları bulanıklaştırır.

### State Management & Mock Veri

Her feature: `abstract interface class XRepository` (domain) + `class FakeXRepository implements XRepository` (data, sabit başlangıç verisiyle kurulur, mutasyon metodları in-memory state'i değiştirir) + Riverpod `@riverpod` provider'lar (Branch'teki `branchRepositoryProvider`/`branchListProvider` deseniyle birebir aynı — `AsyncNotifier` üzerinden yükleme, `ref.read(...).mutateSomething()` üzerinden yazma).

`FakeClassRepository.reserveSpot(classId)` gibi mutasyon metodları gerçekçi olması için küçük bir yapay gecikme (`await Future.delayed(...)`) içerir — böylece UI'daki loading state'ler (buton spinner'ı vb.) gerçek bir API çağrısıymış gibi test edilebilir.

### Kimlik Doğrulama (sahte)

`authStateProvider` (basit `@riverpod` bool state, `Riverpod`'un `Notifier` sınıfıyla) — `FakeAuthRepository.login(identifier, password)` her zaman başarılı döner (yapay gecikmeyle), `authStateProvider`'ı `true` yapar. `app_router.dart`'ta `GoRouter`'ın `redirect` callback'i bu provider'ı dinler: `false` iken `/login` dışındaki her route'u `/login`'e yönlendirir, `true` iken `/login`'e gidilmeye çalışılırsa ana sekmeye yönlendirir. Kalıcılık yok (state sadece `ProviderScope` ömrü boyunca yaşar, uygulama yeniden başlatılınca sıfırlanır) — kullanıcının seçimi.

### Navigasyon

`StatefulShellRoute.indexedStack` (go_router) ile 4 sekme: Ana Sayfa, Dersler, Gelişimim, Üyeliğim — her sekme kendi navigasyon geçmişini/state'ini korur. `AppShell` artık gerçek 4 `NavigationDestination`'a sahip (Mobile Foundation'daki tek-sekme `NavigationBar` çökmesi burada doğal olarak ortadan kalkıyor, çünkü Flutter'ın `>=2` şartı karşılanıyor). `/login` bu shell'in dışında, ayrı bir route.

## Görsel Tasarım Sistemi — Güncellemeler

Brainstorming'de görsel companion ile netleşen, mevcut `AppColors`/`AppTypography`'de **değişiklik gerektiren** kararlar (Task 2'deki temel yapı — spacing skalası, kart border/radius yaklaşımı, input/buton teması — aynen korunuyor):

- **`AppColors.primary` değişiyor: `#C6FF3D` → `#8BC34A`.** Kullanıcı orijinal floresan lime'ı "çok cırtlak" ve "göz yoruyor" olarak reddetti; brainstorming'de test edilen daha dingin, orta tonlu bir yeşile (`#8BC34A`) karar verildi. Bu token'a bağlı her yer (butonlar, aktif nav ikonu, aktif tab/date-pill/chip, pill rozetleri, grafik vurgu rengi) otomatik güncellenir — tek dosya değişikliği. `onPrimary` (`#0D0D0F`, koyu metin) aynı kalıyor, yeni yeşille kontrastı yeterli.
- **Yeşil zeminli metinler için font ağırlığı: `w800` değil `w600`.** Kullanıcı butonlardaki aşırı kalın metni okunaksız buldu. Mevcut `AppTypography.labelLarge` zaten `w600` (Task 2'den) — bu zaten doğruydu, yeni eklenen tab/date-pill/chip aktif durumları da aynı `labelLarge` stilini kullanmalı, kendi başına `w800` tanımlamamalı.
- **Fotoğraf/gerçek görsel yok.** Kart yüzeyleri düz `AppColors.surface` (`#16161a` civarı — mevcut token) + ince border; "hero" kartlar (Ana Sayfa karşılama, Üyeliğim paket özeti) fotoğraf değil, düz kart + metin.
- **İkonlar:** Flutter'ın kendi `Icons` seti (outlined/rounded ikili deseni, Mobile Foundation'daki kararla tutarlı — üçüncü parti ikon paketi yok). Kuşak/başarı rozeti için `Icons.military_tech_outlined` (mockup'taki özel kurdele şekli yerine, mevcut Material ikon setinden en yakın karşılık).
- **Bottom nav:** Yüzen, yuvarlak köşeli bar (mevcut `Scaffold.bottomNavigationBar` yerine `Padding` içine alınmış, `BorderRadius` verilmiş bir `NavigationBar` — ya da eşdeğer özel widget), aktif sekmede ikonun arkasında dolu yeşil pill highlight'ı.
- **Donut/dairesel gösterge (Gelişimim'deki 3 yüzde):** Flutter'da hazır widget yok — küçük bir `CustomPainter` (`CircularStatGauge` gibi, `Canvas.drawArc` ile) yazılacak. Basit, tek sorumluluklu, parametreleri: `value (0-1)`, `color`, `label`.
- **Haftalık devam çubuk grafiği (Ana Sayfa):** Özel paket gerekmiyor — sabit yükseklik oranlarına sahip `Container`'ların bir `Row` içinde dizilmesiyle yapılabilir (custom painter bile gerekmez).

## Ekranlar

### 0. Giriş (`/login`)

- Koyu zemin üzerine hafif bir radial-gradient glow (marka rengiyle, çok düşük opaklık) — düz `AppColors.background` yerine.
- Marka işareti (küçük döndürülmüş kare) + "MAT & MOVE" wordmark, "Tekrar hoş geldin" başlığı, alt metin.
- Telefon/e-posta + şifre `TextFormField`'ları (mevcut `InputDecorationTheme`), "Giriş Yap" birincil buton (yapay gecikmeyle, spinner gösterir), "Şifremi unuttum" (bu akışta işlevsiz, sadece metin — Faz 1 kapsamı dışı, tıklanamaz görünür).
- Herhangi bir dolu (boş olmayan) değerle giriş başarılı sayılır; boşsa `TextFormField` validasyonu "Bu alan zorunludur" gösterir (mevcut ARB anahtarı yeniden kullanılabilir).

### 1. Ana Sayfa (`/` içinde ilk sekme)

- Üst bar: marka + bildirim zili (işlevsiz, sadece görsel).
- Karşılama: "Merhaba, {isim}" + alt metin (mock kullanıcı adı sabit, ör. "Elnara").
- "Aktif Paketin" kartı: paket adı + "N gün kaldı" pill.
- "Sıradaki Ders" kartı: ders adı, saat, eğitmen.
- İki buton: "Rezervasyon" (Dersler sekmesine geçer) / "Giriş Yap" (işlevsiz, Faz 2 kapı erişimi placeholder'ı — sadece görsel, dokunca hiçbir şey olmaz).
- "Bu Hafta Devam" kartı: "N/7 ders" + 7 günlük çubuk grafik (sabit mock veri).

### 2. Dersler (`/classes`)

- Tarih şeridi (bir haftalık, sabit 5-7 gün, biri seçili) — seçim state'i tutulur ama farklı günler için farklı mock veri seti YOK (basitlik için: hangi gün seçilirse seçilsin aynı sabit ders listesi gösterilir; bu bilinçli bir basitleştirme, spec'te açıkça belirtiliyor ki implementasyon sırasında "eksik" sanılmasın).
- Filtre chip'leri: Tümü/BJJ/Fitness — gerçekten filtreler (client-side, mock listeyi süzer).
- Ders kartları: ad, kategori pill, saat, eğitmen, doluluk ("8/12 kişi"), "Yer Ayır" birincil buton (dolu değilse) / "Bekleme Listesi" ikincil buton (doluysa, `enrolled == capacity`).
- "Yer Ayır"a basınca: `FakeClassRepository`'de o dersin `enrolledCount`'u 1 artar, buton anlık "Rezerve Edildi" durumuna döner (devre dışı, farklı stil) — bellekte kalıcı, ekrandan çıkıp geri dönünce hâlâ rezerve görünür (aynı `ProviderScope` ömrü boyunca).

### 3. Gelişimim (`/progress`)

- BJJ/Fitness toggle (iki sabit mock veri seti arasında geçiş).
- Kuşak kartı: ikon (`Icons.military_tech_outlined`) + "Beyaz Kuşak · 2. derece" + alıntı metni.
- "Bu Ay" kartı: "N ders".
- 3 donut gösterge: Teknikler / Devamlılık / Kondisyon, her biri yüzde + etiket.
- "Son Eğitmen Notu" kartı: not metni + eğitmen adı + tarih.

### 4. Üyeliğim (`/membership`)

- Paket özeti kartı: paket adı + "Aktif" pill, başlangıç-bitiş tarihi, tutar + "Ödendi" pill.
- "Üyeliği Yenile" birincil buton (işlevsiz mock — dokunca bir SnackBar ile "Yenileme talebi alındı" gösterir, gerçek bir ödeme akışı yok).
- "Dondurma Talebi" ikincil buton — dokunca `FakeMembershipRepository.requestFreeze()` çağrılır, paket kartındaki "Aktif" pill'i "Donduruldu"ya döner (basit, tek adımlı mock — gerçek dondurma süresi/limit mantığı yok, sadece durum değişimini göstermek için).
- "Ödeme Geçmişi" kartı: sabit 3 satırlık liste (tarih + tutar).

## Test Stratejisi

Branch feature'ındaki desenle aynı: her `Fake...Repository` ve provider için `mocktail` ile (repository arayüzünü mock'layarak) Riverpod provider testleri — `flutter_test` + `ProviderContainer`. UI ekranları için ayrı widget testi zorunlu değil (Mobile Foundation'da da yapılmadı, sadece provider/repository katmanı test edildi, ekranlar plan'ın son adımında manuel smoke test'le doğrulandı — aynı desen burada da geçerli).

## Lokalizasyon

Yeni ARB anahtarları eklenir (branch'e özel anahtarlar — `branchesTitle`, `branchAddButton` vb. — kaldırılır, artık kullanılmıyor). Tüm yeni metinler `AppLocalizations` üzerinden, hiçbir ekranda sabit string yok (mevcut proje kuralı).
