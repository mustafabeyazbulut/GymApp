// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'branch_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BranchList)
final branchListProvider = BranchListProvider._();

final class BranchListProvider
    extends $AsyncNotifierProvider<BranchList, List<Branch>> {
  BranchListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'branchListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$branchListHash();

  @$internal
  @override
  BranchList create() => BranchList();
}

String _$branchListHash() => r'a7ea94b078cb2f1b644ee7aeb1db2e2b4e27a10c';

abstract class _$BranchList extends $AsyncNotifier<List<Branch>> {
  FutureOr<List<Branch>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Branch>>, List<Branch>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Branch>>, List<Branch>>,
              AsyncValue<List<Branch>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
