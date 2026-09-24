import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'token_store.dart';

part 'secure_token_store.g.dart';

/// iOS: Keychain. Android: platform Keystore tarafından desteklenen
/// EncryptedSharedPreferences. Her ikisi de flutter_secure_storage
/// tarafından dahili olarak yönetilir — burada ekstra platforma özgü
/// koda gerek yoktur.
class SecureTokenStore implements TokenStore {
  SecureTokenStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'gym_app_access_token';
  static const _refreshTokenKey = 'gym_app_refresh_token';

  @override
  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  // flutter_secure_storage'ın işlemsel (transactional) bir yazma/silme API'si
  // yoktur, bu yüzden aşağıdaki iki yazma (veya iki silme) arasında sürecin
  // öldürülmesi diskte uyumsuz veya eksik bir token çifti bırakabilir.
  // Kullanan taraflar, refresh token eksikken var olan bir access token'ı
  // bir hata durumu olarak değil, çıkış yapılmış olarak ele almalıdır.
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

// keepAlive: keepAlive olan dioProvider bunu watch ediyor.
@Riverpod(keepAlive: true)
TokenStore tokenStore(Ref ref) => SecureTokenStore(const FlutterSecureStorage());
