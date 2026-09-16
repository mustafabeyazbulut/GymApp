import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/notifications/data/fake_notification_repository.dart';

void main() {
  test('getNotifications returns the fixed mock list', () async {
    final repository = FakeNotificationRepository();

    final notifications = await repository.getNotifications();

    expect(notifications, hasLength(4));
    expect(notifications.first.title, 'Üyeliğiniz yenilendi');
    expect(notifications.where((n) => n.isRead), hasLength(2));
  });
}
