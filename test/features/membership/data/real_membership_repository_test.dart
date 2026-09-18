import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/api_exception.dart';
import 'package:gym_app/features/membership/data/real_membership_repository.dart';

void main() {
  test('getPayments parses the payments list from GET /api/package-assignments/{id}/payments', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/package-assignments/20/payments');
      return ResponseBody.fromString(
        '{"payments":[{"id":1,"amount":1500,"method":"Cash","paidAt":"2026-01-01T00:00:00","note":null}],'
        '"totalPaid":1500,"remainingBalance":0}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });
    final repository = RealMembershipRepository(dio);

    final payments = await repository.getPayments(20);

    expect(payments, hasLength(1));
    expect(payments.single.amount, 1500.0);
    expect(payments.single.date, DateTime(2026, 1, 1));
  });

  test('getPayments rethrows a DioException as ApiException', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      return ResponseBody.fromString(
        '{"Status":403,"Errors":["Bu paket atamasının ödemelerini görme yetkiniz yok."]}',
        403,
        headers: {'content-type': ['application/json']},
      );
    });
    final repository = RealMembershipRepository(dio);

    await expectLater(
      () => repository.getPayments(20),
      throwsA(isA<ApiException>().having(
        (e) => e.message,
        'message',
        'Bu paket atamasının ödemelerini görme yetkiniz yok.',
      )),
    );
  });

  test('requestFreeze posts to /api/package-assignments/{id}/freeze', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/package-assignments/20/freeze');
      return ResponseBody.fromString('', 204);
    });
    final repository = RealMembershipRepository(dio);

    await repository.requestFreeze(20);
  });

  test('requestUnfreeze posts to /api/package-assignments/{id}/unfreeze', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/package-assignments/20/unfreeze');
      return ResponseBody.fromString('', 204);
    });
    final repository = RealMembershipRepository(dio);

    await repository.requestUnfreeze(20);
  });

  test('confirmPackageAssignment posts to /api/package-assignments/confirm with the code', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/package-assignments/confirm');
      expect(options.data, {'code': '654321'});
      return ResponseBody.fromString('{}', 201, headers: {'content-type': ['application/json']});
    });
    final repository = RealMembershipRepository(dio);

    await repository.confirmPackageAssignment('654321');
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
