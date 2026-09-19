import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/secure_token_store.dart';
import 'current_user_provider.dart';

part 'auth_state_provider.g.dart';

/// Uygulamanın tab shell'i mi (true) yoksa `/login`'i mi (false) göstereceği.
/// Başlangıçta bu, her zaman false'a sıfırlamak yerine saklanmış bir access
/// token olup olmadığını kontrol eder — gerçek oturumlar artık uygulama
/// başlatmaları arasında kalıcıdır.
@riverpod
class AuthState extends _$AuthState {
  @override
  Future<bool> build() async {
    final store = ref.watch(tokenStoreProvider);
    final accessToken = await store.readAccessToken();
    final refreshToken = await store.readRefreshToken();
    // SecureTokenStore'un kendi belgelenmiş sözleşmesine göre: refresh token
    // eksikken var olan bir access token, kısmi/uyumsuz bir çift anlamına
    // gelir (ör. yazma sırasında sürecin öldürülmesinden), geçerli bir oturum
    // değildir — bu durum çıkış yapılmış gibi ele alınmalıdır.
    return accessToken != null && refreshToken != null;
  }

  void logIn() {
    state = const AsyncData(true);
    // Aynı oturumda farklı bir hesapla art arda giriş yapıldığında (ör.
    // SuperAdmin'den çıkıp GymAdmin'e girmek) currentUserProvider bu geçiş
    // sırasında genellikle en az bir izleyicisini hep koruyor, bu yüzden
    // autoDispose kendiliğinden temizlemiyor - önceki kullanıcının önbelleğe
    // alınmış MeResult'ı (adı, rolleri, SuperAdmin-özel menüler dahil) yeni
    // giriş yapan kullanıcıya gösterilmeye devam ediyordu.
    ref.invalidate(currentUserProvider);
  }

  Future<void> logOut() async {
    await ref.read(tokenStoreProvider).clear();
    state = const AsyncData(false);
    ref.invalidate(currentUserProvider);
  }
}
