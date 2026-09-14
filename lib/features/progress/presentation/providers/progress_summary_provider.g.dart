// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_summary_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(progressSummary)
final progressSummaryProvider = ProgressSummaryFamily._();

final class ProgressSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProgressSummary>,
          ProgressSummary,
          FutureOr<ProgressSummary>
        >
    with $FutureModifier<ProgressSummary>, $FutureProvider<ProgressSummary> {
  ProgressSummaryProvider._({
    required ProgressSummaryFamily super.from,
    required ProgressCategory super.argument,
  }) : super(
         retry: null,
         name: r'progressSummaryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$progressSummaryHash();

  @override
  String toString() {
    return r'progressSummaryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ProgressSummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ProgressSummary> create(Ref ref) {
    final argument = this.argument as ProgressCategory;
    return progressSummary(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProgressSummaryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$progressSummaryHash() => r'8459159e6f23b52685f053009316effeee3658d3';

final class ProgressSummaryFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<ProgressSummary>, ProgressCategory> {
  ProgressSummaryFamily._()
    : super(
        retry: null,
        name: r'progressSummaryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProgressSummaryProvider call(ProgressCategory category) =>
      ProgressSummaryProvider._(argument: category, from: this);

  @override
  String toString() => r'progressSummaryProvider';
}
