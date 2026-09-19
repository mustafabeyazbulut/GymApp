import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/api_exception.dart';
import 'package:gym_app/features/analytics/data/real_analytics_repository.dart';

void main() {
  test('getSummary parses the response from GET /api/analytics/summary', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/analytics/summary');
      return ResponseBody.fromString(
        '{'
        '"activeMembers":{"currentCount":12,"countThirtyDaysAgo":10,"trendPercentage":20.0},'
        '"classOccupancy":{"overallOccupancyRate":0.75,"classBreakdown":['
        '{"className":"Yoga","sessionCount":4,"totalCapacity":40,"totalEnrolled":30,"occupancyRate":0.75}'
        ']},'
        '"packageSales":{"totalCount":5,"categoryBreakdown":['
        '{"category":"GroupClass","count":3},{"category":null,"count":2}'
        ']},'
        '"trainerActiveStudents":[{"trainerUserId":90,"trainerFullName":"Ali Antrenör","activeStudentCount":7}]'
        '}',
        200,
        headers: {
          'content-type': ['application/json'],
        },
      );
    });
    final repository = RealAnalyticsRepository(dio);

    final summary = await repository.getSummary();

    expect(summary.activeMembers.currentCount, 12);
    expect(summary.activeMembers.countThirtyDaysAgo, 10);
    expect(summary.activeMembers.trendPercentage, 20.0);
    expect(summary.classOccupancy.overallOccupancyRate, 0.75);
    expect(summary.classOccupancy.classBreakdown, hasLength(1));
    expect(summary.classOccupancy.classBreakdown.single.className, 'Yoga');
    expect(summary.packageSales.totalCount, 5);
    expect(summary.packageSales.categoryBreakdown, hasLength(2));
    expect(summary.packageSales.categoryBreakdown.first.category, 'GroupClass');
    expect(summary.packageSales.categoryBreakdown.last.category, isNull);
    expect(summary.trainerActiveStudents.single.trainerFullName, 'Ali Antrenör');
    expect(summary.trainerActiveStudents.single.activeStudentCount, 7);
  });

  test('getSummary rethrows a DioException as ApiException', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      return ResponseBody.fromString('{"Status":403,"Errors":["Yetkiniz yok."]}', 403, headers: {
        'content-type': ['application/json'],
      });
    });
    final repository = RealAnalyticsRepository(dio);

    await expectLater(repository.getSummary, throwsA(isA<ApiException>()));
  });

  test('getSummary parses a null trendPercentage (no baseline 30 days ago)', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      return ResponseBody.fromString(
        '{'
        '"activeMembers":{"currentCount":3,"countThirtyDaysAgo":0,"trendPercentage":null},'
        '"classOccupancy":{"overallOccupancyRate":0,"classBreakdown":[]},'
        '"packageSales":{"totalCount":0,"categoryBreakdown":[]},'
        '"trainerActiveStudents":[]'
        '}',
        200,
        headers: {
          'content-type': ['application/json'],
        },
      );
    });
    final repository = RealAnalyticsRepository(dio);

    final summary = await repository.getSummary();

    expect(summary.activeMembers.trendPercentage, isNull);
    expect(summary.classOccupancy.classBreakdown, isEmpty);
    expect(summary.packageSales.categoryBreakdown, isEmpty);
    expect(summary.trainerActiveStudents, isEmpty);
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
