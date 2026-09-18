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
