import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/personal_log.dart';
import '../domain/personal_log_repository.dart';

part 'real_personal_log_repository.g.dart';

class RealPersonalLogRepository implements PersonalLogRepository {
  RealPersonalLogRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<PersonalLog>> list({required DateTime from, required DateTime to}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/api/personal-logs',
        queryParameters: {'from': personalLogApiDate(from), 'to': personalLogApiDate(to)},
      );
      return response.data!.cast<Map<String, dynamic>>().map(PersonalLog.fromJson).toList();
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<PersonalLog> create(PersonalLogDraft draft) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/api/personal-logs', data: draft.toJson());
      return PersonalLog.fromJson(response.data!);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<PersonalLog> update(int id, PersonalLogDraft draft) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>('/api/personal-logs/$id', data: draft.toJson());
      return PersonalLog.fromJson(response.data!);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<void> delete(int id) async {
    try {
      await _dio.delete<void>('/api/personal-logs/$id');
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }
}

@riverpod
PersonalLogRepository personalLogRepository(Ref ref) => RealPersonalLogRepository(ref.watch(dioProvider));
