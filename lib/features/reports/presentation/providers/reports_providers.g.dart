// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reports_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RevenueReportNotifier)
final revenueReportProvider = RevenueReportNotifierProvider._();

final class RevenueReportNotifierProvider
    extends $AsyncNotifierProvider<RevenueReportNotifier, RevenueReport> {
  RevenueReportNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'revenueReportProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$revenueReportNotifierHash();

  @$internal
  @override
  RevenueReportNotifier create() => RevenueReportNotifier();
}

String _$revenueReportNotifierHash() =>
    r'8b6a68a2737977e8007ff9655e4038ed9c4f37b3';

abstract class _$RevenueReportNotifier extends $AsyncNotifier<RevenueReport> {
  FutureOr<RevenueReport> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<RevenueReport>, RevenueReport>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<RevenueReport>, RevenueReport>,
              AsyncValue<RevenueReport>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(OutstandingBalancesNotifier)
final outstandingBalancesProvider = OutstandingBalancesNotifierProvider._();

final class OutstandingBalancesNotifierProvider
    extends
        $AsyncNotifierProvider<
          OutstandingBalancesNotifier,
          List<OutstandingBalance>
        > {
  OutstandingBalancesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'outstandingBalancesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$outstandingBalancesNotifierHash();

  @$internal
  @override
  OutstandingBalancesNotifier create() => OutstandingBalancesNotifier();
}

String _$outstandingBalancesNotifierHash() =>
    r'd1a4c45e01a9a15b90f5ceefb6c1ff20fcde032f';

abstract class _$OutstandingBalancesNotifier
    extends $AsyncNotifier<List<OutstandingBalance>> {
  FutureOr<List<OutstandingBalance>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<OutstandingBalance>>,
              List<OutstandingBalance>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<OutstandingBalance>>,
                List<OutstandingBalance>
              >,
              AsyncValue<List<OutstandingBalance>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(ExpiringMembershipsNotifier)
final expiringMembershipsProvider = ExpiringMembershipsNotifierProvider._();

final class ExpiringMembershipsNotifierProvider
    extends
        $AsyncNotifierProvider<
          ExpiringMembershipsNotifier,
          List<ExpiringMembership>
        > {
  ExpiringMembershipsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'expiringMembershipsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expiringMembershipsNotifierHash();

  @$internal
  @override
  ExpiringMembershipsNotifier create() => ExpiringMembershipsNotifier();
}

String _$expiringMembershipsNotifierHash() =>
    r'7850c02f1671a487dca29a3ae5400f1ae6afdbcc';

abstract class _$ExpiringMembershipsNotifier
    extends $AsyncNotifier<List<ExpiringMembership>> {
  FutureOr<List<ExpiringMembership>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<ExpiringMembership>>,
              List<ExpiringMembership>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<ExpiringMembership>>,
                List<ExpiringMembership>
              >,
              AsyncValue<List<ExpiringMembership>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
