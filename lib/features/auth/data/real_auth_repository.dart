import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/secure_token_store.dart';
import '../../../core/network/token_store.dart';
import '../domain/auth_exceptions.dart';
import '../domain/auth_repository.dart';
import '../domain/me_result.dart';

part 'real_auth_repository.g.dart';

class RealAuthRepository implements AuthRepository {
  RealAuthRepository(this._dio, this._tokenStore);

  final Dio _dio;
  final TokenStore _tokenStore;

  @override
  Future<void> register({
    required String fullName,
    required String phone,
    String? email,
    required String password,
  }) async {
    final response = await _guard(() => _dio.post<Map<String, dynamic>>('/api/auth/register', data: {
          'fullName': fullName,
          'phone': phone,
          'email': email,
          'password': password,
        }));
    await _storeTokenPair(response.data!);
  }

  @override
  Future<void> login({required String identifier, required String password}) async {
    final response = await _guard(() => _dio.post<Map<String, dynamic>>('/api/auth/login', data: {
          'identifier': identifier,
          'password': password,
        }));
    await _storeTokenPair(response.data!);
  }

  @override
  Future<void> logout() async {
    await _tokenStore.clear();
  }

  @override
  Future<void> forgotPassword({required String identifier}) async {
    await _guard(() => _dio.post<Map<String, dynamic>>('/api/auth/forgot-password', data: {
          'identifier': identifier,
        }));
  }

  @override
  Future<void> resetPassword({
    required String identifier,
    required String code,
    required String newPassword,
  }) async {
    await _guard(() => _dio.post<void>('/api/auth/reset-password', data: {
          'identifier': identifier,
          'code': code,
          'newPassword': newPassword,
        }));
  }

  @override
  Future<MeResult> getMe() async {
    final response = await _guard(() => _dio.get<Map<String, dynamic>>('/api/auth/me'));
    return MeResult.fromJson(response.data!);
  }

  Future<void> _storeTokenPair(Map<String, dynamic> data) => _tokenStore.saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );

  Future<Response<T>> _guard<T>(Future<Response<T>> Function() call) async {
    try {
      return await call();
    } on DioException catch (exception) {
      throw _mapException(exception);
    }
  }

  AuthException _mapException(DioException exception) {
    final statusCode = exception.response?.statusCode;
    if (statusCode == null) {
      return const NetworkAuthException();
    }
    if (statusCode == 401) {
      return const InvalidCredentialsException();
    }

    final data = exception.response?.data;
    final message = data is Map && data['Errors'] is List && (data['Errors'] as List).isNotEmpty
        ? (data['Errors'] as List).first.toString()
        : 'Beklenmeyen bir hata oluştu.';

    if (statusCode == 409) {
      return ConflictAuthException(message);
    }
    return GenericAuthException(message);
  }
}

@riverpod
AuthRepository authRepository(Ref ref) => RealAuthRepository(ref.watch(dioProvider), ref.watch(tokenStoreProvider));
