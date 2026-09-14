import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException({required this.statusCode, required this.errors});

  final int statusCode;
  final List<String> errors;

  String get message => errors.isNotEmpty
      ? errors.join('\n')
      : 'Beklenmeyen bir hata oluştu.';

  /// Reads `ExceptionMiddleware`'s response shape, which is deliberately
  /// PascalCase (`Status`/`Errors`) unlike the rest of the API's camelCase
  /// success responses — the backend's success JSON uses camelCase but its
  /// error middleware serializes with default (PascalCase) casing, a known
  /// asymmetry confirmed directly from the GymAppApi backend source.
  factory ApiException.fromDioException(DioException exception) {
    final data = exception.response?.data;

    if (data is Map) {
      final rawErrors = data['Errors'];
      final errors = rawErrors is List
          ? rawErrors.map((e) => e.toString()).toList()
          : <String>[];

      return ApiException(
        statusCode: exception.response?.statusCode ?? 0,
        errors: errors.isNotEmpty
            ? errors
            : ['Beklenmeyen bir hata oluştu.'],
      );
    }

    return const ApiException(
      statusCode: 0,
      errors: ['Bağlantı hatası, lütfen tekrar deneyin.'],
    );
  }

  @override
  String toString() => 'ApiException($statusCode, $errors)';
}
