// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'real_package_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(packageRepository)
final packageRepositoryProvider = PackageRepositoryProvider._();

final class PackageRepositoryProvider
    extends
        $FunctionalProvider<
          PackageRepository,
          PackageRepository,
          PackageRepository
        >
    with $Provider<PackageRepository> {
  PackageRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'packageRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$packageRepositoryHash();

  @$internal
  @override
  $ProviderElement<PackageRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PackageRepository create(Ref ref) {
    return packageRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PackageRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PackageRepository>(value),
    );
  }
}

String _$packageRepositoryHash() => r'7178982172affd2d4ba2e89b5c8ac9335187185e';
