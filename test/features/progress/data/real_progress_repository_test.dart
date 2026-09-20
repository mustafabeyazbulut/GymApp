import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/api_exception.dart';
import 'package:gym_app/features/progress/data/real_progress_repository.dart';

void main() {
  test('getProgressNotes parses the list from GET /api/package-assignments/{id}/progress-notes', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/package-assignments/20/progress-notes');
      return ResponseBody.fromString(
        '[{"id":1,"techniqueScore":70,"conditionScore":60,"noteText":"İyi ilerleme.","createdAt":"2026-01-01T10:00:00Z"}]',
        200,
        headers: {'content-type': ['application/json']},
      );
    });
    final repository = RealProgressRepository(dio);

    final notes = await repository.getProgressNotes(20);

    expect(notes, hasLength(1));
    expect(notes.single.techniqueScore, 70);
    expect(notes.single.hasMedia, isFalse);
  });

  test('getProgressNotes parses a note with media', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      return ResponseBody.fromString(
        '[{"id":1,"techniqueScore":70,"conditionScore":60,"noteText":null,'
        '"createdAt":"2026-01-01T10:00:00Z","mediaFileId":9,"mediaContentType":"image/jpeg"}]',
        200,
        headers: {'content-type': ['application/json']},
      );
    });
    final repository = RealProgressRepository(dio);

    final notes = await repository.getProgressNotes(20);

    expect(notes.single.hasMedia, isTrue);
    expect(notes.single.isVideoMedia, isFalse);
  });

  test('recordProgressNote posts multipart/form-data with the given fields', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/package-assignments/20/progress-notes');
      final formData = options.data as FormData;
      final fields = {for (final entry in formData.fields) entry.key: entry.value};
      expect(fields['techniqueScore'], '70');
      expect(fields['conditionScore'], '60');
      expect(fields['noteText'], 'İyi ilerleme.');
      expect(formData.files, isEmpty);
      return ResponseBody.fromString(
        '{"id":1,"techniqueScore":70,"conditionScore":60,"noteText":"İyi ilerleme.","createdAt":"2026-01-01T10:00:00Z"}',
        201,
        headers: {'content-type': ['application/json']},
      );
    });
    final repository = RealProgressRepository(dio);

    await repository.recordProgressNote(
      packageAssignmentId: 20,
      techniqueScore: 70,
      conditionScore: 60,
      noteText: 'İyi ilerleme.',
    );
  });

  test('recordProgressNote rethrows a DioException as ApiException', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      return ResponseBody.fromString(
        '{"Status":403,"Errors":["Bu paket ataması için ilerleme notu bırakma yetkiniz yok."]}',
        403,
        headers: {'content-type': ['application/json']},
      );
    });
    final repository = RealProgressRepository(dio);

    await expectLater(
      () => repository.recordProgressNote(packageAssignmentId: 20, techniqueScore: 50, conditionScore: 50),
      throwsA(isA<ApiException>()),
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
