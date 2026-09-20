import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/secure_token_store.dart';
import '../../../core/network/token_store.dart';
import '../domain/content_item.dart';
import '../domain/content_library_repository.dart';

part 'real_content_library_repository.g.dart';

class RealContentLibraryRepository implements ContentLibraryRepository {
  RealContentLibraryRepository(this._dio, this._tokenStore);

  final Dio _dio;
  final TokenStore _tokenStore;

  @override
  Future<List<ContentItem>> getContentItems() async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/content-items');
      return response.data!.map((e) => ContentItem.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<ContentItem> createContentItem({
    required String title,
    String? description,
    required String requiredAccessTier,
    int? branchId,
    required String filePath,
    required String fileName,
    required String mimeType,
  }) async {
    try {
      final formData = FormData.fromMap({
        'title': title,
        'description': ?description,
        'requiredAccessTier': requiredAccessTier,
        'branchId': ?branchId,
        'file': await MultipartFile.fromFile(filePath, filename: fileName, contentType: MediaType.parse(mimeType)),
      });
      final response = await _dio.post<Map<String, dynamic>>('/api/content-items', data: formData);
      // Backend sadece Id/Title/MediaFileId döner - tam bir ContentItem
      // göstermek için listeyi yeniden çekmek yerine, çağıran taraf
      // (ContentLibraryNotifier) zaten upload sonrası refresh() çağırıyor.
      return ContentItem(
        id: response.data!['id'] as int,
        companyId: 0,
        branchId: branchId,
        title: response.data!['title'] as String,
        description: description,
        requiredAccessTier: requiredAccessTier,
        mediaFileId: response.data!['mediaFileId'] as int,
        mediaContentType: mimeType,
        isActive: true,
        createdAt: DateTime.now(),
        hasAccess: true,
      );
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<void> setContentItemActive({required int id, required bool isActive}) async {
    try {
      await _dio.patch<void>('/api/content-items/$id/active', data: {'isActive': isActive});
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<List<int>> downloadMediaBytes(int mediaFileId) async {
    try {
      final response = await _dio.get<List<int>>(
        '/api/media/$mediaFileId',
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data!;
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  String mediaUrl(int mediaFileId) => '${_dio.options.baseUrl}/api/media/$mediaFileId';

  @override
  Future<Map<String, String>> mediaAuthHeaders() async {
    final accessToken = await _tokenStore.readAccessToken();
    return accessToken == null ? {} : {'Authorization': 'Bearer $accessToken'};
  }
}

@riverpod
ContentLibraryRepository contentLibraryRepository(Ref ref) =>
    RealContentLibraryRepository(ref.watch(dioProvider), ref.watch(tokenStoreProvider));
