import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/dio_client.dart';
import 'package:gym_app/core/network/fake_token_store.dart';
import 'package:gym_app/core/network/secure_token_store.dart';
import 'package:gym_app/core/providers/active_staff_company_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(overrides: [
      tokenStoreProvider.overrideWithValue(FakeTokenStore()),
    ]);
    addTearDown(container.dispose);
    // dioProvider VE activeStaffCompanyIdProvider autoDispose'dur - bir
    // dinleyici olmadan, container.read döndükten hemen sonra elden
    // çıkarılırlar (senkron kapsamın sonunda). dioProvider için bu,
    // interceptor'ın kendi ref.read'inin sonraki asenkron dio.get() çağrısı
    // sırasında zaten dispose edilmiş bir Ref'e çarpmasına yol açar.
    // activeStaffCompanyIdProvider için ise select(7) çağrısının hemen
    // ardından state'in sessizce null'a sıfırlanmasına yol açar (gerçek
    // uygulamada drawer'ın kendi ref.watch'ı onu zaten canlı tutuyor).
    // Testin süresi boyunca ikisini de canlı tutmak için sahte dinleyiciler
    // ekle.
    container.listen(dioProvider, (_, _) {});
    container.listen(activeStaffCompanyIdProvider, (_, _) {});
  });

  test('does not attach X-Active-Company-Id when none is selected', () async {
    final dio = container.read(dioProvider);
    RequestOptions? captured;
    dio.httpClientAdapter = _CapturingAdapter((options) => captured = options);

    await dio.get('/api/ping');

    expect(captured!.headers.containsKey(activeCompanyHeaderName), isFalse);
  });

  test('attaches the currently selected company id to every request', () async {
    container.read(activeStaffCompanyIdProvider.notifier).select(7);
    final dio = container.read(dioProvider);
    RequestOptions? captured;
    dio.httpClientAdapter = _CapturingAdapter((options) => captured = options);

    await dio.get('/api/ping');

    expect(captured!.headers[activeCompanyHeaderName], '7');
  });

  test('reads the selection fresh on each request, not just at Dio creation', () async {
    final dio = container.read(dioProvider);
    RequestOptions? captured;
    dio.httpClientAdapter = _CapturingAdapter((options) => captured = options);

    await dio.get('/api/ping');
    expect(captured!.headers.containsKey(activeCompanyHeaderName), isFalse);

    container.read(activeStaffCompanyIdProvider.notifier).select(3);
    await dio.get('/api/ping');
    expect(captured!.headers[activeCompanyHeaderName], '3');
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
