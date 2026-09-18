import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/api_exception.dart';
import 'package:gym_app/features/classes/data/real_class_repository.dart';

void main() {
  test('getTrainers parses the trainer list from GET /api/package-assignments/{id}/trainers', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/package-assignments/20/trainers');
      return ResponseBody.fromString(
        '[{"id":99,"fullName":"Ali Antrenör","branchId":null}]',
        200,
        headers: {'content-type': ['application/json']},
      );
    });
    final repository = RealClassRepository(dio);

    final trainers = await repository.getTrainers(20);

    expect(trainers, hasLength(1));
    expect(trainers.single.fullName, 'Ali Antrenör');
  });

  test('getReservations parses the reservation list', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/package-assignments/20/reservations');
      return ResponseBody.fromString(
        '[{"id":1,"trainerId":99,"scheduledAt":"2026-01-01T10:00:00Z","status":"Booked","qrCode":"111111"}]',
        200,
        headers: {'content-type': ['application/json']},
      );
    });
    final repository = RealClassRepository(dio);

    final reservations = await repository.getReservations(20);

    expect(reservations, hasLength(1));
    expect(reservations.single.trainerId, 99);
  });

  test('getCheckIns parses the check-in list', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/package-assignments/20/check-ins');
      return ResponseBody.fromString(
        '[{"id":1,"reservationId":null,"checkedInAt":"2026-01-01T10:00:00Z"}]',
        200,
        headers: {'content-type': ['application/json']},
      );
    });
    final repository = RealClassRepository(dio);

    final checkIns = await repository.getCheckIns(20);

    expect(checkIns, hasLength(1));
    expect(checkIns.single.reservationId, isNull);
  });

  test('createReservation posts to /api/reservations with the given fields', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/reservations');
      expect(options.data['packageAssignmentId'], 20);
      expect(options.data['trainerId'], 99);
      return ResponseBody.fromString(
        '{"id":1,"scheduledAt":"2026-01-01T10:00:00Z","qrCode":"111111"}',
        201,
        headers: {'content-type': ['application/json']},
      );
    });
    final repository = RealClassRepository(dio);

    await repository.createReservation(
      packageAssignmentId: 20,
      trainerId: 99,
      scheduledAt: DateTime.utc(2026, 1, 1, 10),
    );
  });

  test('createReservation rethrows a 409 conflict as ApiException', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      return ResponseBody.fromString(
        '{"Status":409,"Errors":["Bu antrenörün bu saatte zaten bir rezervasyonu var."]}',
        409,
        headers: {'content-type': ['application/json']},
      );
    });
    final repository = RealClassRepository(dio);

    await expectLater(
      () => repository.createReservation(
        packageAssignmentId: 20,
        trainerId: 99,
        scheduledAt: DateTime.utc(2026, 1, 1, 10),
      ),
      throwsA(isA<ApiException>().having(
        (e) => e.message,
        'message',
        'Bu antrenörün bu saatte zaten bir rezervasyonu var.',
      )),
    );
  });

  test('cancelReservation posts to /api/reservations/{id}/cancel', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/reservations/1/cancel');
      return ResponseBody.fromString('', 204);
    });
    final repository = RealClassRepository(dio);

    await repository.cancelReservation(1);
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
