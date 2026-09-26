// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'platform_report_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SelectedReportPeriod)
final selectedReportPeriodProvider = SelectedReportPeriodProvider._();

final class SelectedReportPeriodProvider
    extends $NotifierProvider<SelectedReportPeriod, ReportPeriod> {
  SelectedReportPeriodProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedReportPeriodProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedReportPeriodHash();

  @$internal
  @override
  SelectedReportPeriod create() => SelectedReportPeriod();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReportPeriod value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReportPeriod>(value),
    );
  }
}

String _$selectedReportPeriodHash() =>
    r'c86e9581b23b9020a6b04cfc9bbcaf69aac00968';

abstract class _$SelectedReportPeriod extends $Notifier<ReportPeriod> {
  ReportPeriod build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ReportPeriod, ReportPeriod>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ReportPeriod, ReportPeriod>,
              ReportPeriod,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(platformReportSummary)
final platformReportSummaryProvider = PlatformReportSummaryProvider._();

final class PlatformReportSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<PlatformReportSummary>,
          PlatformReportSummary,
          FutureOr<PlatformReportSummary>
        >
    with
        $FutureModifier<PlatformReportSummary>,
        $FutureProvider<PlatformReportSummary> {
  PlatformReportSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'platformReportSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$platformReportSummaryHash();

  @$internal
  @override
  $FutureProviderElement<PlatformReportSummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PlatformReportSummary> create(Ref ref) {
    return platformReportSummary(ref);
  }
}

String _$platformReportSummaryHash() =>
    r'e4a5e9371d8f7ac42b1fc486677e1bd8f742ac23';

@ProviderFor(companyBranchReport)
final companyBranchReportProvider = CompanyBranchReportFamily._();

final class CompanyBranchReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BranchReportRow>>,
          List<BranchReportRow>,
          FutureOr<List<BranchReportRow>>
        >
    with
        $FutureModifier<List<BranchReportRow>>,
        $FutureProvider<List<BranchReportRow>> {
  CompanyBranchReportProvider._({
    required CompanyBranchReportFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'companyBranchReportProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$companyBranchReportHash();

  @override
  String toString() {
    return r'companyBranchReportProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<BranchReportRow>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<BranchReportRow>> create(Ref ref) {
    final argument = this.argument as int;
    return companyBranchReport(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CompanyBranchReportProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$companyBranchReportHash() =>
    r'd70b460dc386c93551b45c6557a122ee518e799e';

final class CompanyBranchReportFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<BranchReportRow>>, int> {
  CompanyBranchReportFamily._()
    : super(
        retry: null,
        name: r'companyBranchReportProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CompanyBranchReportProvider call(int companyId) =>
      CompanyBranchReportProvider._(argument: companyId, from: this);

  @override
  String toString() => r'companyBranchReportProvider';
}
