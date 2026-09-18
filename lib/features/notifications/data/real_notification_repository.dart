import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/notification_item.dart';
import '../domain/notification_repository.dart';

part 'real_notification_repository.g.dart';

class RealNotificationRepository implements NotificationRepository {
  RealNotificationRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<NotificationItem>> getNotifications() async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/notifications');
      return response.data!
          .cast<Map<String, dynamic>>()
          .map(NotificationItem.fromJson)
          .toList();
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<void> markRead(int notificationId) async {
    try {
      await _dio.patch<void>('/api/notifications/$notificationId/read');
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }
}

@riverpod
NotificationRepository notificationRepository(Ref ref) => RealNotificationRepository(ref.watch(dioProvider));
