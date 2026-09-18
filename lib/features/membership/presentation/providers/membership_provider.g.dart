// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'membership_provider.dart';

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

String _$membershipsHash() => r'ee8ea3930d9b3d57f242667368cdff471611bf31';

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

@ProviderFor(membershipPayments)
final membershipPaymentsProvider = MembershipPaymentsFamily._();

final class MembershipPaymentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PaymentHistoryEntry>>,
          List<PaymentHistoryEntry>,
          FutureOr<List<PaymentHistoryEntry>>
        >
    with
        $FutureModifier<List<PaymentHistoryEntry>>,
        $FutureProvider<List<PaymentHistoryEntry>> {
  MembershipPaymentsProvider._({
    required MembershipPaymentsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'membershipPaymentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$membershipPaymentsHash();

  @override
  String toString() {
    return r'membershipPaymentsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<PaymentHistoryEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PaymentHistoryEntry>> create(Ref ref) {
    final argument = this.argument as int;
    return membershipPayments(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MembershipPaymentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$membershipPaymentsHash() =>
    r'8352334f801bb03a174fe6ebe1cfc633ca2e7324';

final class MembershipPaymentsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<PaymentHistoryEntry>>, int> {
  MembershipPaymentsFamily._()
    : super(
        retry: null,
        name: r'membershipPaymentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MembershipPaymentsProvider call(int packageAssignmentId) =>
      MembershipPaymentsProvider._(argument: packageAssignmentId, from: this);

  @override
  String toString() => r'membershipPaymentsProvider';
}
