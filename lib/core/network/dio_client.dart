import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'api_config.dart';
import 'token_store.dart';
import 'secure_token_store.dart';

part 'dio_client.g.dart';

// Endpoints that must NOT get an Authorization header attached, and must
// NOT trigger a refresh-and-retry on 401 (a 401 from /login IS the actual
// "wrong password" answer, not an expired-session signal).
const _noAuthPaths = [
  '/api/auth/register',
  '/api/auth/login',
  '/api/auth/refresh',
  '/api/auth/forgot-password',
  '/api/auth/reset-password',
];

void addAuthInterceptor(Dio dio, TokenStore tokenStore) {
  // Used only for the refresh call and the retry of the failed request.
  // QueuedInterceptorsWrapper serializes onError handling through a single
  // shared queue: while the outer 401 handler below is running (and hasn't
  // called handler.next/resolve yet), that queue is "busy". If the refresh
  // call itself were issued on `dio` (the same instance this interceptor is
  // attached to) and it errored, its own onError would be queued behind the
  // still-running outer handler — which is itself awaiting that inner
  // call — a permanent deadlock. `rawDio` shares the same transport
  // (httpClientAdapter) and base options but carries none of `dio`'s
  // interceptors, so the refresh/retry calls never re-enter this queue.
  final rawDio = Dio(dio.options)..httpClientAdapter = dio.httpClientAdapter;

  dio.interceptors.add(
    QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        if (!_noAuthPaths.contains(options.path)) {
          final accessToken = await tokenStore.readAccessToken();
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final requestPath = error.requestOptions.path;
        if (error.response?.statusCode != 401 ||
            _noAuthPaths.contains(requestPath)) {
          handler.next(error);
          return;
        }

        final refreshToken = await tokenStore.readRefreshToken();
        if (refreshToken == null) {
          await tokenStore.clear();
          handler.next(error);
          return;
        }

        try {
          final refreshResponse = await rawDio.post<Map<String, dynamic>>(
            '/api/auth/refresh',
            data: {'refreshToken': refreshToken},
          );
          final data = refreshResponse.data!;
          await tokenStore.saveTokens(
            accessToken: data['accessToken'] as String,
            refreshToken: data['refreshToken'] as String,
          );

          final retryOptions = error.requestOptions;
          retryOptions.headers['Authorization'] =
              'Bearer ${data['accessToken']}';
          final retryResponse = await rawDio.fetch(retryOptions);
          handler.resolve(retryResponse);
        } catch (_) {
          await tokenStore.clear();
          handler.next(error);
        }
      },
    ),
  );
}

@riverpod
Dio dio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  addAuthInterceptor(dio, ref.watch(tokenStoreProvider));
  return dio;
}
