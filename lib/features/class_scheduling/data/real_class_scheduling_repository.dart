import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/class_enrollment.dart';
import '../domain/class_scheduling_repository.dart';
import '../domain/class_session.dart';

part 'real_class_scheduling_repository.g.dart';

final _dateFormat = DateFormat('yyyy-MM-dd');

class RealClassSchedulingRepository implements ClassSchedulingRepository {
  RealClassSchedulingRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<ClassSession>> getClassSessions({int? branchId, DateTime? from, DateTime? to}) async {
    final queryParameters = <String, dynamic>{};
    if (branchId != null) queryParameters['branchId'] = branchId;
    if (from != null) queryParameters['from'] = _dateFormat.format(from);
    if (to != null) queryParameters['to'] = _dateFormat.format(to);

    try {
      final response = await _dio.get<List<dynamic>>('/api/class-sessions', queryParameters: queryParameters);
      return response.data!.cast<Map<String, dynamic>>().map(ClassSession.fromJson).toList();
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<void> enroll({required int classSessionId, required int packageAssignmentId}) async {
    try {
      await _dio.post<void>(
        '/api/class-sessions/$classSessionId/enroll',
        data: {'packageAssignmentId': packageAssignmentId},
      );
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<void> cancelEnrollment(int classEnrollmentId) async {
    try {
      await _dio.post<void>('/api/class-enrollments/$classEnrollmentId/cancel');
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<List<MyClassEnrollment>> getMyEnrollments() async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/class-enrollments/mine');
      return response.data!.cast<Map<String, dynamic>>().map(MyClassEnrollment.fromJson).toList();
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<void> createClassSession({
    required int branchId,
    required int trainerUserId,
    required ClassSessionCategory category,
    required String name,
    required DateTime date,
    required String startTime,
    required String endTime,
    required int capacity,
    required int cancellationCutoffHours,
  }) async {
    try {
      await _dio.post<void>(
        '/api/class-sessions',
        data: {
          'branchId': branchId,
          'trainerUserId': trainerUserId,
          'category': classSessionCategoryToApi(category),
          'name': name,
          'date': _dateFormat.format(date),
          'startTime': startTime,
          'endTime': endTime,
          'capacity': capacity,
          'cancellationCutoffHours': cancellationCutoffHours,
        },
      );
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }
}

@riverpod
ClassSchedulingRepository classSchedulingRepository(Ref ref) => RealClassSchedulingRepository(ref.watch(dioProvider));
