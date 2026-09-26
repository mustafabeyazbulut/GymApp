// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invitations_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Kullanıcının bekleyen davetleri. Push/polling yok: shell'in üst çubuğu
/// (uygulama açılışı) ve Davetlerim ekranı (her girişte tazeler) izler;
/// autoDispose olduğu için çıkış yapınca bellekte kalmaz.

@ProviderFor(myInvitations)
final myInvitationsProvider = MyInvitationsProvider._();

/// Kullanıcının bekleyen davetleri. Push/polling yok: shell'in üst çubuğu
/// (uygulama açılışı) ve Davetlerim ekranı (her girişte tazeler) izler;
/// autoDispose olduğu için çıkış yapınca bellekte kalmaz.

final class MyInvitationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Invitation>>,
          List<Invitation>,
          FutureOr<List<Invitation>>
        >
    with $FutureModifier<List<Invitation>>, $FutureProvider<List<Invitation>> {
  /// Kullanıcının bekleyen davetleri. Push/polling yok: shell'in üst çubuğu
  /// (uygulama açılışı) ve Davetlerim ekranı (her girişte tazeler) izler;
  /// autoDispose olduğu için çıkış yapınca bellekte kalmaz.
  MyInvitationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myInvitationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myInvitationsHash();

  @$internal
  @override
  $FutureProviderElement<List<Invitation>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Invitation>> create(Ref ref) {
    return myInvitations(ref);
  }
}

String _$myInvitationsHash() => r'a67b0f163416d05f80485bff7871afd81115989d';

/// Menüdeki "Davetlerim" rozeti ve üst çubuktaki menü noktası için. Liste
/// yüklenemezse 0 - rozet hata göstermez, hata Davetlerim ekranında görünür.

@ProviderFor(pendingInvitationCount)
final pendingInvitationCountProvider = PendingInvitationCountProvider._();

/// Menüdeki "Davetlerim" rozeti ve üst çubuktaki menü noktası için. Liste
/// yüklenemezse 0 - rozet hata göstermez, hata Davetlerim ekranında görünür.

final class PendingInvitationCountProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Menüdeki "Davetlerim" rozeti ve üst çubuktaki menü noktası için. Liste
  /// yüklenemezse 0 - rozet hata göstermez, hata Davetlerim ekranında görünür.
  PendingInvitationCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingInvitationCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingInvitationCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return pendingInvitationCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$pendingInvitationCountHash() =>
    r'342c106a44bf6d93db14e4d196cf01155085d6b9';

@ProviderFor(InvitationActions)
final invitationActionsProvider = InvitationActionsProvider._();

final class InvitationActionsProvider
    extends $NotifierProvider<InvitationActions, void> {
  InvitationActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'invitationActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$invitationActionsHash();

  @$internal
  @override
  InvitationActions create() => InvitationActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$invitationActionsHash() => r'765dd5e9972b2216498a948158f107046cf9d5a1';

abstract class _$InvitationActions extends $Notifier<void> {
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
