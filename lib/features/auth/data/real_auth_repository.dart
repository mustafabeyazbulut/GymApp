import 'dart:async';

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
  Future<void> requestRegistrationOtp({required String phone, String? email}) async {
    await _guard(() => _dio.post<void>('/api/auth/register/request-otp', data: {
          'phone': phone,
          'email': email,
        }));
  }

  @override
  Future<void> completeRegistration({
    required String fullName,
    required String phone,
    required String phoneCode,
    String? email,
    String? emailCode,
    required String password,
  }) async {
    final response = await _guard(() => _dio.post<Map<String, dynamic>>('/api/auth/register/complete', data: {
          'fullName': fullName,
          'phone': phone,
          'phoneCode': phoneCode,
          'email': email,
          'emailCode': emailCode,
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
    // MeResult.fromJson, _guard'ın try/catch bloğunun dışında çalışır, bu yüzden bir JSON ayrıştırma
    // hatası (ör. bir cast hatası) burada AuthException olarak değil, ham bir hata olarak ortaya çıkar.
    return MeResult.fromJson(response.data!);
  }

  @override
  Future<void> requestDeleteAccountOtp() async {
    await _guard(() => _dio.post<void>('/api/auth/me/delete/request-otp'));
  }

  @override
  Future<void> deleteAccount({required String code}) async {
    await _guard(() => _dio.delete<void>('/api/auth/me', data: {'code': code}));
    await _tokenStore.clear();
  }

  @override
  Future<void> updatePreferredLanguage(String language) async {
    await _guard(() => _dio.patch<void>('/api/auth/me/language', data: {'language': language}));
  }

  @override
  Future<void> requestFreezeOtp() async {
    await _guard(() => _dio.post<void>('/api/auth/me/freeze/request-otp'));
  }

  @override
  Future<void> freezeAccount({required String code}) async {
    await _guard(() => _dio.post<void>('/api/auth/me/freeze', data: {'code': code}));
  }

  @override
  Future<void> requestUnfreezeOtp() async {
    await _guard(() => _dio.post<void>('/api/auth/me/unfreeze/request-otp'));
  }

  @override
  Future<void> reactivateAccount({required String code}) async {
    await _guard(() => _dio.post<void>('/api/auth/me/unfreeze', data: {'code': code}));
  }

  Future<void> _storeTokenPair(Map<String, dynamic> data) => _tokenStore.saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );

  Future<Response<T>> _guard<T>(Future<Response<T>> Function() call) async {
    try {
      // Dio'nun kendi connectTimeout/receiveTimeout'u sadece istek GERÇEKTEN
      // ağa çıktıktan sonraki fazı ölçüyor - istek, dio_client.dart'taki
      // auth interceptor'ın kendi await zincirinde (token okuma, 401'de
      // refresh çağrısı) askıda kalırsa bu süre hiç işlemiyor. Docker/WSL2
      // NAT'ın sessizce düşürdüğü bir bağlantı yüzünden bu tür bir askıda
      // kalma yaşanırsa, bu son çare zaman aşımı olmadan ekran (ör. Home)
      // sonsuza kadar dönmeye devam ediyordu - "kapatıp açtığımda dönüp
      // duruyor, kimin hesabı belli değil" şikayetinin kök nedeni buydu.
      return await call().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const NetworkAuthException();
    } on DioException catch (exception) {
      throw _mapException(exception);
    }
  }

  AuthException _mapException(DioException exception) {
    final statusCode = exception.response?.statusCode;
    if (statusCode == null) {
      return const NetworkAuthException();
    }
    if (statusCode == 429) {
      return const RateLimitedAuthException();
    }

    // Sunucu bir Errors gövdesi döndürmediyse mesaj null kalır - burada sabit
    // bir dil ile doldurmak, AppLocalizations'ı bypass eden tam olarak
    // yasaklanan örüntü olurdu. Null, GenericAuthException/ConflictAuthException
    // üzerinden localizedMessage(context)'e taşınır ve orada l10n.commonError'a
    // düşülür.
    final data = exception.response?.data;
    final message = data is Map && data['Errors'] is List && (data['Errors'] as List).isNotEmpty
        ? (data['Errors'] as List).first.toString()
        : null;

    if (statusCode == 401) {
      // Bu (method, path) çağrılarının 401'i "yanlış şifre" değil "yanlış OTP kodu"
      // anlamına gelir - sunucunun kendi mesajı zaten hangi kanalın başarısız
      // olduğunu söyler, bu yüzden diğer her 401'in kullandığı sabit kodlanmış
      // InvalidCredentialsException yerine bunu olduğu gibi göster. DELETE
      // /api/auth/me dahildir ama GET /api/auth/me (süresi dolmuş bir access
      // token) dahil değildir - aynı path, farklı method, farklı anlam.
      const otpVerifiedCalls = {
        'POST /api/auth/register/complete',
        'POST /api/auth/me/freeze',
        'POST /api/auth/me/unfreeze',
        'DELETE /api/auth/me',
      };
      final call = '${exception.requestOptions.method} ${exception.requestOptions.path}';
      if (otpVerifiedCalls.contains(call)) {
        return GenericAuthException(message);
      }
      // /api/auth/login'in KENDİSİNDEN gelen bir 401 gerçekten "yanlış şifre"
      // demektir. Başka HERHANGİ bir uç noktadan gelen bir 401 buraya ancak
      // dio_client.dart'ın refresh-and-retry akışı da başarısız olduysa
      // ulaşır - yani kullanıcı hiçbir şifre girmedi, oturumu gerçekten
      // geçersiz. Bu iki durumu aynı "yanlış şifre" metniyle göstermek
      // kafa karıştırıcı ve yanlıştı.
      if (exception.requestOptions.path == '/api/auth/login') {
        return const InvalidCredentialsException();
      }
      return const SessionExpiredException();
    }
    if (statusCode == 409) {
      return ConflictAuthException(message);
    }
    return GenericAuthException(message);
  }
}

@riverpod
AuthRepository authRepository(Ref ref) => RealAuthRepository(ref.watch(dioProvider), ref.watch(tokenStoreProvider));
