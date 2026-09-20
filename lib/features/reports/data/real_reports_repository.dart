import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/expiring_membership.dart';
import '../domain/outstanding_balance.dart';
import '../domain/reports_repository.dart';
import '../domain/revenue_report.dart';

part 'real_reports_repository.g.dart';

String _dateOnly(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class RealReportsRepository implements ReportsRepository {
  RealReportsRepository(this._dio);

  final Dio _dio;

  @override
  Future<RevenueReport> getRevenueReport({DateTime? fromDate, DateTime? toDate}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/reports/revenue', queryParameters: {
        if (fromDate != null) 'fromDate': _dateOnly(fromDate),
        if (toDate != null) 'toDate': _dateOnly(toDate),
      });
      return RevenueReport.fromJson(response.data!);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<List<OutstandingBalance>> getOutstandingBalances() async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/reports/outstanding-balances');
      return response.data!.map((e) => OutstandingBalance.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<List<ExpiringMembership>> getExpiringMemberships({int daysAhead = 30}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/api/reports/expiring-memberships',
        queryParameters: {'daysAhead': daysAhead},
      );
      return response.data!.map((e) => ExpiringMembership.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }
}

@riverpod
ReportsRepository reportsRepository(Ref ref) => RealReportsRepository(ref.watch(dioProvider));
