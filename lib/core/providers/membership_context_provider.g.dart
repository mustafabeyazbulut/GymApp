// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'membership_context_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(memberships)
final membershipsProvider = MembershipsProvider._();

final class MembershipsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MembershipSummary>>,
          List<MembershipSummary>,
          FutureOr<List<MembershipSummary>>
        >
    with
        $FutureModifier<List<MembershipSummary>>,
        $FutureProvider<List<MembershipSummary>> {
  MembershipsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'membershipsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$membershipsHash();

  @$internal
  @override
  $FutureProviderElement<List<MembershipSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MembershipSummary>> create(Ref ref) {
    return memberships(ref);
  }
}

String _$membershipsHash() => r'b4000c332acc216f676daaec4f26b6fd8c11cf1c';

@ProviderFor(SelectedMembershipId)
final selectedMembershipIdProvider = SelectedMembershipIdProvider._();

final class SelectedMembershipIdProvider
    extends $NotifierProvider<SelectedMembershipId, int?> {
  SelectedMembershipIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedMembershipIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedMembershipIdHash();

  @$internal
  @override
  SelectedMembershipId create() => SelectedMembershipId();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$selectedMembershipIdHash() =>
    r'aae4e17ee397ea46466b44cb787389247e774f5b';

abstract class _$SelectedMembershipId extends $Notifier<int?> {
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
