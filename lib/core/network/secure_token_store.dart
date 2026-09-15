import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'token_store.dart';

part 'secure_token_store.g.dart';

/// iOS: Keychain. Android: EncryptedSharedPreferences backed by the
/// platform Keystore. Both handled internally by flutter_secure_storage —
/// no extra platform-specific code needed here.
class SecureTokenStore implements TokenStore {
  SecureTokenStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'gym_app_access_token';
  static const _refreshTokenKey = 'gym_app_refresh_token';

  @override
  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  // flutter_secure_storage has no transactional write/delete API, so a process
  // kill between the two writes (or two deletes) below can leave a mismatched
  // or partial token pair on disk. Consumers must treat a present access token
  // with a missing refresh token as logged-out, not as an error state.
  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}

@riverpod
TokenStore tokenStore(Ref ref) => SecureTokenStore(const FlutterSecureStorage());
