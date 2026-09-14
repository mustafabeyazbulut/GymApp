import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/branch_repository_impl.dart';
import '../../domain/branch.dart';

part 'branch_list_provider.g.dart';

@riverpod
class BranchList extends _$BranchList {
  @override
  Future<List<Branch>> build() {
    return ref.watch(branchRepositoryProvider).getBranches();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(branchRepositoryProvider).getBranches(),
    );
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
    state = AsyncData([...?state.value, created]);
  }
}
