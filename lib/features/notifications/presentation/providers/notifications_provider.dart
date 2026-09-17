import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/fake_notification_repository.dart';
import '../../domain/notification_item.dart';

part 'notifications_provider.g.dart';

@riverpod
Future<List<NotificationItem>> notifications(Ref ref) {
  return ref.watch(notificationRepositoryProvider).getNotifications();
}

@riverpod
bool hasUnreadNotifications(Ref ref) {
  final notifications = ref.watch(notificationsProvider).asData?.value;
  return notifications?.any((notification) => !notification.isRead) ?? false;
}
