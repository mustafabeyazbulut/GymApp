import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/api_exception.dart';
import 'package:gym_app/features/tenant_onboarding/data/real_tenant_repository.dart';

void main() {
  test('createCompany posts to /api/companies with just the company name and admin phone', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/companies');
      expect(options.data, {
        'companyName': 'Test Gym',
        'gymAdminPhone': '+905551112233',
      });
      return ResponseBody.fromString('{}', 201, headers: {'content-type': ['application/json']});
    });
    final repository = RealTenantRepository(dio);

    await repository.createCompany(companyName: 'Test Gym', gymAdminPhone: '+905551112233');
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
      () => repository.createCompany(companyName: 'x', gymAdminPhone: 'x'),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Bu işlem için yetkiniz yok.')),
    );
  });

  test('confirmAssignmentInvitation posts to /api/assignments/confirm with the code', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/assignments/confirm');
      expect(options.data, {'code': '123456'});
      return ResponseBody.fromString('{}', 201, headers: {'content-type': ['application/json']});
    });
    final repository = RealTenantRepository(dio);

    await repository.confirmAssignmentInvitation('123456');
  });

  test('inviteGymAdmin posts to /api/assignments/gym-admin with the given fields', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/assignments/gym-admin');
      expect(options.data, {'companyId': 1, 'phone': '+905551112233'});
      return ResponseBody.fromString('{}', 201, headers: {'content-type': ['application/json']});
    });
    final repository = RealTenantRepository(dio);

    await repository.inviteGymAdmin(companyId: 1, phone: '+905551112233');
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

  test('listCompanies parses the company list', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/companies');
      return ResponseBody.fromString(
        '[{"id":1,"name":"Test Gym","isActive":true,"branchCount":2}]',
        200,
        headers: {'content-type': ['application/json']},
      );
    });
    final repository = RealTenantRepository(dio);

    final companies = await repository.listCompanies();

    expect(companies, hasLength(1));
    expect(companies.single.name, 'Test Gym');
    expect(companies.single.branchCount, 2);
  });

  test('getCompanyDetail parses the company with its branches', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/companies/1');
      return ResponseBody.fromString(
        '{"id":1,"name":"Test Gym","isActive":true,"branches":[{"id":5,"name":"Merkez","address":"Adres","isActive":true}]}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });
    final repository = RealTenantRepository(dio);

    final detail = await repository.getCompanyDetail(1);

    expect(detail.name, 'Test Gym');
    expect(detail.branches, hasLength(1));
    expect(detail.branches.single.name, 'Merkez');
  });

  test('updateCompanyName patches /api/companies/{id} with the new name', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/companies/1');
      expect(options.data, {'name': 'New Name'});
      return ResponseBody.fromString('', 204);
    });
    final repository = RealTenantRepository(dio);

    await repository.updateCompanyName(companyId: 1, name: 'New Name');
  });

  test('setCompanyActive patches /api/companies/{id}/active with the new status', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/companies/1/active');
      expect(options.data, {'isActive': false});
      return ResponseBody.fromString('', 204);
    });
    final repository = RealTenantRepository(dio);

    await repository.setCompanyActive(companyId: 1, isActive: false);
  });

  test('getManagedBranches parses the list with address and isActive', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/branches');
      return ResponseBody.fromString(
        '[{"id":1,"companyId":3,"name":"Merkez","address":"Adres 1","isActive":true}]',
        200,
        headers: {'content-type': ['application/json']},
      );
    });
    final repository = RealTenantRepository(dio);

    final branches = await repository.getManagedBranches();

    expect(branches, hasLength(1));
    expect(branches.single.address, 'Adres 1');
    expect(branches.single.isActive, isTrue);
  });

  test('createBranch posts to /api/branches with the given fields', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/branches');
      expect(options.data, {'companyId': 3, 'name': 'Merkez', 'address': 'Adres 1'});
      return ResponseBody.fromString('{}', 201, headers: {'content-type': ['application/json']});
    });
    final repository = RealTenantRepository(dio);

    await repository.createBranch(companyId: 3, name: 'Merkez', address: 'Adres 1');
  });

  test('updateBranch patches /api/branches/{id} with the given fields', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/branches/1');
      expect(options.data, {'name': 'Yeni Ad', 'address': 'Yeni Adres'});
      return ResponseBody.fromString('', 204);
    });
    final repository = RealTenantRepository(dio);

    await repository.updateBranch(branchId: 1, name: 'Yeni Ad', address: 'Yeni Adres');
  });

  test('setBranchActive patches /api/branches/{id}/active', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/branches/1/active');
      expect(options.data, {'isActive': false});
      return ResponseBody.fromString('', 204);
    });
    final repository = RealTenantRepository(dio);

    await repository.setBranchActive(branchId: 1, isActive: false);
  });

  test('addStaffMember posts to /api/assignments/staff with the given fields', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '/api/assignments/staff');
      expect(options.data, {
        'phone': '+905550003333',
        'role': 'Trainer',
        'branchId': 10,
      });
      return ResponseBody.fromString('{}', 201, headers: {'content-type': ['application/json']});
    });
    final repository = RealTenantRepository(dio);

    await repository.addStaffMember(
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
