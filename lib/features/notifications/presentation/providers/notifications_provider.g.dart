// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(notifications)
final notificationsProvider = NotificationsProvider._();

final class NotificationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<NotificationItem>>,
          List<NotificationItem>,
          FutureOr<List<NotificationItem>>
        >
    with
        $FutureModifier<List<NotificationItem>>,
        $FutureProvider<List<NotificationItem>> {
  NotificationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationsHash();

  @$internal
  @override
  $FutureProviderElement<List<NotificationItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<NotificationItem>> create(Ref ref) {
    return notifications(ref);
  }
}

String _$notificationsHash() => r'5e3326ae79b8788df65e7160279db5b6d55ad5e8';

@ProviderFor(hasUnreadNotifications)
final hasUnreadNotificationsProvider = HasUnreadNotificationsProvider._();

final class HasUnreadNotificationsProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  HasUnreadNotificationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hasUnreadNotificationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hasUnreadNotificationsHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return hasUnreadNotifications(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$hasUnreadNotificationsHash() =>
    r'0b8cf08b8488c49046ac579538798139b45de5ae';
