import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/progress_repository.dart';
import '../domain/progress_summary.dart';

part 'real_progress_repository.g.dart';

class RealProgressRepository implements ProgressRepository {
  RealProgressRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<ProgressNote>> getProgressNotes(int packageAssignmentId) async {
    try {
      final response =
          await _dio.get<List<dynamic>>('/api/package-assignments/$packageAssignmentId/progress-notes');
      return response.data!.cast<Map<String, dynamic>>().map(ProgressNote.fromJson).toList();
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<void> recordProgressNote({
    required int packageAssignmentId,
    required int techniqueScore,
    required int conditionScore,
    String? noteText,
    String? mediaFilePath,
    String? mediaFileName,
    String? mediaMimeType,
  }) async {
    try {
      final formData = FormData.fromMap({
        'techniqueScore': techniqueScore,
        'conditionScore': conditionScore,
        'noteText': ?noteText,
        if (mediaFilePath != null)
          'mediaFile': await MultipartFile.fromFile(
            mediaFilePath,
            filename: mediaFileName,
            contentType: mediaMimeType == null ? null : MediaType.parse(mediaMimeType),
          ),
      });
      await _dio.post<void>('/api/package-assignments/$packageAssignmentId/progress-notes', data: formData);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }
}

@riverpod
ProgressRepository progressRepository(Ref ref) => RealProgressRepository(ref.watch(dioProvider));
