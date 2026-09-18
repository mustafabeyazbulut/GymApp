import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException({required this.statusCode, required this.errors});

  final int statusCode;
  final List<String> errors;

  String get message => errors.isNotEmpty
      ? errors.join('\n')
      : 'Beklenmeyen bir hata oluştu.';

  /// `ExceptionMiddleware`'in yanıt şeklini okur; bu şekil, API'nin geri
  /// kalanının camelCase başarı yanıtlarının aksine bilinçli olarak
  /// PascalCase'dir (`Status`/`Errors`) — backend'in başarı JSON'u camelCase
  /// kullanır ama error middleware'i varsayılan (PascalCase) casing ile
  /// serialize eder; bu, doğrudan GymAppApi backend kaynağından doğrulanmış
  /// bilinen bir asimetridir.
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
