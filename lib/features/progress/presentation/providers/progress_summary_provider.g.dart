// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_summary_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(progressNotes)
final progressNotesProvider = ProgressNotesFamily._();

final class ProgressNotesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProgressNote>>,
          List<ProgressNote>,
          FutureOr<List<ProgressNote>>
        >
    with
        $FutureModifier<List<ProgressNote>>,
        $FutureProvider<List<ProgressNote>> {
  ProgressNotesProvider._({
    required ProgressNotesFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'progressNotesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$progressNotesHash();

  @override
  String toString() {
    return r'progressNotesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ProgressNote>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProgressNote>> create(Ref ref) {
    final argument = this.argument as int;
    return progressNotes(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProgressNotesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$progressNotesHash() => r'09c09574fc4a2f19b1b20aa9e5839015dad41e90';

final class ProgressNotesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ProgressNote>>, int> {
  ProgressNotesFamily._()
    : super(
        retry: null,
        name: r'progressNotesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProgressNotesProvider call(int packageAssignmentId) =>
      ProgressNotesProvider._(argument: packageAssignmentId, from: this);

  @override
  String toString() => r'progressNotesProvider';
}

@ProviderFor(progressSummary)
final progressSummaryProvider = ProgressSummaryProvider._();

final class ProgressSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProgressSummary>,
          ProgressSummary,
          FutureOr<ProgressSummary>
        >
    with $FutureModifier<ProgressSummary>, $FutureProvider<ProgressSummary> {
  ProgressSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'progressSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$progressSummaryHash();

  @$internal
  @override
  $FutureProviderElement<ProgressSummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ProgressSummary> create(Ref ref) {
    return progressSummary(ref);
  }
}

String _$progressSummaryHash() => r'876a5c9962cd8c765cba46146cb1c6cb360dd0b2';
