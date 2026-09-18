import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/real_notification_repository.dart';
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

// Kendi state'i yok, sadece markRead'i sunuyor - başarı sonrası
// notificationsProvider'ı invalidate ederek hem liste hem de
// hasUnreadNotifications'ın (aynı veriden türediği için) otomatik
// güncellenmesini sağlıyor.
@riverpod
class NotificationActions extends _$NotificationActions {
  @override
  void build() {}

  Future<void> markRead(int notificationId) async {
    await ref.read(notificationRepositoryProvider).markRead(notificationId);
    ref.invalidate(notificationsProvider);
  }
}
