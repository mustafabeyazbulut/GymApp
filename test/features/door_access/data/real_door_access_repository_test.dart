import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/api_exception.dart';
import 'package:gym_app/features/door_access/data/real_door_access_repository.dart';

void main() {
  test('getZones parses the list from GET /api/zones', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/zones');
      expect(options.queryParameters['branchId'], 5);
      return ResponseBody.fromString(
        '[{"id":1,"branchId":5,"name":"Ana Giriş"}]',
        200,
        headers: {'content-type': ['application/json']},
      );
    });
    final repository = RealDoorAccessRepository(dio);

    final zones = await repository.getZones(5);

    expect(zones, hasLength(1));
    expect(zones.single.name, 'Ana Giriş');
  });

  test('createZone posts to /api/zones with the given fields', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/zones');
      expect(options.data, {'branchId': 5, 'name': 'Ana Giriş'});
      return ResponseBody.fromString('{"id":1,"name":"Ana Giriş"}', 201, headers: {
        'content-type': ['application/json'],
      });
    });
    final repository = RealDoorAccessRepository(dio);

    final zone = await repository.createZone(branchId: 5, name: 'Ana Giriş');

    expect(zone.id, 1);
  });

  test('deleteZone sends DELETE to /api/zones/{id}', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/zones/1');
      expect(options.method, 'DELETE');
      return ResponseBody.fromString('', 204);
    });
    final repository = RealDoorAccessRepository(dio);

    await repository.deleteZone(1);
  });

  test('createDoor posts to /api/zones/{zoneId}/doors', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/zones/1/doors');
      return ResponseBody.fromString('{"id":2,"name":"Kapı 1"}', 201, headers: {
        'content-type': ['application/json'],
      });
    });
    final repository = RealDoorAccessRepository(dio);

    final door = await repository.createDoor(zoneId: 1, name: 'Kapı 1');

    expect(door.id, 2);
  });

  test('createZoneAccessRule posts to /api/zones/{zoneId}/access-rules', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/zones/1/access-rules');
      expect(options.data, {'ruleType': 'Gender', 'ruleValue': 'Kadın'});
      return ResponseBody.fromString('{"id":3}', 201, headers: {
        'content-type': ['application/json'],
      });
    });
    final repository = RealDoorAccessRepository(dio);

    final rule = await repository.createZoneAccessRule(zoneId: 1, ruleType: 'Gender', ruleValue: 'Kadın');

    expect(rule.id, 3);
  });

  test('getZones rethrows a DioException as ApiException', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      return ResponseBody.fromString('{"Status":403,"Errors":["Yetkiniz yok."]}', 403, headers: {
        'content-type': ['application/json'],
      });
    });
    final repository = RealDoorAccessRepository(dio);

    await expectLater(() => repository.getZones(5), throwsA(isA<ApiException>()));
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
