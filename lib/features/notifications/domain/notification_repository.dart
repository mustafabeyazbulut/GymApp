import 'notification_item.dart';

abstract interface class NotificationRepository {
  Future<List<NotificationItem>> getNotifications();
}
