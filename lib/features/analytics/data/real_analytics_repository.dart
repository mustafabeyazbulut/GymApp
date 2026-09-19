import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/analytics_repository.dart';
import '../domain/analytics_summary.dart';

part 'real_analytics_repository.g.dart';

class RealAnalyticsRepository implements AnalyticsRepository {
  RealAnalyticsRepository(this._dio);

  final Dio _dio;

  @override
  Future<AnalyticsSummary> getSummary() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/analytics/summary');
      return AnalyticsSummary.fromJson(response.data!);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }
}

@riverpod
AnalyticsRepository analyticsRepository(Ref ref) => RealAnalyticsRepository(ref.watch(dioProvider));
