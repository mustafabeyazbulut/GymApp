import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/package_assignment_summary.dart';
import '../domain/package_repository.dart';
import '../domain/package_summary.dart';

part 'real_package_repository.g.dart';

class RealPackageRepository implements PackageRepository {
  RealPackageRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<PackageSummary>> getPackages() async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/packages');
      return response.data!
          .cast<Map<String, dynamic>>()
          .map(PackageSummary.fromJson)
          .toList();
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<void> createPackage({
    required int companyId,
    required int branchId,
    required String name,
    String? description,
    required String type,
    int? durationDays,
    int? sessionCount,
    required double price,
    int? maxFreezeDays,
  }) async {
    try {
      await _dio.post<void>('/api/packages', data: {
        'companyId': companyId,
        'branchId': branchId,
        'name': name,
        'description': description,
        'type': type,
        'durationDays': durationDays,
        'sessionCount': sessionCount,
        'price': price,
        'maxFreezeDays': maxFreezeDays,
      });
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<void> setPackageActive({required int packageId, required bool isActive}) async {
    try {
      await _dio.patch<void>('/api/packages/$packageId/active', data: {'isActive': isActive});
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<void> assignPackage({required int packageId, required String memberPhone}) async {
    try {
      await _dio.post<void>('/api/package-assignments', data: {
        'packageId': packageId,
        'memberPhone': memberPhone,
      });
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<List<PackageAssignmentSummary>> getPackageAssignments({String? memberPhone}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/api/package-assignments',
        queryParameters: memberPhone == null || memberPhone.isEmpty ? null : {'memberPhone': memberPhone},
      );
      return response.data!
          .cast<Map<String, dynamic>>()
          .map(PackageAssignmentSummary.fromJson)
          .toList();
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<void> cancelPackageAssignment(int packageAssignmentId) async {
    try {
      await _dio.post<void>('/api/package-assignments/$packageAssignmentId/cancel');
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<void> freezePackageAssignment(int packageAssignmentId) async {
    try {
      await _dio.post<void>('/api/package-assignments/$packageAssignmentId/freeze');
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<void> unfreezePackageAssignment(int packageAssignmentId) async {
    try {
      await _dio.post<void>('/api/package-assignments/$packageAssignmentId/unfreeze');
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<void> recordGeneralCheckIn(int packageAssignmentId) async {
    try {
      await _dio.post<void>('/api/package-assignments/$packageAssignmentId/check-in');
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<void> recordPayment({
    required int packageAssignmentId,
    required double amount,
    required String method,
    String? note,
  }) async {
    try {
      await _dio.post<void>('/api/package-assignments/$packageAssignmentId/payments', data: {
        'amount': amount,
        'method': method,
        'note': note,
      });
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }
}

@riverpod
PackageRepository packageRepository(Ref ref) => RealPackageRepository(ref.watch(dioProvider));
