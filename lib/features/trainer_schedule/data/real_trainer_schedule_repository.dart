import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/my_reservation.dart';
import '../domain/trainer_schedule_repository.dart';

part 'real_trainer_schedule_repository.g.dart';

class RealTrainerScheduleRepository implements TrainerScheduleRepository {
  RealTrainerScheduleRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<MyReservation>> getMyReservations() async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/reservations/mine');
      return response.data!.cast<Map<String, dynamic>>().map(MyReservation.fromJson).toList();
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<void> checkIn(int reservationId) => _postAction(reservationId, 'check-in');

  @override
  Future<void> markNoShow(int reservationId) => _postAction(reservationId, 'no-show');

  @override
  Future<void> cancel(int reservationId) => _postAction(reservationId, 'cancel');

  Future<void> _postAction(int reservationId, String action) async {
    try {
      await _dio.post<void>('/api/reservations/$reservationId/$action');
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }
}

@riverpod
TrainerScheduleRepository trainerScheduleRepository(Ref ref) => RealTrainerScheduleRepository(ref.watch(dioProvider));
