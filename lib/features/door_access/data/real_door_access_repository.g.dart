// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'real_door_access_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(doorAccessRepository)
final doorAccessRepositoryProvider = DoorAccessRepositoryProvider._();

final class DoorAccessRepositoryProvider
    extends
        $FunctionalProvider<
          DoorAccessRepository,
          DoorAccessRepository,
          DoorAccessRepository
        >
    with $Provider<DoorAccessRepository> {
  DoorAccessRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'doorAccessRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$doorAccessRepositoryHash();

  @$internal
  @override
  $ProviderElement<DoorAccessRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DoorAccessRepository create(Ref ref) {
    return doorAccessRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DoorAccessRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DoorAccessRepository>(value),
    );
  }
}

String _$doorAccessRepositoryHash() =>
    r'393a455bab8af2fe0f5e33de87e41a578cc20864';
