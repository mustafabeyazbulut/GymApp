import 'dart:ui' show PlatformDispatcher;

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../locale/app_locale_provider.dart';
import '../providers/active_staff_company_provider.dart';
import 'api_config.dart';
import 'token_store.dart';
import 'secure_token_store.dart';

part 'dio_client.g.dart';

// Backend'in TenantContextMiddleware'inin okuduğu header adıyla birebir
// aynı olmalı (bkz. GymAppApi Presentation/GymAppApi.WebApi/Middleware/
// TenantContextMiddleware.cs'deki ActiveCompanyHeaderName sabiti).
const activeCompanyHeaderName = 'X-Active-Company-Id';

// Kendisine Authorization başlığı eklenmemesi gereken ve 401 durumunda
// refresh-and-retry'ı TETİKLEMEMESİ gereken uç noktalar (/login'den gelen
// bir 401, süresi dolmuş oturum sinyali değil, gerçek "yanlış şifre"
// cevabının KENDİSİdir).
const _noAuthPaths = [
  '/api/auth/register',
  '/api/auth/login',
  '/api/auth/refresh',
  '/api/auth/forgot-password',
  '/api/auth/reset-password',
];

void addAuthInterceptor(Dio dio, TokenStore tokenStore) {
  // Sadece refresh çağrısı ve başarısız isteğin tekrarı için kullanılır.
  // QueuedInterceptorsWrapper, onError işlemesini tek bir paylaşılan kuyruk
  // üzerinden sıraya koyar: aşağıdaki dış 401 işleyicisi çalışırken (ve henüz
  // handler.next/resolve çağırmamışken) bu kuyruk "meşgul"dür. Eğer refresh
  // çağrısının kendisi `dio` üzerinden (bu interceptor'ın bağlı olduğu aynı
  // instance) yapılsaydı ve hata verseydi, kendi onError'ı hâlâ çalışmakta
  // olan ve zaten bu iç çağrıyı bekleyen dış işleyicinin arkasına kuyruğa
  // girerdi — bu da kalıcı bir kilitlenmeye yol açardı. `rawDio` aynı
  // transport'u (httpClientAdapter) ve base options'ı paylaşır ama `dio`'nun
  // interceptor'larından hiçbirini taşımaz, bu yüzden refresh/retry çağrıları
  // asla bu kuyruğa yeniden girmez.
  final rawDio = Dio(dio.options)..httpClientAdapter = dio.httpClientAdapter;

  dio.interceptors.add(
    QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        if (!_noAuthPaths.contains(options.path)) {
          final accessToken = await tokenStore.readAccessToken();
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final requestPath = error.requestOptions.path;
        if (error.response?.statusCode != 401 ||
            _noAuthPaths.contains(requestPath)) {
          handler.next(error);
          return;
        }

        final refreshToken = await tokenStore.readRefreshToken();
        if (refreshToken == null) {
          await tokenStore.clear();
          handler.next(error);
          return;
        }

        try {
          final refreshResponse = await rawDio.post<Map<String, dynamic>>(
            '/api/auth/refresh',
            data: {'refreshToken': refreshToken},
          );
          final data = refreshResponse.data!;
          await tokenStore.saveTokens(
            accessToken: data['accessToken'] as String,
            refreshToken: data['refreshToken'] as String,
          );

          final retryOptions = error.requestOptions;
          retryOptions.headers['Authorization'] =
              'Bearer ${data['accessToken']}';
          final retryResponse = await rawDio.fetch(retryOptions);
          handler.resolve(retryResponse);
        } catch (_) {
          await tokenStore.clear();
          handler.next(error);
        }
      },
    ),
  );
}

@riverpod
Dio dio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  addAuthInterceptor(dio, ref.watch(tokenStoreProvider));
  // addAuthInterceptor'dan ayrı bir interceptor - bunun kendi test dosyası
  // Riverpod'suz plain bir Dio/TokenStore çifti kuruyor, bu yüzden ref'e
  // ihtiyaç duyan bu mantığı oraya karıştırmıyoruz. ref.read (watch değil):
  // değeri her istekte YENİDEN okumak istiyoruz, Dio ilk oluşturulduğunda
  // sabitlenmiş bir değeri değil.
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final companyId = ref.read(activeStaffCompanyIdProvider);
        if (companyId != null) {
          options.headers[activeCompanyHeaderName] = companyId.toString();
        }
        // Backend'in kendi mesajlarını (hata/uyarı metinleri) hangi dilde
        // döneceğine bu header karar veriyor (bkz. GymAppApi
        // Program.cs'teki UseRequestLocalization) - "backend mobildeki
        // seçili dil paketiyle çalışacak" talimatının karşılığı. Uygulama
        // henüz açıkça bir dil seçmemişse (appLocaleProvider == null,
        // "cihazın sistem locale'ini takip et" durumu) cihazın gerçek
        // locale'ine bakılıyor - AppLocalizations.supportedLocales'in
        // (en, tr) kendi varsayılan çözümlemesiyle aynı mantık.
        final locale = ref.read(appLocaleProvider) ?? PlatformDispatcher.instance.locale;
        options.headers['Accept-Language'] = locale.languageCode == 'tr' ? 'tr' : 'en';
        handler.next(options);
      },
    ),
  );
  return dio;
}
