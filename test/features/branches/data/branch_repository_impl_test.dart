import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/api_exception.dart';
import 'package:gym_app/features/branches/data/branch_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late BranchRepositoryImpl repository;

  setUp(() {
    dio = _MockDio();
    repository = BranchRepositoryImpl(dio);
  });

  group('getBranches', () {
    test('maps a camelCase JSON array into a list of Branch', () async {
      when(() => dio.get('/api/branches')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/branches'),
          statusCode: 200,
          data: [
            {'id': 1, 'companyId': 1, 'name': 'Merkez Şube', 'address': 'Adres 1', 'isActive': true},
            {'id': 2, 'companyId': 1, 'name': 'Kadıköy Şube', 'address': 'Adres 2', 'isActive': false},
          ],
        ),
      );

      final branches = await repository.getBranches();

      expect(branches, hasLength(2));
      expect(branches[0].name, 'Merkez Şube');
      expect(branches[1].isActive, false);
    });

    test('rethrows DioException as ApiException', () async {
      final requestOptions = RequestOptions(path: '/api/branches');
      when(() => dio.get('/api/branches')).thenThrow(
        DioException(
          requestOptions: requestOptions,
          response: Response(
            requestOptions: requestOptions,
            statusCode: 500,
            data: {'Status': 500, 'Errors': ['Beklenmeyen bir hata oluştu.']},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(() => repository.getBranches(), throwsA(isA<ApiException>()));
    });
  });

  group('createBranch', () {
    test('posts a camelCase body and maps the 201 result', () async {
      when(() => dio.post(
            '/api/branches',
            data: {'companyId': 1, 'name': 'Yeni Şube', 'address': 'Yeni Adres'},
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/branches'),
          statusCode: 201,
          data: {'id': 5, 'name': 'Yeni Şube'},
        ),
      );

      final branch = await repository.createBranch(
        companyId: 1,
        name: 'Yeni Şube',
        address: 'Yeni Adres',
      );

      expect(branch.id, 5);
      expect(branch.name, 'Yeni Şube');
      expect(branch.companyId, 1);
      expect(branch.address, 'Yeni Adres');
      expect(branch.isActive, true);
    });

    test('rethrows a 404 CompanyNotFoundException as ApiException', () async {
      final requestOptions = RequestOptions(path: '/api/branches');
      when(() => dio.post(
            '/api/branches',
            data: {'companyId': 999, 'name': 'X', 'address': 'Y'},
          )).thenThrow(
        DioException(
          requestOptions: requestOptions,
          response: Response(
            requestOptions: requestOptions,
            statusCode: 404,
            data: {'Status': 404, 'Errors': ['Company 999 bulunamadı.']},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      try {
        await repository.createBranch(companyId: 999, name: 'X', address: 'Y');
        fail('expected ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 404);
        expect(e.errors, ['Company 999 bulunamadı.']);
      }
    });
  });
}
