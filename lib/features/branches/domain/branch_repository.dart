import 'branch.dart';

abstract interface class BranchRepository {
  Future<List<Branch>> getBranches();

  Future<Branch> createBranch({
    required int companyId,
    required String name,
    required String address,
  });
}
