import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/secure_token_store.dart';
import 'package:mocktail/mocktail.dart';

class _MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockFlutterSecureStorage storage;
  late SecureTokenStore tokenStore;

  setUp(() {
    storage = _MockFlutterSecureStorage();
    tokenStore = SecureTokenStore(storage);
  });

  test('saveTokens writes both values under their keys', () async {
    when(() => storage.write(key: any(named: 'key'), value: any(named: 'value'))).thenAnswer((_) async {});

    await tokenStore.saveTokens(accessToken: 'access-1', refreshToken: 'refresh-1');

    verify(() => storage.write(key: 'gym_app_access_token', value: 'access-1')).called(1);
    verify(() => storage.write(key: 'gym_app_refresh_token', value: 'refresh-1')).called(1);
  });

  test('readAccessToken reads the access-token key', () async {
    when(() => storage.read(key: 'gym_app_access_token')).thenAnswer((_) async => 'stored-access');

    final result = await tokenStore.readAccessToken();

    expect(result, 'stored-access');
  });

  test('clear deletes both keys', () async {
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((_) async {});

    await tokenStore.clear();

    verify(() => storage.delete(key: 'gym_app_access_token')).called(1);
    verify(() => storage.delete(key: 'gym_app_refresh_token')).called(1);
  });
}
