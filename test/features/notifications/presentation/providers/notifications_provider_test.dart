import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/notifications/data/real_notification_repository.dart';
import 'package:gym_app/features/notifications/domain/notification_item.dart';
import 'package:gym_app/features/notifications/domain/notification_repository.dart';
import 'package:gym_app/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockNotificationRepository extends Mock implements NotificationRepository {}

void main() {
  late _MockNotificationRepository repository;
  late ProviderContainer container;

  final unread = NotificationItem(id: 1, title: 'Unread', body: 'Test', isRead: false, createdAt: DateTime(2026, 1, 1));
  final read = NotificationItem(id: 2, title: 'Read', body: 'Test', isRead: true, createdAt: DateTime(2026, 1, 1));

  setUp(() {
    repository = _MockNotificationRepository();
    container = ProviderContainer(overrides: [
      notificationRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);
  });

  test('loads the notifications from the repository', () async {
    when(() => repository.getNotifications()).thenAnswer((_) async => [unread]);

    final notifications = await container.read(notificationsProvider.future);

    expect(notifications, hasLength(1));
    expect(notifications.single.title, 'Unread');
  });

  test('hasUnreadNotifications is true when at least one notification is unread', () async {
    when(() => repository.getNotifications()).thenAnswer((_) async => [read, unread]);

    await container.read(notificationsProvider.future);

    expect(container.read(hasUnreadNotificationsProvider), isTrue);
  });

  test('hasUnreadNotifications is false when every notification is read', () async {
    when(() => repository.getNotifications()).thenAnswer((_) async => [read]);

    await container.read(notificationsProvider.future);

    expect(container.read(hasUnreadNotificationsProvider), isFalse);
  });

  test('NotificationActions.markRead calls the repository then invalidates notificationsProvider', () async {
    when(() => repository.getNotifications()).thenAnswer((_) async => [unread]);
    when(() => repository.markRead(1)).thenAnswer((_) async {});

    await container.read(notificationsProvider.future);
    await container.read(notificationActionsProvider.notifier).markRead(1);
    await container.read(notificationsProvider.future);

    verify(() => repository.markRead(1)).called(1);
    verify(() => repository.getNotifications()).called(2);
  });
}
