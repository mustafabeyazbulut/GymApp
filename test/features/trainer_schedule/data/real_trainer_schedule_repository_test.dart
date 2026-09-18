import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/api_exception.dart';
import 'package:gym_app/features/trainer_schedule/data/real_trainer_schedule_repository.dart';

void main() {
  test('getMyReservations parses the list from GET /api/reservations/mine', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/reservations/mine');
      return ResponseBody.fromString(
        '[{"id":1,"packageAssignmentId":10,"memberUserId":7,"memberFullName":"Ayşe Yılmaz",'
        '"companyId":3,"branchId":10,"scheduledAt":"2026-01-01T10:00:00Z","status":"Booked","qrCode":"111111"}]',
        200,
        headers: {'content-type': ['application/json']},
      );
    });
    final repository = RealTrainerScheduleRepository(dio);

    final reservations = await repository.getMyReservations();

    expect(reservations, hasLength(1));
    expect(reservations.single.memberFullName, 'Ayşe Yılmaz');
  });

  test('getMyReservations rethrows a DioException as ApiException', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      return ResponseBody.fromString(
        '{"Status":401,"Errors":["Yetkisiz."]}',
        401,
        headers: {'content-type': ['application/json']},
      );
    });
    final repository = RealTrainerScheduleRepository(dio);

    await expectLater(
      () => repository.getMyReservations(),
      throwsA(isA<ApiException>()),
    );
  });

  test('checkIn posts to /api/reservations/{id}/check-in', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/reservations/1/check-in');
      return ResponseBody.fromString('', 204);
    });
    final repository = RealTrainerScheduleRepository(dio);

    await repository.checkIn(1);
  });

  test('markNoShow posts to /api/reservations/{id}/no-show', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/reservations/1/no-show');
      return ResponseBody.fromString('', 204);
    });
    final repository = RealTrainerScheduleRepository(dio);

    await repository.markNoShow(1);
  });

  test('cancel posts to /api/reservations/{id}/cancel', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/reservations/1/cancel');
      return ResponseBody.fromString('', 204);
    });
    final repository = RealTrainerScheduleRepository(dio);

    await repository.cancel(1);
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
