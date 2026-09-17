import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/api_exception.dart';
import 'package:gym_app/features/tenant_onboarding/data/real_tenant_repository.dart';

void main() {
  test('createCompany posts to /api/companies with the given fields', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/companies');
      expect(options.data, {
        'companyName': 'Test Gym',
        'branchName': 'Merkez',
        'branchAddress': 'Adres',
        'gymAdminFullName': 'Ada Admin',
        'gymAdminPhone': '+905551112233',
        'gymAdminEmail': null,
      });
      return ResponseBody.fromString('{}', 201, headers: {'content-type': ['application/json']});
    });
    final repository = RealTenantRepository(dio);

    await repository.createCompany(
      companyName: 'Test Gym',
      branchName: 'Merkez',
      branchAddress: 'Adres',
      gymAdminFullName: 'Ada Admin',
      gymAdminPhone: '+905551112233',
    );
  });

  test('createCompany rethrows a DioException as ApiException', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      return ResponseBody.fromString(
        '{"Status":403,"Errors":["Bu işlem için yetkiniz yok."]}',
        403,
        headers: {'content-type': ['application/json']},
      );
    });
    final repository = RealTenantRepository(dio);

    await expectLater(
      () => repository.createCompany(
        companyName: 'x', branchName: 'x', branchAddress: 'x',
        gymAdminFullName: 'x', gymAdminPhone: 'x',
      ),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Bu işlem için yetkiniz yok.')),
    );
  });

  test('listBranches parses the branch list', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/branches');
      return ResponseBody.fromString(
        '[{"id":1,"name":"Merkez","address":"a","isActive":true}]',
        200,
        headers: {'content-type': ['application/json']},
      );
    });
    final repository = RealTenantRepository(dio);

    final branches = await repository.listBranches();

    expect(branches, hasLength(1));
    expect(branches.single.name, 'Merkez');
  });

  test('addStaffMember posts to /api/assignments/staff with the given fields', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/assignments/staff');
      expect(options.data, {
        'fullName': 'New Trainer',
        'phone': '+905550003333',
        'email': null,
        'role': 'Trainer',
        'branchId': 10,
      });
      return ResponseBody.fromString('{}', 201, headers: {'content-type': ['application/json']});
    });
    final repository = RealTenantRepository(dio);

    await repository.addStaffMember(
      fullName: 'New Trainer',
      phone: '+905550003333',
      role: 'Trainer',
      branchId: 10,
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
