import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/fake_token_store.dart';
import 'package:gym_app/core/network/dio_client.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

/// http_mock_adapter bir rotayı sadece KAYIT anında, sabit bir yanıtla
/// eşleştirir - aynı isteğin ilk denemede başarısız, ikinci denemede başarılı
/// olduğu bir senaryoyu (deneme sayacına göre dallanan) modelleyemez. Bu
/// yüzden refresh'in "geçici hata sonrası kendiliğinden toparlanma" davranışı
/// için elle yazılmış, deneme sayısını sayan bu minik adapter kullanılıyor.
class _FlakyRefreshAdapter implements HttpClientAdapter {
  _FlakyRefreshAdapter({required this.failFirstNRefreshAttempts});

  final int failFirstNRefreshAttempts;
  int refreshAttempts = 0;

  ResponseBody _json(String body, int statusCode) => ResponseBody.fromString(
        body,
        statusCode,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/api/protected') {
      final isFresh = options.headers['Authorization'] == 'Bearer fresh-access';
      return isFresh
          ? _json('{"ok":true}', 200)
          : _json('{"Status":401,"Errors":["expired"]}', 401);
    }
    if (options.path == '/api/auth/refresh') {
      refreshAttempts += 1;
      if (refreshAttempts <= failFirstNRefreshAttempts) {
        throw DioException.connectionError(requestOptions: options, reason: 'simulated flaky Postgres/Docker NAT');
      }
      return _json(
        '{"accessToken":"fresh-access","expiresAtUtc":"2026-01-01T00:00:00Z","refreshToken":"fresh-refresh"}',
        200,
      );
    }
    throw UnimplementedError('beklenmeyen path: ${options.path}');
  }

  @override
  void close({bool force = false}) {}
}

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

  test(
    'refresh bir kez geçici bağlantı hatası alsa bile (Postgres/Docker gecikmesi gibi) '
    'ikinci denemede toparlanır ve kullanıcıyı yanlışlıkla çıkışa zorlamaz',
    () async {
      // addAuthInterceptor kendi rawDio'sunu (refresh/retry çağrıları için)
      // OLUŞTURULDUĞU ANDA dio.httpClientAdapter'ın o anki değerini yakalar
      // - bu yüzden flaky adapter, addAuthInterceptor çağrılmadan ÖNCE
      // atanmalı, paylaşılan setUp()'ın kurduğu dio/adapter yerine kendi
      // taze çiftini kuruyoruz.
      final freshTokenStore = FakeTokenStore();
      await freshTokenStore.saveTokens(accessToken: 'expired-access', refreshToken: 'valid-refresh');
      final freshDio = Dio(BaseOptions(baseUrl: 'http://test.local'));
      final flakyAdapter = _FlakyRefreshAdapter(failFirstNRefreshAttempts: 1);
      freshDio.httpClientAdapter = flakyAdapter;
      addAuthInterceptor(freshDio, freshTokenStore);

      final response = await freshDio.get('/api/protected');

      expect(response.statusCode, 200);
      expect(flakyAdapter.refreshAttempts, 2);
      expect(await freshTokenStore.readAccessToken(), 'fresh-access');
    },
  );

  test(
    '3 denemenin hepsi de geçici bağlantı hatasıyla başarısız olursa '
    'nihayetinde vazgeçip token deposunu temizler',
    () async {
      final freshTokenStore = FakeTokenStore();
      await freshTokenStore.saveTokens(accessToken: 'expired-access', refreshToken: 'valid-refresh');
      final freshDio = Dio(BaseOptions(baseUrl: 'http://test.local'));
      final flakyAdapter = _FlakyRefreshAdapter(failFirstNRefreshAttempts: 3);
      freshDio.httpClientAdapter = flakyAdapter;
      addAuthInterceptor(freshDio, freshTokenStore);

      await expectLater(
        () => freshDio.get('/api/protected'),
        throwsA(isA<DioException>()),
      );
      expect(flakyAdapter.refreshAttempts, 3);
      expect(await freshTokenStore.readAccessToken(), isNull);
    },
  );
}
