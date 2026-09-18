// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_staff_company_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ActiveStaffCompanyId)
final activeStaffCompanyIdProvider = ActiveStaffCompanyIdProvider._();

final class ActiveStaffCompanyIdProvider
    extends $NotifierProvider<ActiveStaffCompanyId, int?> {
  ActiveStaffCompanyIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeStaffCompanyIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeStaffCompanyIdHash();

  @$internal
  @override
  ActiveStaffCompanyId create() => ActiveStaffCompanyId();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$activeStaffCompanyIdHash() =>
    r'17ed463daa36ec4e49c436c313c1454445b6600c';

abstract class _$ActiveStaffCompanyId extends $Notifier<int?> {
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
