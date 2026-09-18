import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/api_exception.dart';
import 'package:gym_app/features/notifications/data/real_notification_repository.dart';

void main() {
  test('getNotifications parses the list from GET /api/notifications', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/notifications');
      return ResponseBody.fromString(
        '[{"id":1,"title":"Yeni davet","body":"Bir paket size tanımlanmak üzere.",'
        '"isRead":false,"createdAt":"2026-01-01T10:00:00Z"}]',
        200,
        headers: {'content-type': ['application/json']},
      );
    });
    final repository = RealNotificationRepository(dio);

    final notifications = await repository.getNotifications();

    expect(notifications, hasLength(1));
    expect(notifications.single.title, 'Yeni davet');
    expect(notifications.single.isRead, isFalse);
  });

  test('getNotifications rethrows a DioException as ApiException', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      return ResponseBody.fromString('{"Status":401,"Errors":["Yetkisiz."]}', 401,
          headers: {'content-type': ['application/json']});
    });
    final repository = RealNotificationRepository(dio);

    await expectLater(() => repository.getNotifications(), throwsA(isA<ApiException>()));
  });

  test('markRead patches /api/notifications/{id}/read', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/notifications/1/read');
      return ResponseBody.fromString('', 204);
    });
    final repository = RealNotificationRepository(dio);

    await repository.markRead(1);
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
