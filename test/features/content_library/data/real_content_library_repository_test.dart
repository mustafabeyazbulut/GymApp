import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/api_exception.dart';
import 'package:gym_app/core/network/fake_token_store.dart';
import 'package:gym_app/features/content_library/data/real_content_library_repository.dart';
import 'package:gym_app/features/content_library/domain/content_item.dart';

void main() {
  test('getContentItems parses the list from GET /api/content-items', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/content-items');
      return ResponseBody.fromString(
        '[{'
        '"id":1,"companyId":1,"branchId":null,"title":"Squat Tekniği","description":"Doğru form",'
        '"requiredAccessTier":"Standard","mediaFileId":5,"mediaContentType":"video/mp4",'
        '"isActive":true,"createdAt":"2026-09-20T10:00:00Z","hasAccess":true'
        '}]',
        200,
        headers: {
          'content-type': ['application/json'],
        },
      );
    });
    final repository = RealContentLibraryRepository(dio, FakeTokenStore());

    final items = await repository.getContentItems();

    expect(items, hasLength(1));
    expect(items.single.title, 'Squat Tekniği');
    expect(items.single.mediaFileId, 5);
    expect(items.single.hasAccess, isTrue);
    expect(items.single.isVideo, isTrue);
  });

  test('getContentItems source alanını ayrıştırır; platform içeriğinde companyId null olabilir', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) => ResponseBody.fromString(
          '[{"id":1,"source":"Platform","companyId":null,"branchId":null,"title":"Isınma","description":null,'
          '"requiredAccessTier":"Standard","mediaFileId":5,"mediaContentType":"video/mp4","isActive":true,'
          '"createdAt":"2026-09-20T10:00:00Z","hasAccess":true},'
          '{"id":2,"source":"Gym","companyId":3,"branchId":9,"title":"Squat","description":null,'
          '"requiredAccessTier":"Standard","mediaFileId":6,"mediaContentType":"video/mp4","isActive":true,'
          '"createdAt":"2026-09-20T10:00:00Z","hasAccess":true}]',
          200,
          headers: {
            'content-type': ['application/json'],
          },
        ));

    final items = await RealContentLibraryRepository(dio, FakeTokenStore()).getContentItems();

    expect(items[0].source, ContentSource.platform);
    expect(items[0].isPlatform, isTrue);
    expect(items[0].companyId, isNull);
    expect(items[1].source, ContentSource.gym);
    expect(items[1].companyId, 3);
  });

  test('getContentItems rethrows a DioException as ApiException', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      return ResponseBody.fromString('{"Status":403,"Errors":["Yetkiniz yok."]}', 403, headers: {
        'content-type': ['application/json'],
      });
    });
    final repository = RealContentLibraryRepository(dio, FakeTokenStore());

    await expectLater(repository.getContentItems, throwsA(isA<ApiException>()));
  });

  test('setContentItemActive patches /api/content-items/{id}/active', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/content-items/1/active');
      expect(options.method, 'PATCH');
      expect(options.data, {'isActive': false});
      return ResponseBody.fromString('', 204);
    });
    final repository = RealContentLibraryRepository(dio, FakeTokenStore());

    await repository.setContentItemActive(id: 1, isActive: false);
  });

  test('mediaUrl builds the full authenticated media URL', () {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    final repository = RealContentLibraryRepository(dio, FakeTokenStore());

    expect(repository.mediaUrl(5), 'https://test/api/media/5');
  });

  group('ensureMediaAccessible', () {
    test('erişim varsa gövdeyi indirmeden tamamlanır', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://test'));
      RequestOptions? captured;
      dio.httpClientAdapter = _PassThroughAdapter((options) {
        captured = options;
        return ResponseBody.fromBytes(List.filled(1024, 0), 200, headers: {
          'content-type': ['video/mp4'],
        });
      });
      final repository = RealContentLibraryRepository(dio, FakeTokenStore());

      await repository.ensureMediaAccessible(5);

      expect(captured!.path, '/api/media/5');
      expect(captured!.responseType, ResponseType.stream);
    });

    test('403 gelirse backend\'in yerelleştirilmiş mesajıyla ApiException fırlatır', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://test'));
      dio.httpClientAdapter = _PassThroughAdapter(
        (options) => ResponseBody.fromString(
          '{"Status":403,"Errors":["Bu medya dosyasını görüntüleme yetkiniz yok."]}',
          403,
          headers: {
            'content-type': ['application/json'],
          },
        ),
      );
      final repository = RealContentLibraryRepository(dio, FakeTokenStore());

      await expectLater(
        repository.ensureMediaAccessible(5),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 403)
            .having((e) => e.errors, 'errors', ['Bu medya dosyasını görüntüleme yetkiniz yok.'])),
      );
    });
  });

  test('mediaAuthHeaders returns a Bearer header from the stored access token', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    final tokenStore = FakeTokenStore();
    await tokenStore.saveTokens(accessToken: 'abc123', refreshToken: 'refresh');
    final repository = RealContentLibraryRepository(dio, tokenStore);

    final headers = await repository.mediaAuthHeaders();

    expect(headers, {'Authorization': 'Bearer abc123'});
  });
}

typedef _ResponseBuilder = ResponseBody Function(RequestOptions options);

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._respond);

  final _ResponseBuilder _respond;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = _respond(options);
    if (body.statusCode >= 400) {
      throw DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: body.statusCode,
          data: jsonDecode(await utf8.decoder.bind(body.stream).join()),
        ),
      );
    }
    return body;
  }
}

// Gerçek adaptör gibi yanıtı olduğu gibi döner; 4xx'i Dio'nun kendisi
// responseType'a göre DioException'a çevirir.
class _PassThroughAdapter implements HttpClientAdapter {
  _PassThroughAdapter(this._respond);

  final _ResponseBuilder _respond;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      _respond(options);
}
