import 'notification_item.dart';

abstract interface class NotificationRepository {
  Future<List<NotificationItem>> getNotifications();

  Future<void> markRead(int notificationId);
}
