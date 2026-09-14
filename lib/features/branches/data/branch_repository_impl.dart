import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/branch.dart';
import '../domain/branch_repository.dart';
import 'branch_dto.dart';

part 'branch_repository_impl.g.dart';

class BranchRepositoryImpl implements BranchRepository {
  BranchRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<Branch>> getBranches() async {
    try {
      final response = await _dio.get('/api/branches');
      final items = response.data as List<dynamic>? ?? const [];
      return items
          .map((json) => BranchDto.fromJson(json as Map<String, dynamic>).toDomain())
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<Branch> createBranch({
    required int companyId,
    required String name,
    required String address,
  }) async {
    try {
      final response = await _dio.post(
        '/api/branches',
        data: {'companyId': companyId, 'name': name, 'address': address},
      );
      final id = (response.data as Map<String, dynamic>)['id'] as int;
      return Branch(
        id: id,
        companyId: companyId,
        name: name,
        address: address,
        isActive: true,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

@riverpod
BranchRepository branchRepository(Ref ref) {
  return BranchRepositoryImpl(ref.watch(dioProvider));
}
