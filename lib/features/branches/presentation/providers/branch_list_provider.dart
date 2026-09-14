import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/branch_repository_impl.dart';
import '../../domain/branch.dart';

part 'branch_list_provider.g.dart';

@riverpod
class BranchList extends _$BranchList {
  /// The last successfully loaded list, kept independently of [state].
  ///
  /// `AsyncValue.copyWithPrevious` — the framework's own mechanism for
  /// carrying a previous value forward into a failed refresh's `AsyncError`
  /// — was made `@internal` in riverpod 3.x (not usable from application
  /// code; confirmed against the installed `riverpod-3.4.3` source, where
  /// using it trips the `invalid_use_of_internal_member` analyzer warning).
  /// Without it, `state.value` goes back to `null` after a failed
  /// [refresh], which would make [addBranch] silently drop every
  /// previously-loaded branch. This field is this notifier's own cache of
  /// the last known-good list so [addBranch] never depends on `state.value`
  /// directly.
  List<Branch> _lastKnownBranches = const [];

  @override
  Future<List<Branch>> build() async {
    final branches = await ref.watch(branchRepositoryProvider).getBranches();
    _lastKnownBranches = branches;
    return branches;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(branchRepositoryProvider).getBranches(),
    );
    final value = state.value;
    if (value != null) {
      _lastKnownBranches = value;
    }
  }

  /// Lets `DioException`/`ApiException` propagate to the caller (the form
  /// screen) instead of being swallowed into state — the form is what needs
  /// to show `ApiException.errors` to the user, per the spec.
  Future<void> addBranch({
    required int companyId,
    required String name,
    required String address,
  }) async {
    final repository = ref.read(branchRepositoryProvider);
    final created = await repository.createBranch(
      companyId: companyId,
      name: name,
      address: address,
    );
    _lastKnownBranches = [..._lastKnownBranches, created];
    state = AsyncData(_lastKnownBranches);
  }
}
