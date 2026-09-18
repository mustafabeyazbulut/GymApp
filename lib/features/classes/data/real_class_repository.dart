import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/check_in.dart';
import '../domain/class_repository.dart';
import '../domain/reservation.dart';
import '../domain/trainer.dart';

part 'real_class_repository.g.dart';

class RealClassRepository implements ClassRepository {
  RealClassRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<Trainer>> getTrainers(int packageAssignmentId) async {
    try {
      final response =
          await _dio.get<List<dynamic>>('/api/package-assignments/$packageAssignmentId/trainers');
      return response.data!.cast<Map<String, dynamic>>().map(Trainer.fromJson).toList();
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<List<Reservation>> getReservations(int packageAssignmentId) async {
    try {
      final response =
          await _dio.get<List<dynamic>>('/api/package-assignments/$packageAssignmentId/reservations');
      return response.data!.cast<Map<String, dynamic>>().map(Reservation.fromJson).toList();
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<List<CheckIn>> getCheckIns(int packageAssignmentId) async {
    try {
      final response =
          await _dio.get<List<dynamic>>('/api/package-assignments/$packageAssignmentId/check-ins');
      return response.data!.cast<Map<String, dynamic>>().map(CheckIn.fromJson).toList();
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<void> createReservation({
    required int packageAssignmentId,
    required int trainerId,
    required DateTime scheduledAt,
  }) async {
    try {
      await _dio.post<void>('/api/reservations', data: {
        'packageAssignmentId': packageAssignmentId,
        'trainerId': trainerId,
        'scheduledAt': scheduledAt.toUtc().toIso8601String(),
      });
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<void> cancelReservation(int reservationId) async {
    try {
      await _dio.post<void>('/api/reservations/$reservationId/cancel');
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }
}

@riverpod
ClassRepository classRepository(Ref ref) => RealClassRepository(ref.watch(dioProvider));
