// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'membership_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

@ProviderFor(MembershipActions)
final membershipActionsProvider = MembershipActionsProvider._();

final class MembershipActionsProvider
    extends $NotifierProvider<MembershipActions, void> {
  MembershipActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'membershipActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$membershipActionsHash();

  @$internal
  @override
  MembershipActions create() => MembershipActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$membershipActionsHash() => r'4d87bd7267e523e9e2737220628d47d5a4ffc3c4';

abstract class _$MembershipActions extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
