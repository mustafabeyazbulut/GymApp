import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/fake_notification_repository.dart';
import '../../domain/notification_item.dart';

part 'notifications_provider.g.dart';

@riverpod
Future<List<NotificationItem>> notifications(Ref ref) {
  return ref.watch(notificationRepositoryProvider).getNotifications();
}
