---
name: project-login-redirect-token-race-fix
description: "Giriş başarılı ama ana sayfaya yönlendirmiyor" hatasının kök nedeni ve düzeltmesi (2026-09-23) - main.dart'taki currentUserProvider dinleyicisi, /me 401 döngüsü, token silinmesi ve dioProvider keepAlive. main.dart, dio_client.dart veya auth akışına dokunmadan önce oku.
metadata:
  type: project
---

# Giriş sonrası yönlendirmeme hatası (2026-09-23'te bulunup düzeltildi)

Kullanıcı şikayeti: "şifre girişini yapıyor ama yönlendirmiyor diğer sayfaya", ekranda uyarı da çıkmıyor. Backend logunda girişler başarılıydı (RefreshTokens satırı oluşuyordu), ama ardından mobilden hiç yetkili istek gelmiyordu.

## Kök neden (iki katmanlı)

1. **`lib/main.dart`'taki `ref.listen(currentUserProvider)` koşulsuzdu.** `GymApp` widget'ı her rotada (/login dahil) build edildiği için `currentUserProvider` giriş ekranında da canlı kalıyordu. Token yokken `/api/auth/me` 401 dönüyor, Riverpod 3'ün otomatik retry'ı provider'ı giderek uzayan aralıklarla (~6.4 sn'ye kadar) sonsuza kadar yeniden deniyordu. Her 401'de `dio_client.dart`'taki auth interceptor refresh token bulamayıp `tokenStore.clear()` çağırıyordu. Kullanıcı tam o sırada giriş yapınca yeni kaydedilen token bu `clear()` ile siliniyor, token'sız giden `/me` `SessionExpiredException` üretiyor ve listener `logOut()` ile kullanıcıyı tekrar /login'e atıyordu. Sessiz kalmasının sebebi: bu bir hata değil, "oturum bitti" olarak işleniyordu.
2. **Birinci düzeltme ikinci bir gizli hatayı açığa çıkardı:** `dioProvider` autoDispose'du ve onu canlı tutan tek şey o koşulsuz listener zinciriydi (`currentUserProvider → authRepositoryProvider → dioProvider`). Listener kalkınca /login ekranında `login()` sırasında provider dispose ediliyor, interceptor içindeki `ref.read(activeStaffCompanyIdProvider)` "dispose edilmiş Ref" hatası fırlatıyordu. Dio bunu yanıtsız bir `DioException`'a çevirdiği için ekranda sunucuya hiç gitmeyen bir "Couldn't connect" hatası görünüyordu.

## Düzeltme

- `main.dart`: listener artık `if (isAuthenticated)` içinde kuruluyor (`isAuthenticated = ref.watch(authStateProvider).value ?? false`). `ConsumerWidget` her build'de dinleyicilerini kapatıp yeniden kurduğu için koşullu `ref.listen` güvenli (flutter_riverpod 3.4.3 kaynağında `consumer.dart` build() içinde `_listeners` temizleniyor - doğrulandı).
- `dioProvider` ve `tokenStoreProvider`: `@Riverpod(keepAlive: true)`. Dio'nun interceptor'ları provider'ın kendi `ref`'ini kullandığı için autoDispose olmamalı, zaten uygulama genelinde tek örnek.

## Doğrulama

Web'de (flutter web-server + Playwright) canlı test edildi: /login'de API'ye sıfır istek, giriş → `/me 200` → `/home`; çıkış → tek bir `/me 401` sonra sessizlik; tekrar giriş → `/home`. `flutter analyze` temiz, 206/206 test geçti.

## Ders

- Uygulama kökünde (`GymApp.build`) kurulan bir `ref.listen`/`ref.watch`, bir autoDispose provider zincirini (dio dahil) HER rotada canlı tutar. Böyle bir dinleyiciyi kaldırırken veya koşullu yaparken, zincirdeki provider'ların (özellikle `ref`'i closure içinde kullananların) dinleyicisiz kalınca dispose olup olmayacağını kontrol et.
- Bu hatanın bir önceki "düzeltmesi" (commit `d7270b9`, logOut'u `wasAuthenticated` kontrolüyle sınırlamak) sonsuz logOut döngüsünü kırmıştı ama `/me` retry döngüsünü ve token silme yarışını kırmamıştı.
