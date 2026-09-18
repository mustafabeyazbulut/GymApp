import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/branch_option.dart';
import '../domain/company_summary.dart';
import '../domain/tenant_repository.dart';

part 'real_tenant_repository.g.dart';

class RealTenantRepository implements TenantRepository {
  RealTenantRepository(this._dio);

  final Dio _dio;

  @override
  Future<void> createCompany({
    required String companyName,
    required String gymAdminPhone,
  }) async {
    try {
      await _dio.post<void>('/api/companies', data: {
        'companyName': companyName,
        'gymAdminPhone': gymAdminPhone,
      });
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<void> confirmAssignmentInvitation(String code) async {
    try {
      await _dio.post<void>('/api/assignments/confirm', data: {'code': code});
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<void> inviteGymAdmin({required int companyId, required String phone}) async {
    try {
      await _dio.post<void>('/api/assignments/gym-admin', data: {
        'companyId': companyId,
        'phone': phone,
      });
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<List<CompanyListItem>> listCompanies() async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/companies');
      return response.data!
          .cast<Map<String, dynamic>>()
          .map(CompanyListItem.fromJson)
          .toList();
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<CompanyDetail> getCompanyDetail(int companyId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/companies/$companyId');
      return CompanyDetail.fromJson(response.data!);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<void> updateCompanyName({required int companyId, required String name}) async {
    try {
      await _dio.patch<void>('/api/companies/$companyId', data: {'name': name});
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<void> setCompanyActive({required int companyId, required bool isActive}) async {
    try {
      await _dio.patch<void>('/api/companies/$companyId/active', data: {'isActive': isActive});
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<List<BranchOption>> listBranches() async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/branches');
      return response.data!
          .cast<Map<String, dynamic>>()
          .map(BranchOption.fromJson)
          .toList();
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<void> addStaffMember({
    required String phone,
    required String role,
    required int branchId,
  }) async {
    try {
      await _dio.post<void>('/api/assignments/staff', data: {
        'phone': phone,
        'role': role,
        'branchId': branchId,
      });
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }
}

@riverpod
TenantRepository tenantRepository(Ref ref) => RealTenantRepository(ref.watch(dioProvider));
