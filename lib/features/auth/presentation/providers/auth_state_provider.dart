import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/secure_token_store.dart';

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

  void logIn() => state = const AsyncData(true);

  Future<void> logOut() async {
    await ref.read(tokenStoreProvider).clear();
    state = const AsyncData(false);
  }
}
