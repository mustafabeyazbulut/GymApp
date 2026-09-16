import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/notifications/data/fake_notification_repository.dart';
import 'package:gym_app/features/notifications/domain/notification_item.dart';
import 'package:gym_app/features/notifications/domain/notification_repository.dart';
import 'package:gym_app/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockNotificationRepository extends Mock implements NotificationRepository {}

void main() {
  test('loads the notifications from the repository', () async {
    final repository = _MockNotificationRepository();
    when(() => repository.getNotifications()).thenAnswer(
      (_) async => const [
        NotificationItem(id: '1', title: 'Test', message: 'Test mesaj', timeLabel: 'Şimdi'),
      ],
    );
    final container = ProviderContainer(
      overrides: [notificationRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final notifications = await container.read(notificationsProvider.future);

    expect(notifications, hasLength(1));
    expect(notifications.single.title, 'Test');
  });
}
