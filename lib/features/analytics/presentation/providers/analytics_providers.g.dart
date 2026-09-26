// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AnalyticsSummaryNotifier)
final analyticsSummaryProvider = AnalyticsSummaryNotifierProvider._();

final class AnalyticsSummaryNotifierProvider
    extends $AsyncNotifierProvider<AnalyticsSummaryNotifier, AnalyticsSummary> {
  AnalyticsSummaryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analyticsSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analyticsSummaryNotifierHash();

  @$internal
  @override
  AnalyticsSummaryNotifier create() => AnalyticsSummaryNotifier();
}

String _$analyticsSummaryNotifierHash() =>
    r'e743153676ee8b93a6b059cd64c65ec467752f23';

abstract class _$AnalyticsSummaryNotifier
    extends $AsyncNotifier<AnalyticsSummary> {
  FutureOr<AnalyticsSummary> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<AnalyticsSummary>, AnalyticsSummary>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AnalyticsSummary>, AnalyticsSummary>,
              AsyncValue<AnalyticsSummary>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
