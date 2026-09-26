import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/api_exception.dart';

void main() {
  group('ApiException.fromDioException', () {
    test('parses the PascalCase Status/Errors body from ExceptionMiddleware', () {
      final requestOptions = RequestOptions(path: '/api/branches');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 404,
          data: {
            'Status': 404,
            'Errors': ['Company 999 bulunamadı.'],
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final result = ApiException.fromDioException(dioException);

      expect(result.statusCode, 404);
      expect(result.errors, ['Company 999 bulunamadı.']);
    });

    test('preserves the real status code for a bodyless response (e.g. a plain [Authorize] 403)', () {
      // Kritik bug buradaydı: [Authorize(Policy=...)] başarısızlığı hiç
      // gövdesi olmayan düz bir 403 döndürür - eski kod 'data is Map'
      // olmadığı için bunu statusCode: 0 (bağlantı hatası) sayıyordu,
      // yetkisiz bir kullanıcıya "bağlantı kurulamadı" gibi tamamen
      // yanlış bir mesaj gösteriyordu.
      final requestOptions = RequestOptions(path: '/api/companies');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 403, data: null),
        type: DioExceptionType.badResponse,
      );

      final result = ApiException.fromDioException(dioException);

      expect(result.statusCode, 403);
      expect(result.isConnectionError, isFalse);
    });

    // Medya uçları responseType.bytes ile çağrılıyor - hata gövdesi de bayt
    // olarak geliyor; backend'in yerelleştirilmiş mesajı kaybolmamalı.
    test('bayt olarak gelen JSON hata gövdesini de ayrıştırır', () {
      final requestOptions = RequestOptions(path: '/api/media/5');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 403,
          data: utf8.encode('{"Status":403,"Errors":["Bu medya dosyasını görüntüleme yetkiniz yok."]}'),
        ),
        type: DioExceptionType.badResponse,
      );

      final result = ApiException.fromDioException(dioException);

      expect(result.statusCode, 403);
      expect(result.errors, ['Bu medya dosyasını görüntüleme yetkiniz yok.']);
    });

    test('JSON olmayan bayt gövdede boş errors ile durum kodunu korur', () {
      final requestOptions = RequestOptions(path: '/api/media/5');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 403, data: [0xff, 0x00]),
        type: DioExceptionType.badResponse,
      );

      final result = ApiException.fromDioException(dioException);

      expect(result.statusCode, 403);
      expect(result.errors, isEmpty);
    });

    test('marks a connection error (no response body) with empty errors, resolved via AppLocalizations at display time', () {
      final requestOptions = RequestOptions(path: '/api/branches');
      final dioException = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.connectionError,
      );

      final result = ApiException.fromDioException(dioException);

      expect(result.statusCode, 0);
      expect(result.errors, isEmpty);
      expect(result.isConnectionError, isTrue);
    });
  });
}
