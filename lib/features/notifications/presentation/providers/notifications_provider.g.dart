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
    r'0d615dad5797a347e3714d5496541f9abb27a892';

@ProviderFor(NotificationActions)
final notificationActionsProvider = NotificationActionsProvider._();

final class NotificationActionsProvider
    extends $NotifierProvider<NotificationActions, void> {
  NotificationActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationActionsHash();

  @$internal
  @override
  NotificationActions create() => NotificationActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$notificationActionsHash() =>
    r'555660b69c504495b8f49d2991e65964a5471efc';

abstract class _$NotificationActions extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
