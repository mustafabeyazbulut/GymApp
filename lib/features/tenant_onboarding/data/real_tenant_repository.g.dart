// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'real_tenant_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tenantRepository)
final tenantRepositoryProvider = TenantRepositoryProvider._();

final class TenantRepositoryProvider
    extends
        $FunctionalProvider<
          TenantRepository,
          TenantRepository,
          TenantRepository
        >
    with $Provider<TenantRepository> {
  TenantRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tenantRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tenantRepositoryHash();

  @$internal
  @override
  $ProviderElement<TenantRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TenantRepository create(Ref ref) {
    return tenantRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TenantRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TenantRepository>(value),
    );
  }
}

String _$tenantRepositoryHash() => r'9288d5251478c7e4a2dd30d495982f730b6ec185';
