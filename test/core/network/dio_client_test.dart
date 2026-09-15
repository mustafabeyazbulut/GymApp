import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/fake_token_store.dart';
import 'package:gym_app/core/network/dio_client.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late FakeTokenStore tokenStore;

  setUp(() async {
    tokenStore = FakeTokenStore();
    await tokenStore.saveTokens(
      accessToken: 'expired-access',
      refreshToken: 'valid-refresh',
    );

    dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
    adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;

    addAuthInterceptor(dio, tokenStore);
  });

  test('attaches the stored access token as a Bearer header', () async {
    adapter.onGet(
      '/api/protected',
      (server) => server.reply(200, {'ok': true}),
      headers: {'Authorization': 'Bearer expired-access'},
    );

    final response = await dio.get('/api/protected');

    expect(response.statusCode, 200);
  });

  test('on 401, silently refreshes and retries once with the new token', () async {
    // http_mock_adapter evaluates an onGet/onPost callback once, synchronously,
    // at registration time (it is not re-invoked per matching request), so a
    // single route can't branch its response on a mutable call counter. Two
    // registrations of the same route, distinguished by the Authorization
    // header actually sent (stale on the first call, refreshed on the retry),
    // give each phase its own fixed response while still counting real calls
    // via replyCallback, which IS invoked per matching request.
    var attempt = 0;
    adapter.onGet(
      '/api/protected',
      (server) => server.replyCallback(401, (options) {
        attempt += 1;
        return {
          'Status': 401,
          'Errors': ['expired'],
        };
      }),
      headers: {'Authorization': 'Bearer expired-access'},
    );
    adapter.onGet(
      '/api/protected',
      (server) => server.replyCallback(200, (options) {
        attempt += 1;
        return {'ok': true};
      }),
      headers: {'Authorization': 'Bearer fresh-access'},
    );
    adapter.onPost(
      '/api/auth/refresh',
      (server) => server.reply(200, {
        'accessToken': 'fresh-access',
        'expiresAtUtc': DateTime.now().toIso8601String(),
        'refreshToken': 'fresh-refresh',
      }),
      data: Matchers.any,
    );

    final response = await dio.get('/api/protected');

    expect(response.statusCode, 200);
    expect(attempt, 2);
    expect(await tokenStore.readAccessToken(), 'fresh-access');
    expect(await tokenStore.readRefreshToken(), 'fresh-refresh');
  });

  test(
    'on 401 when refresh itself fails, clears the token store and rethrows',
    () async {
      adapter.onGet(
        '/api/protected',
        (server) => server.reply(401, {
          'Status': 401,
          'Errors': ['expired'],
        }),
      );
      adapter.onPost(
        '/api/auth/refresh',
        (server) => server.reply(401, {
          'Status': 401,
          'Errors': ['invalid'],
        }),
        data: Matchers.any,
      );

      await expectLater(
        () => dio.get('/api/protected'),
        throwsA(isA<DioException>()),
      );
      expect(await tokenStore.readAccessToken(), isNull);
    },
  );
}
