import 'token_store.dart';

/// Testler için bellek içi (in-memory) TokenStore — gerçek uygulamada asla
/// kullanılmaz (gerçek Keychain/Keystore destekli implementasyon için
/// SecureTokenStore'a bakın).
class FakeTokenStore implements TokenStore {
  String? _accessToken;
  String? _refreshToken;

  @override
  Future<String?> readAccessToken() async => _accessToken;

  @override
  Future<String?> readRefreshToken() async => _refreshToken;

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  @override
  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
  }
}
