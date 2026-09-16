import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/notification_item.dart';
import '../domain/notification_repository.dart';

part 'fake_notification_repository.g.dart';

class FakeNotificationRepository implements NotificationRepository {
  @override
  Future<List<NotificationItem>> getNotifications() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const [
      NotificationItem(
        id: '1',
        title: 'Üyeliğiniz yenilendi',
        message: 'BJJ + Fitness Aylık paketiniz başarıyla yenilendi.',
        timeLabel: '2 saat önce',
      ),
      NotificationItem(
        id: '2',
        title: 'Yeni ders eklendi',
        message: 'Cuma günleri 19:00\'da yeni bir BJJ Temel dersi eklendi.',
        timeLabel: 'Dün',
      ),
      NotificationItem(
        id: '3',
        title: 'Ödemeniz alındı',
        message: '₺2.500 tutarındaki ödemeniz başarıyla alındı.',
        timeLabel: '3 gün önce',
        isRead: true,
      ),
      NotificationItem(
        id: '4',
        title: 'Antrenman hatırlatması',
        message: 'Bugün 19:00\'daki BJJ Temel dersine katılmayı unutmayın.',
        timeLabel: '1 hafta önce',
        isRead: true,
      ),
    ];
  }
}

@riverpod
NotificationRepository notificationRepository(Ref ref) => FakeNotificationRepository();
