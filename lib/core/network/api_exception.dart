import 'dart:convert';

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
    final response = exception.response;
    if (response == null) {
      // Sunucudan hiç yanıt gelmedi - gerçek bir bağlantı/timeout hatası.
      return const ApiException(statusCode: 0, errors: []);
    }

    // Bir yanıt VAR ama gövdesi JSON olmayabilir/boş olabilir (ör.
    // [Authorize(Policy=...)] politikasının ürettiği, hiç gövdesi olmayan
    // düz bir 403) - bu durumda bile GERÇEK durum kodunu koru. Önceden bu
    // dal `statusCode: 0` (bağlantı hatası) döndürüyordu, bu da ör. yetkisiz
    // bir kullanıcının SuperAdmin'e özel bir ekrana girmeye çalışmasını
    // "bağlantı kurulamadı" gibi tamamen yanlış bir mesajla gösteriyordu.
    final data = _decodeBytesBody(response.data);
    final errors = data is Map && data['Errors'] is List
        ? (data['Errors'] as List).map((e) => e.toString()).toList()
        : <String>[];

    return ApiException(statusCode: response.statusCode ?? 0, errors: errors);
  }

  // responseType.bytes ile yapılan isteklerde (ör. medya indirme) hata gövdesi
  // de bayt olarak gelir - JSON'sa çözülür ki backend'in yerelleştirilmiş
  // mesajı kaybolmasın. Çözülemezse gövdesiz yanıt gibi ele alınır.
  static Object? _decodeBytesBody(Object? data) {
    if (data is! List<int>) return data;
    try {
      return jsonDecode(utf8.decode(data));
    } on FormatException {
      return null;
    }
  }

  @override
  String toString() => 'ApiException($statusCode, $errors)';
}
