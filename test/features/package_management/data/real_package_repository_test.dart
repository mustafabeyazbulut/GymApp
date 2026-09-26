import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/api_exception.dart';
import 'package:gym_app/features/package_management/data/real_package_repository.dart';

void main() {
  test('getPackages parses the list from GET /api/packages', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/packages');
      return ResponseBody.fromString(
        '[{"id":1,"companyId":3,"branchId":null,"name":"Aylık Üyelik","description":null,'
        '"type":"Duration","durationDays":30,"sessionCount":null,"price":1000,"accessTier":"Standard","isActive":true}]',
        200,
        headers: {'content-type': ['application/json']},
      );
    });
    final repository = RealPackageRepository(dio);

    final packages = await repository.getPackages();

    expect(packages, hasLength(1));
    expect(packages.single.name, 'Aylık Üyelik');
    expect(packages.single.isDuration, isTrue);
  });

  test('getPackages rethrows a DioException as ApiException', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      return ResponseBody.fromString('{"Status":401,"Errors":["Yetkisiz."]}', 401,
          headers: {'content-type': ['application/json']});
    });
    final repository = RealPackageRepository(dio);

    await expectLater(() => repository.getPackages(), throwsA(isA<ApiException>()));
  });

  test('createPackage posts to /api/packages with the given fields', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/packages');
      expect(options.data, {
        'companyId': 3,
        'branchId': 7,
        'name': 'Aylık Üyelik',
        'description': null,
        'type': 'Duration',
        'durationDays': 30,
        'sessionCount': null,
        'price': 1000.0,
        'maxFreezeDays': null,
      });
      return ResponseBody.fromString('{}', 201, headers: {'content-type': ['application/json']});
    });
    final repository = RealPackageRepository(dio);

    await repository.createPackage(
      companyId: 3,
      branchId: 7,
      name: 'Aylık Üyelik',
      type: 'Duration',
      durationDays: 30,
      price: 1000,
    );
  });

  test('setPackageActive patches /api/packages/{id}/active', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/packages/1/active');
      expect(options.data, {'isActive': false});
      return ResponseBody.fromString('', 204);
    });
    final repository = RealPackageRepository(dio);

    await repository.setPackageActive(packageId: 1, isActive: false);
  });

  test('assignPackage posts to /api/package-assignments', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/package-assignments');
      expect(options.data, {'packageId': 1, 'memberPhone': '+905551112233'});
      return ResponseBody.fromString('{}', 201, headers: {'content-type': ['application/json']});
    });
    final repository = RealPackageRepository(dio);

    await repository.assignPackage(packageId: 1, memberPhone: '+905551112233');
  });

  test('getPackageAssignments parses the list and forwards memberPhone as a query parameter', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/package-assignments');
      expect(options.queryParameters, {'memberPhone': '+905551112233'});
      return ResponseBody.fromString(
        '[{"id":1,"packageId":5,"packageName":"Aylık Üyelik","price":1000,"memberUserId":7,'
        '"memberFullName":"Ayşe Yılmaz","memberPhone":"+905551112233","companyId":3,"branchId":10,'
        '"startDate":"2026-01-01T00:00:00Z","endDate":null,"remainingSessions":null,"status":"Active",'
        '"totalPaid":400,"remainingBalance":600}]',
        200,
        headers: {'content-type': ['application/json']},
      );
    });
    final repository = RealPackageRepository(dio);

    final assignments = await repository.getPackageAssignments(memberPhone: '+905551112233');

    expect(assignments, hasLength(1));
    expect(assignments.single.remainingBalance, 600);
    expect(assignments.single.isFullyPaid, isFalse);
  });

  test('getPackageAssignments parses maxFreezeDays/totalFrozenDays and computes remainingFreezeDays', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      return ResponseBody.fromString(
        '[{"id":1,"packageId":5,"packageName":"Aylık Üyelik","price":1000,"memberUserId":7,'
        '"memberFullName":"Ayşe Yılmaz","memberPhone":"+905551112233","companyId":3,"branchId":10,'
        '"startDate":"2026-01-01T00:00:00Z","endDate":null,"remainingSessions":null,"status":"Active",'
        '"totalPaid":0,"remainingBalance":1000,"maxFreezeDays":30,"totalFrozenDays":10}]',
        200,
        headers: {'content-type': ['application/json']},
      );
    });
    final repository = RealPackageRepository(dio);

    final assignments = await repository.getPackageAssignments();

    expect(assignments.single.maxFreezeDays, 30);
    expect(assignments.single.remainingFreezeDays, 20);
  });

  test('cancelPackageAssignment posts to /api/package-assignments/{id}/cancel', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/package-assignments/1/cancel');
      return ResponseBody.fromString('', 204);
    });
    final repository = RealPackageRepository(dio);

    await repository.cancelPackageAssignment(1);
  });

  test('freezePackageAssignment posts to /api/package-assignments/{id}/freeze', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/package-assignments/1/freeze');
      return ResponseBody.fromString('', 204);
    });
    final repository = RealPackageRepository(dio);

    await repository.freezePackageAssignment(1);
  });

  test('unfreezePackageAssignment posts to /api/package-assignments/{id}/unfreeze', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/package-assignments/1/unfreeze');
      return ResponseBody.fromString('', 204);
    });
    final repository = RealPackageRepository(dio);

    await repository.unfreezePackageAssignment(1);
  });

  test('recordGeneralCheckIn posts to /api/package-assignments/{id}/check-in', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/package-assignments/1/check-in');
      return ResponseBody.fromString('', 204);
    });
    final repository = RealPackageRepository(dio);

    await repository.recordGeneralCheckIn(1);
  });

  test('recordPayment posts to /api/package-assignments/{id}/payments', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/package-assignments/1/payments');
      expect(options.data, {'amount': 400.0, 'method': 'Cash', 'note': null});
      return ResponseBody.fromString('{}', 201, headers: {'content-type': ['application/json']});
    });
    final repository = RealPackageRepository(dio);

    await repository.recordPayment(packageAssignmentId: 1, amount: 400, method: 'Cash');
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
