// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fake_membership_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(membershipRepository)
final membershipRepositoryProvider = MembershipRepositoryProvider._();

final class MembershipRepositoryProvider
    extends
        $FunctionalProvider<
          MembershipRepository,
          MembershipRepository,
          MembershipRepository
        >
    with $Provider<MembershipRepository> {
  MembershipRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'membershipRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$membershipRepositoryHash();

  @$internal
  @override
  $ProviderElement<MembershipRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MembershipRepository create(Ref ref) {
    return membershipRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MembershipRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MembershipRepository>(value),
    );
  }
}

String _$membershipRepositoryHash() =>
    r'a7e47ec6ba3c3f2d0859a0dd1cfed98918d27607';
