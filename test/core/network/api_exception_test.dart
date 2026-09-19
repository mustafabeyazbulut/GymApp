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
