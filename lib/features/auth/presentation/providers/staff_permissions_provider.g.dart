// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_permissions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Aktif göreve göre yetki matrisi - kullanıcı yüklenmediyse hiçbir yetki
/// yoktur. Menü, rota korumaları ve personel ekranları bunu izler; görev
/// değişince hepsi birlikte yeniden hesaplanır.

@ProviderFor(staffPermissions)
final staffPermissionsProvider = StaffPermissionsProvider._();

/// Aktif göreve göre yetki matrisi - kullanıcı yüklenmediyse hiçbir yetki
/// yoktur. Menü, rota korumaları ve personel ekranları bunu izler; görev
/// değişince hepsi birlikte yeniden hesaplanır.

final class StaffPermissionsProvider
    extends
        $FunctionalProvider<
          StaffPermissions,
          StaffPermissions,
          StaffPermissions
        >
    with $Provider<StaffPermissions> {
  /// Aktif göreve göre yetki matrisi - kullanıcı yüklenmediyse hiçbir yetki
  /// yoktur. Menü, rota korumaları ve personel ekranları bunu izler; görev
  /// değişince hepsi birlikte yeniden hesaplanır.
  StaffPermissionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'staffPermissionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$staffPermissionsHash();

  @$internal
  @override
  $ProviderElement<StaffPermissions> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StaffPermissions create(Ref ref) {
    return staffPermissions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StaffPermissions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StaffPermissions>(value),
    );
  }
}

String _$staffPermissionsHash() => r'd5d46735e84fa259346abddfcf8673f9999bfeed';
