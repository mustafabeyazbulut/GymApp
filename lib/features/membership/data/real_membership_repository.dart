import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/membership_repository.dart';
import '../domain/membership_summary.dart';

part 'real_membership_repository.g.dart';

class RealMembershipRepository implements MembershipRepository {
  RealMembershipRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<PaymentHistoryEntry>> getPayments(int packageAssignmentId) async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/api/package-assignments/$packageAssignmentId/payments');
      final payments = (response.data!['payments'] as List).cast<Map<String, dynamic>>();
      return payments
          .map((json) => PaymentHistoryEntry(
                date: DateTime.parse(json['paidAt'] as String),
                amount: (json['amount'] as num).toDouble(),
              ))
          .toList();
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<void> requestFreeze(int packageAssignmentId) async {
    try {
      await _dio.post<void>('/api/package-assignments/$packageAssignmentId/freeze');
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<void> requestUnfreeze(int packageAssignmentId) async {
    try {
      await _dio.post<void>('/api/package-assignments/$packageAssignmentId/unfreeze');
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<void> confirmPackageAssignment(String code) async {
    try {
      await _dio.post<void>('/api/package-assignments/confirm', data: {'code': code});
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }
}

@riverpod
MembershipRepository membershipRepository(Ref ref) => RealMembershipRepository(ref.watch(dioProvider));
