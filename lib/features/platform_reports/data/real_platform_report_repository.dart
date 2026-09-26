import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/platform_report.dart';
import '../domain/platform_report_repository.dart';

part 'real_platform_report_repository.g.dart';

class RealPlatformReportRepository implements PlatformReportRepository {
  RealPlatformReportRepository(this._dio);

  final Dio _dio;

  @override
  Future<PlatformReportSummary> getSummary(ReportPeriod period) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/platform-reports/summary',
        queryParameters: {'days': period.days},
      );
      return PlatformReportSummary.fromJson(response.data!);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<List<BranchReportRow>> getCompanyBranches(int companyId, ReportPeriod period) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/api/platform-reports/companies/$companyId/branches',
        queryParameters: {'days': period.days},
      );
      return response.data!.cast<Map<String, dynamic>>().map(BranchReportRow.fromJson).toList();
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }
}

@riverpod
PlatformReportRepository platformReportRepository(Ref ref) => RealPlatformReportRepository(ref.watch(dioProvider));
