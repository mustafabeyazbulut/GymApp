// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_staff_assignment_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(activeAssignmentStore)
final activeAssignmentStoreProvider = ActiveAssignmentStoreProvider._();

final class ActiveAssignmentStoreProvider
    extends
        $FunctionalProvider<
          ActiveAssignmentStore,
          ActiveAssignmentStore,
          ActiveAssignmentStore
        >
    with $Provider<ActiveAssignmentStore> {
  ActiveAssignmentStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeAssignmentStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeAssignmentStoreHash();

  @$internal
  @override
  $ProviderElement<ActiveAssignmentStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ActiveAssignmentStore create(Ref ref) {
    return activeAssignmentStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActiveAssignmentStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActiveAssignmentStore>(value),
    );
  }
}

String _$activeAssignmentStoreHash() =>
    r'1c2e337593fed91b440335251f421d7c9639e609';

/// Personelin şu an hangi görevle (firma + şube + rol) hareket ettiği - değer
/// seçilen atamanın Id'sidir; null = kullanıcı seçim yapmadı.
///
/// Bu değer ham seçimdir: kullanıcının atamalarından biriyle eşleşmiyorsa
/// (atama kaldırıldı, cihazda başka kullanıcıdan kaldı) çözümleme
/// MeResult.activeStaffAssignment'ta varsayılan kurala döner. dioProvider
/// çözümlenen görevi her isteğe X-Active-Assignment-Id olarak ekler; backend
/// bu değere çağıranın kendi ataması olmadıkça güvenmez (403).
///
/// keepAlive: dioProvider'ın interceptor'ı bunu her istekte okuyor - dinleyen
/// ekran yokken dispose olsaydı seçim kaybolurdu (bkz. dio_client.dart'taki
/// keepAlive notu).

@ProviderFor(ActiveStaffAssignment)
final activeStaffAssignmentProvider = ActiveStaffAssignmentProvider._();

/// Personelin şu an hangi görevle (firma + şube + rol) hareket ettiği - değer
/// seçilen atamanın Id'sidir; null = kullanıcı seçim yapmadı.
///
/// Bu değer ham seçimdir: kullanıcının atamalarından biriyle eşleşmiyorsa
/// (atama kaldırıldı, cihazda başka kullanıcıdan kaldı) çözümleme
/// MeResult.activeStaffAssignment'ta varsayılan kurala döner. dioProvider
/// çözümlenen görevi her isteğe X-Active-Assignment-Id olarak ekler; backend
/// bu değere çağıranın kendi ataması olmadıkça güvenmez (403).
///
/// keepAlive: dioProvider'ın interceptor'ı bunu her istekte okuyor - dinleyen
/// ekran yokken dispose olsaydı seçim kaybolurdu (bkz. dio_client.dart'taki
/// keepAlive notu).
final class ActiveStaffAssignmentProvider
    extends $NotifierProvider<ActiveStaffAssignment, int?> {
  /// Personelin şu an hangi görevle (firma + şube + rol) hareket ettiği - değer
  /// seçilen atamanın Id'sidir; null = kullanıcı seçim yapmadı.
  ///
  /// Bu değer ham seçimdir: kullanıcının atamalarından biriyle eşleşmiyorsa
  /// (atama kaldırıldı, cihazda başka kullanıcıdan kaldı) çözümleme
  /// MeResult.activeStaffAssignment'ta varsayılan kurala döner. dioProvider
  /// çözümlenen görevi her isteğe X-Active-Assignment-Id olarak ekler; backend
  /// bu değere çağıranın kendi ataması olmadıkça güvenmez (403).
  ///
  /// keepAlive: dioProvider'ın interceptor'ı bunu her istekte okuyor - dinleyen
  /// ekran yokken dispose olsaydı seçim kaybolurdu (bkz. dio_client.dart'taki
  /// keepAlive notu).
  ActiveStaffAssignmentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeStaffAssignmentProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeStaffAssignmentHash();

  @$internal
  @override
  ActiveStaffAssignment create() => ActiveStaffAssignment();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$activeStaffAssignmentHash() =>
    r'7dc58586d0cf396211dfa46f4ee65b6526c2bd0d';

/// Personelin şu an hangi görevle (firma + şube + rol) hareket ettiği - değer
/// seçilen atamanın Id'sidir; null = kullanıcı seçim yapmadı.
///
/// Bu değer ham seçimdir: kullanıcının atamalarından biriyle eşleşmiyorsa
/// (atama kaldırıldı, cihazda başka kullanıcıdan kaldı) çözümleme
/// MeResult.activeStaffAssignment'ta varsayılan kurala döner. dioProvider
/// çözümlenen görevi her isteğe X-Active-Assignment-Id olarak ekler; backend
/// bu değere çağıranın kendi ataması olmadıkça güvenmez (403).
///
/// keepAlive: dioProvider'ın interceptor'ı bunu her istekte okuyor - dinleyen
/// ekran yokken dispose olsaydı seçim kaybolurdu (bkz. dio_client.dart'taki
/// keepAlive notu).

abstract class _$ActiveStaffAssignment extends $Notifier<int?> {
  int? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int?, int?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int?, int?>,
              int?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
