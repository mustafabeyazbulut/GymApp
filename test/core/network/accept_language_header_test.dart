import 'dart:typed_data';
import 'dart:ui' show Locale;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/locale/app_locale_provider.dart';
import 'package:gym_app/core/network/dio_client.dart';
import 'package:gym_app/core/network/fake_token_store.dart';
import 'package:gym_app/core/network/secure_token_store.dart';

// Backend'in "mobildeki seçili dil paketiyle çalışacak" olması, mobilin
// kendi seçili dilini HER istekte göndermesine bağlı - bu, o sözleşmenin
// mobil tarafındaki tek karşılığı (bkz. GymAppApi'nin
// Program.cs'teki UseRequestLocalization'ı).
void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(overrides: [
      tokenStoreProvider.overrideWithValue(FakeTokenStore()),
    ]);
    addTearDown(container.dispose);
    container.listen(dioProvider, (_, _) {});
    container.listen(appLocaleProvider, (_, _) {});
  });

  test('sends Accept-Language: tr when the app locale is explicitly Turkish', () async {
    container.read(appLocaleProvider.notifier).setLocale(const Locale('tr'));
    final dio = container.read(dioProvider);
    RequestOptions? captured;
    dio.httpClientAdapter = _CapturingAdapter((options) => captured = options);

    await dio.get('/api/ping');

    expect(captured!.headers['Accept-Language'], 'tr');
  });

  test('sends Accept-Language: en when the app locale is explicitly English', () async {
    container.read(appLocaleProvider.notifier).setLocale(const Locale('en'));
    final dio = container.read(dioProvider);
    RequestOptions? captured;
    dio.httpClientAdapter = _CapturingAdapter((options) => captured = options);

    await dio.get('/api/ping');

    expect(captured!.headers['Accept-Language'], 'en');
  });

  test('reads the selection fresh on each request, not just at Dio creation', () async {
    final dio = container.read(dioProvider);
    RequestOptions? captured;
    dio.httpClientAdapter = _CapturingAdapter((options) => captured = options);

    container.read(appLocaleProvider.notifier).setLocale(const Locale('tr'));
    await dio.get('/api/ping');
    expect(captured!.headers['Accept-Language'], 'tr');

    container.read(appLocaleProvider.notifier).setLocale(const Locale('en'));
    await dio.get('/api/ping');
    expect(captured!.headers['Accept-Language'], 'en');
  });
}

typedef _RequestCapture = void Function(RequestOptions options);

class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter(this._capture);

  final _RequestCapture _capture;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    _capture(options);
    return ResponseBody.fromString('{}', 200, headers: {
      'content-type': ['application/json'],
    });
  }
}
