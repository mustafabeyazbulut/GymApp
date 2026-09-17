import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/fake_token_store.dart';
import 'package:gym_app/features/auth/data/real_auth_repository.dart';
import 'package:gym_app/features/auth/domain/auth_exceptions.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late FakeTokenStore tokenStore;
  late RealAuthRepository repository;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
    adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;
    tokenStore = FakeTokenStore();
    repository = RealAuthRepository(dio, tokenStore);
  });

  test('login on success stores the returned token pair', () async {
    adapter.onPost(
      '/api/auth/login',
      (server) => server.reply(200, {
        'accessToken': 'access-1',
        'expiresAtUtc': '2026-09-15T13:00:00Z',
        'refreshToken': 'refresh-1',
      }),
      data: Matchers.any,
    );

    await repository.login(identifier: '+905551112233', password: 'Sifre123!');

    expect(await tokenStore.readAccessToken(), 'access-1');
    expect(await tokenStore.readRefreshToken(), 'refresh-1');
  });

  test('login on 401 throws InvalidCredentialsException', () async {
    adapter.onPost(
      '/api/auth/login',
      (server) => server.reply(401, {
        'Status': 401,
        'Errors': ['Telefon numarası/e-posta veya şifre hatalı.'],
      }),
      data: Matchers.any,
    );

    await expectLater(
      () => repository.login(identifier: '+905551112233', password: 'wrong'),
      throwsA(isA<InvalidCredentialsException>()),
    );
  });

  test('login on connection error throws NetworkAuthException', () async {
    adapter.onPost(
      '/api/auth/login',
      (server) => server.throws(
        0,
        DioException.connectionError(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          reason: 'no internet',
        ),
      ),
      data: Matchers.any,
    );

    await expectLater(
      () => repository.login(identifier: '+905551112233', password: 'Sifre123!'),
      throwsA(isA<NetworkAuthException>()),
    );
  });

  test('logout clears the token store without calling the backend', () async {
    await tokenStore.saveTokens(accessToken: 'a', refreshToken: 'r');

    await repository.logout();

    expect(await tokenStore.readAccessToken(), isNull);
  });

  test('getMe parses the assignments list', () async {
    adapter.onGet(
      '/api/auth/me',
      (server) => server.reply(200, {
        'id': 1,
        'fullName': 'Ayşe Yılmaz',
        'phone': '+905551112233',
        'email': 'ayse@test.com',
        'preferredLanguage': 'tr',
        'isAccountFrozen': false,
        'assignments': [
          {'companyId': 3, 'companyName': 'MAT & MOVE Kadıköy', 'branchId': null, 'role': 'Member'},
        ],
      }),
    );

    final result = await repository.getMe();

    expect(result.hasActiveMembership, isTrue);
    expect(result.assignments.single.companyName, 'MAT & MOVE Kadıköy');
  });

  test('getMe parses a null companyId/companyName without throwing (e.g. a SuperAdmin assignment)', () async {
    adapter.onGet('/api/auth/me', (server) => server.reply(200, {
          'id': 1,
          'fullName': 'Süper Admin',
          'phone': '+900000000000',
          'email': 'admin@gymapp.local',
          'preferredLanguage': 'tr',
          'isAccountFrozen': false,
          'assignments': [
            {'companyId': null, 'companyName': null, 'branchId': null, 'role': 'SuperAdmin'},
          ],
        }));

    final result = await repository.getMe();

    expect(result.assignments.single.companyId, isNull);
    expect(result.assignments.single.companyName, isNull);
  });

  test('login on 429 throws RateLimitedAuthException', () async {
    adapter.onPost('/api/auth/login', (server) => server.reply(429, ''), data: Matchers.any);

    await expectLater(
      () => repository.login(identifier: '+905551112233', password: 'Sifre123!'),
      throwsA(isA<RateLimitedAuthException>()),
    );
  });

  test('requestDeleteAccountOtp calls POST /api/auth/me/delete/request-otp', () async {
    adapter.onPost('/api/auth/me/delete/request-otp', (server) => server.reply(204, null));

    await repository.requestDeleteAccountOtp();
  });

  test('deleteAccount calls DELETE /api/auth/me with the code and clears the token store', () async {
    await tokenStore.saveTokens(accessToken: 'a', refreshToken: 'r');
    adapter.onDelete(
      '/api/auth/me',
      (server) => server.reply(204, null),
      data: {'code': '123456'},
    );

    await repository.deleteAccount(code: '123456');

    expect(await tokenStore.readAccessToken(), isNull);
  });

  test('deleteAccount on 401 surfaces the server message (wrong code, not wrong password)', () async {
    adapter.onDelete(
      '/api/auth/me',
      (server) => server.reply(401, {
        'Status': 401,
        'Errors': ['Telefon kodu hatalı, süresi dolmuş veya çok fazla deneme yapıldı.'],
      }),
      data: {'code': '000000'},
    );

    await expectLater(
      () => repository.deleteAccount(code: '000000'),
      throwsA(isA<GenericAuthException>().having(
        (e) => e.message,
        'message',
        'Telefon kodu hatalı, süresi dolmuş veya çok fazla deneme yapıldı.',
      )),
    );
  });

  test('updatePreferredLanguage calls PATCH /api/auth/me/language with the language', () async {
    adapter.onPatch(
      '/api/auth/me/language',
      (server) => server.reply(204, null),
      data: {'language': 'en'},
    );

    await repository.updatePreferredLanguage('en');
  });

  test('requestFreezeOtp calls POST /api/auth/me/freeze/request-otp', () async {
    adapter.onPost('/api/auth/me/freeze/request-otp', (server) => server.reply(204, null));

    await repository.requestFreezeOtp();
  });

  test('freezeAccount calls POST /api/auth/me/freeze with the code', () async {
    adapter.onPost(
      '/api/auth/me/freeze',
      (server) => server.reply(204, null),
      data: {'code': '123456'},
    );

    await repository.freezeAccount(code: '123456');
  });

  test('freezeAccount on 401 surfaces the server message (wrong code, not wrong password)', () async {
    adapter.onPost(
      '/api/auth/me/freeze',
      (server) => server.reply(401, {
        'Status': 401,
        'Errors': ['Telefon kodu hatalı, süresi dolmuş veya çok fazla deneme yapıldı.'],
      }),
      data: {'code': '000000'},
    );

    await expectLater(
      () => repository.freezeAccount(code: '000000'),
      throwsA(isA<GenericAuthException>().having(
        (e) => e.message,
        'message',
        'Telefon kodu hatalı, süresi dolmuş veya çok fazla deneme yapıldı.',
      )),
    );
  });

  test('requestUnfreezeOtp calls POST /api/auth/me/unfreeze/request-otp', () async {
    adapter.onPost('/api/auth/me/unfreeze/request-otp', (server) => server.reply(204, null));

    await repository.requestUnfreezeOtp();
  });

  test('reactivateAccount calls POST /api/auth/me/unfreeze with the code', () async {
    adapter.onPost(
      '/api/auth/me/unfreeze',
      (server) => server.reply(204, null),
      data: {'code': '123456'},
    );

    await repository.reactivateAccount(code: '123456');
  });
}
