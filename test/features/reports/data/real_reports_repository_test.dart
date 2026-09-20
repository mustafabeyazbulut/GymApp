import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/api_exception.dart';
import 'package:gym_app/features/reports/data/real_reports_repository.dart';

void main() {
  test('getRevenueReport sends fromDate/toDate as yyyy-MM-dd query params and parses the response', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/reports/revenue');
      expect(options.queryParameters['fromDate'], '2026-01-01');
      expect(options.queryParameters['toDate'], '2026-01-31');
      return ResponseBody.fromString(
        '{'
        '"fromDate":"2026-01-01T00:00:00Z","toDate":"2026-01-31T00:00:00Z","totalAmount":1500.0,'
        '"methodBreakdown":[{"method":"Cash","amount":1000.0},{"method":"Card","amount":500.0}],'
        '"dailyBreakdown":[{"date":"2026-01-05T00:00:00Z","amount":1500.0}]'
        '}',
        200,
        headers: {
          'content-type': ['application/json'],
        },
      );
    });
    final repository = RealReportsRepository(dio);

    final report = await repository.getRevenueReport(
      fromDate: DateTime(2026, 1, 1),
      toDate: DateTime(2026, 1, 31),
    );

    expect(report.totalAmount, 1500.0);
    expect(report.methodBreakdown, hasLength(2));
    expect(report.methodBreakdown.first.method, 'Cash');
    expect(report.dailyBreakdown.single.amount, 1500.0);
  });

  test('getRevenueReport omits query params when no range given', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.queryParameters, isEmpty);
      return ResponseBody.fromString(
        '{"fromDate":"2026-01-01T00:00:00Z","toDate":"2026-01-31T00:00:00Z","totalAmount":0.0,'
        '"methodBreakdown":[],"dailyBreakdown":[]}',
        200,
        headers: {
          'content-type': ['application/json'],
        },
      );
    });
    final repository = RealReportsRepository(dio);

    await repository.getRevenueReport();
  });

  test('getRevenueReport rethrows a DioException as ApiException', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      return ResponseBody.fromString('{"Status":403,"Errors":["Yetkiniz yok."]}', 403, headers: {
        'content-type': ['application/json'],
      });
    });
    final repository = RealReportsRepository(dio);

    await expectLater(repository.getRevenueReport, throwsA(isA<ApiException>()));
  });

  test('getOutstandingBalances parses the response from GET /api/reports/outstanding-balances', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/reports/outstanding-balances');
      return ResponseBody.fromString(
        '[{"packageAssignmentId":1,"memberFullName":"Ayşe Yılmaz","memberPhone":"5551112233",'
        '"packageName":"Aylık Üyelik","branchName":"Merkez Şube","price":1000.0,"totalPaid":400.0,'
        '"remainingBalance":600.0}]',
        200,
        headers: {
          'content-type': ['application/json'],
        },
      );
    });
    final repository = RealReportsRepository(dio);

    final balances = await repository.getOutstandingBalances();

    expect(balances, hasLength(1));
    expect(balances.single.memberFullName, 'Ayşe Yılmaz');
    expect(balances.single.remainingBalance, 600.0);
  });

  test('getOutstandingBalances rethrows a DioException as ApiException', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      return ResponseBody.fromString('{"Status":403,"Errors":["Yetkiniz yok."]}', 403, headers: {
        'content-type': ['application/json'],
      });
    });
    final repository = RealReportsRepository(dio);

    await expectLater(repository.getOutstandingBalances, throwsA(isA<ApiException>()));
  });

  test('getExpiringMemberships sends daysAhead as a query param and parses the response', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/reports/expiring-memberships');
      expect(options.queryParameters['daysAhead'], 90);
      return ResponseBody.fromString(
        '[{"packageAssignmentId":2,"memberFullName":"Mehmet Demir","memberPhone":"5552223344",'
        '"packageName":"Yıllık Üyelik","branchName":null,"endDate":"2026-01-10T00:00:00Z","daysRemaining":-5}]',
        200,
        headers: {
          'content-type': ['application/json'],
        },
      );
    });
    final repository = RealReportsRepository(dio);

    final memberships = await repository.getExpiringMemberships(daysAhead: 90);

    expect(memberships, hasLength(1));
    expect(memberships.single.branchName, isNull);
    expect(memberships.single.daysRemaining, -5);
    expect(memberships.single.isAlreadyExpired, isTrue);
  });

  test('getExpiringMemberships rethrows a DioException as ApiException', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      return ResponseBody.fromString('{"Status":403,"Errors":["Yetkiniz yok."]}', 403, headers: {
        'content-type': ['application/json'],
      });
    });
    final repository = RealReportsRepository(dio);

    await expectLater(() => repository.getExpiringMemberships(), throwsA(isA<ApiException>()));
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
