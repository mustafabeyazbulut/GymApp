// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(packages)
final packagesProvider = PackagesProvider._();

final class PackagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PackageSummary>>,
          List<PackageSummary>,
          FutureOr<List<PackageSummary>>
        >
    with
        $FutureModifier<List<PackageSummary>>,
        $FutureProvider<List<PackageSummary>> {
  PackagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'packagesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$packagesHash();

  @$internal
  @override
  $FutureProviderElement<List<PackageSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PackageSummary>> create(Ref ref) {
    return packages(ref);
  }
}

String _$packagesHash() => r'b761c207055911c82edce1e17773f27b77af3d56';

@ProviderFor(packageAssignments)
final packageAssignmentsProvider = PackageAssignmentsFamily._();

final class PackageAssignmentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PackageAssignmentSummary>>,
          List<PackageAssignmentSummary>,
          FutureOr<List<PackageAssignmentSummary>>
        >
    with
        $FutureModifier<List<PackageAssignmentSummary>>,
        $FutureProvider<List<PackageAssignmentSummary>> {
  PackageAssignmentsProvider._({
    required PackageAssignmentsFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'packageAssignmentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$packageAssignmentsHash();

  @override
  String toString() {
    return r'packageAssignmentsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<PackageAssignmentSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PackageAssignmentSummary>> create(Ref ref) {
    final argument = this.argument as String?;
    return packageAssignments(ref, memberPhone: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PackageAssignmentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$packageAssignmentsHash() =>
    r'059906cd4ecdc243c1ba9d5569c32d46cae6e6ec';

final class PackageAssignmentsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<PackageAssignmentSummary>>,
          String?
        > {
  PackageAssignmentsFamily._()
    : super(
        retry: null,
        name: r'packageAssignmentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PackageAssignmentsProvider call({String? memberPhone}) =>
      PackageAssignmentsProvider._(argument: memberPhone, from: this);

  @override
  String toString() => r'packageAssignmentsProvider';
}

@ProviderFor(PackageActions)
final packageActionsProvider = PackageActionsProvider._();

final class PackageActionsProvider
    extends $NotifierProvider<PackageActions, void> {
  PackageActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'packageActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$packageActionsHash();

  @$internal
  @override
  PackageActions create() => PackageActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$packageActionsHash() => r'4bb76924576898a1b9f5b8d3df949804887ed06b';

abstract class _$PackageActions extends $Notifier<void> {
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
