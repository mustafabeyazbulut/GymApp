// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'membership_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Membership)
final membershipProvider = MembershipProvider._();

final class MembershipProvider
    extends $AsyncNotifierProvider<Membership, MembershipSummary> {
  MembershipProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'membershipProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$membershipHash();

  @$internal
  @override
  Membership create() => Membership();
}

String _$membershipHash() => r'bdedc6a09e3d257b71237889d2da5be18017ef5f';

abstract class _$Membership extends $AsyncNotifier<MembershipSummary> {
  FutureOr<MembershipSummary> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<MembershipSummary>, MembershipSummary>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<MembershipSummary>, MembershipSummary>,
              AsyncValue<MembershipSummary>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
