import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/api_exception.dart';
import 'package:gym_app/features/personal_tracking/data/real_personal_log_repository.dart';
import 'package:gym_app/features/personal_tracking/domain/personal_log.dart';

const _json = {
  'content-type': ['application/json'],
};

const _workoutJson =
    '{"id":1,"date":"2026-09-25","kind":"Workout","title":"Koşu","durationMinutes":30,"notes":"Sahil",'
    '"weightKg":null,"bodyFatPercent":null,"waistCm":null,"createdAt":"2026-09-25T18:00:00Z"}';
const _measurementJson =
    '{"id":2,"date":"2026-09-24","kind":"Measurement","title":null,"durationMinutes":null,"notes":null,'
    '"weightKg":72.4,"bodyFatPercent":18,"waistCm":null,"createdAt":"2026-09-24T08:00:00Z"}';

void main() {
  test('list GET /api/personal-logs from/to parametreleriyle çağırır ve iki türü ayrıştırır', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    RequestOptions? captured;
    dio.httpClientAdapter = _Adapter((options) {
      captured = options;
      return ResponseBody.fromString('[$_workoutJson,$_measurementJson]', 200, headers: _json);
    });

    final logs = await RealPersonalLogRepository(dio).list(from: DateTime(2026, 6, 1), to: DateTime(2026, 9, 26));

    expect(captured!.path, '/api/personal-logs');
    expect(captured!.queryParameters, {'from': '2026-06-01', 'to': '2026-09-26'});
    expect(logs, hasLength(2));

    final workout = logs[0];
    expect(workout.id, 1);
    expect(workout.date, DateTime(2026, 9, 25));
    expect(workout.kind, PersonalLogKind.workout);
    expect(workout.title, 'Koşu');
    expect(workout.durationMinutes, 30);
    expect(workout.notes, 'Sahil');
    expect(workout.weightKg, isNull);
    expect(workout.createdAt, DateTime.utc(2026, 9, 25, 18));

    final measurement = logs[1];
    expect(measurement.kind, PersonalLogKind.measurement);
    expect(measurement.title, isNull);
    expect(measurement.weightKg, 72.4);
    // Tam sayı olarak gelen ondalık alan da double'a çevrilir.
    expect(measurement.bodyFatPercent, 18.0);
    expect(measurement.waistCm, isNull);
  });

  test('create POST gövdesini sözleşme alanlarıyla gönderir ve dönen öğeyi ayrıştırır', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    RequestOptions? captured;
    dio.httpClientAdapter = _Adapter((options) {
      captured = options;
      return ResponseBody.fromString(_measurementJson, 201, headers: _json);
    });

    final created = await RealPersonalLogRepository(dio).create(
      PersonalLogDraft(date: DateTime(2026, 9, 24), kind: PersonalLogKind.measurement, weightKg: 72.4, bodyFatPercent: 18),
    );

    expect(captured!.method, 'POST');
    expect(captured!.path, '/api/personal-logs');
    expect(jsonDecode(jsonEncode(captured!.data)), {
      'date': '2026-09-24',
      'kind': 'Measurement',
      'title': null,
      'durationMinutes': null,
      'notes': null,
      'weightKg': 72.4,
      'bodyFatPercent': 18.0,
      'waistCm': null,
    });
    expect(created.id, 2);
  });

  test('update PUT /api/personal-logs/{id} çağırır', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    RequestOptions? captured;
    dio.httpClientAdapter = _Adapter((options) {
      captured = options;
      return ResponseBody.fromString(_workoutJson, 200, headers: _json);
    });

    await RealPersonalLogRepository(dio).update(
      1,
      PersonalLogDraft(date: DateTime(2026, 9, 25), kind: PersonalLogKind.workout, title: 'Koşu', durationMinutes: 30),
    );

    expect(captured!.method, 'PUT');
    expect(captured!.path, '/api/personal-logs/1');
    expect((captured!.data as Map)['kind'], 'Workout');
  });

  test('delete DELETE /api/personal-logs/{id} çağırır', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    RequestOptions? captured;
    dio.httpClientAdapter = _Adapter((options) {
      captured = options;
      return ResponseBody.fromString('', 204);
    });

    await RealPersonalLogRepository(dio).delete(1);

    expect(captured!.method, 'DELETE');
    expect(captured!.path, '/api/personal-logs/1');
  });

  test('başkasının kaydı (404) ApiException olarak fırlatılır', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _Adapter((_) => ResponseBody.fromString(
          '{"Status":404,"Errors":["Kayıt bulunamadı."]}',
          404,
          headers: _json,
        ));

    await expectLater(
      RealPersonalLogRepository(dio).delete(99),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404)),
    );
  });
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this._respond);

  final ResponseBody Function(RequestOptions options) _respond;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async =>
      _respond(options);
}
