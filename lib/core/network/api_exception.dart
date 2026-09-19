import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart' show BuildContext;

import '../../l10n/generated/app_localizations.dart';

class ApiException implements Exception {
  const ApiException({required this.statusCode, required this.errors});

  final int statusCode;
  final List<String> errors;

  /// Sunucudan hiç yanıt gelmedi (bağlantı/timeout hatası) - bu durumda
  /// errors her zaman boştur, çünkü sunucu hiç konuşmadı.
  bool get isConnectionError => statusCode == 0;

  /// Gösterilecek metni ÇAĞRILDIĞI ANDA (BuildContext olan yerde) çözer -
  /// sunucudan gelen errors zaten backend'in kendi yerelleştirmesiyle doğru
  /// dilde geliyor; sadece istemci tarafı fallback'ler (boş errors, bağlantı
  /// hatası) burada AppLocalizations'a bakıyor.
  String localizedMessage(BuildContext context) {
    if (errors.isNotEmpty) return errors.join('\n');
    final l10n = AppLocalizations.of(context)!;
    return isConnectionError ? l10n.commonConnectionError : l10n.commonError;
  }

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
        errors: errors,
      );
    }

    return const ApiException(statusCode: 0, errors: []);
  }

  @override
  String toString() => 'ApiException($statusCode, $errors)';
}
