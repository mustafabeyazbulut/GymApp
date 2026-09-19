import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/api_exception.dart';
import 'package:gym_app/features/class_scheduling/data/real_class_scheduling_repository.dart';
import 'package:gym_app/features/class_scheduling/domain/class_session.dart';

void main() {
  test('getClassSessions parses the list from GET /api/class-sessions with branchId/from/to query params', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/class-sessions');
      expect(options.queryParameters['branchId'], 10);
      expect(options.queryParameters['from'], '2026-09-21');
      expect(options.queryParameters['to'], '2026-09-28');
      return ResponseBody.fromString(
        '[{"id":1,"branchId":10,"trainerUserId":99,"category":"GroupClass","name":"Yoga",'
        '"date":"2026-09-21","startTime":"09:00:00","endTime":"10:00:00","capacity":10,'
        '"enrolledCount":3,"cancellationCutoffHours":2}]',
        200,
        headers: {
          'content-type': ['application/json'],
        },
      );
    });
    final repository = RealClassSchedulingRepository(dio);

    final sessions = await repository.getClassSessions(
      branchId: 10,
      from: DateTime(2026, 9, 21),
      to: DateTime(2026, 9, 28),
    );

    expect(sessions, hasLength(1));
    expect(sessions.single.name, 'Yoga');
    expect(sessions.single.category, ClassSessionCategory.groupClass);
    expect(sessions.single.enrolledCount, 3);
    expect(sessions.single.capacity, 10);
    expect(sessions.single.startTimeLabel, '09:00');
  });

  test('getClassSessions rethrows a DioException as ApiException', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      return ResponseBody.fromString('{"Status":500,"Errors":[]}', 500);
    });
    final repository = RealClassSchedulingRepository(dio);

    await expectLater(() => repository.getClassSessions(), throwsA(isA<ApiException>()));
  });

  test('enroll posts to /api/class-sessions/{id}/enroll with packageAssignmentId', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/class-sessions/5/enroll');
      expect(options.data['packageAssignmentId'], 20);
      return ResponseBody.fromString('{"id":1,"reservedAt":"2026-09-21T09:00:00Z"}', 201, headers: {
        'content-type': ['application/json'],
      });
    });
    final repository = RealClassSchedulingRepository(dio);

    await repository.enroll(classSessionId: 5, packageAssignmentId: 20);
  });

  test('enroll rethrows a 409 conflict (class full) as ApiException', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      return ResponseBody.fromString('{"Status":409,"Errors":["Bu ders programının kapasitesi dolu."]}', 409, headers: {
        'content-type': ['application/json'],
      });
    });
    final repository = RealClassSchedulingRepository(dio);

    await expectLater(
      () => repository.enroll(classSessionId: 5, packageAssignmentId: 20),
      throwsA(isA<ApiException>().having((e) => e.errors, 'errors', ['Bu ders programının kapasitesi dolu.'])),
    );
  });

  test('cancelEnrollment posts to /api/class-enrollments/{id}/cancel', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/class-enrollments/7/cancel');
      return ResponseBody.fromString('', 204);
    });
    final repository = RealClassSchedulingRepository(dio);

    await repository.cancelEnrollment(7);
  });

  test('getMyEnrollments parses the list from GET /api/class-enrollments/mine', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/class-enrollments/mine');
      return ResponseBody.fromString(
        '[{"id":7,"classSessionId":5,"className":"Yoga","category":"GroupClass",'
        '"date":"2026-09-21","startTime":"09:00:00","endTime":"10:00:00","status":"Reserved"}]',
        200,
        headers: {
          'content-type': ['application/json'],
        },
      );
    });
    final repository = RealClassSchedulingRepository(dio);

    final enrollments = await repository.getMyEnrollments();

    expect(enrollments, hasLength(1));
    expect(enrollments.single.className, 'Yoga');
  });

  test('createClassSession posts to /api/class-sessions with the given fields', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/class-sessions');
      expect(options.data['branchId'], 10);
      expect(options.data['trainerUserId'], 99);
      expect(options.data['category'], 'MartialArts');
      expect(options.data['name'], 'Karate');
      expect(options.data['date'], '2026-09-21');
      expect(options.data['startTime'], '18:00');
      expect(options.data['endTime'], '19:00');
      expect(options.data['capacity'], 12);
      expect(options.data['cancellationCutoffHours'], 4);
      return ResponseBody.fromString('{"id":1,"name":"Karate"}', 201, headers: {
        'content-type': ['application/json'],
      });
    });
    final repository = RealClassSchedulingRepository(dio);

    await repository.createClassSession(
      branchId: 10,
      trainerUserId: 99,
      category: ClassSessionCategory.martialArts,
      name: 'Karate',
      date: DateTime(2026, 9, 21),
      startTime: '18:00',
      endTime: '19:00',
      capacity: 12,
      cancellationCutoffHours: 4,
    );
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
