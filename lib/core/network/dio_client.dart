import 'dart:ui' show PlatformDispatcher;

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/domain/me_result.dart';
import '../../features/auth/presentation/providers/current_user_provider.dart';
import '../locale/app_locale_provider.dart';
import '../providers/active_staff_assignment_provider.dart';
import 'api_config.dart';
import 'token_store.dart';
import 'secure_token_store.dart';

part 'dio_client.g.dart';

// Backend'in TenantContextMiddleware'inin okuduğu header adlarıyla birebir
// aynı olmalı (bkz. GymAppApi Presentation/GymAppApi.WebApi/Middleware/
// TenantContextMiddleware.cs). Aktif görev asıl bağlamdır; firma header'ı
// geriye dönük uyumluluk için seçili görevin firmasıyla gönderilmeye devam eder.
const activeAssignmentHeaderName = 'X-Active-Assignment-Id';
const activeCompanyHeaderName = 'X-Active-Company-Id';

// Backend'in geçersiz/başkasına ait/pasif bir X-Active-Assignment-Id için
// döndüğü 403'ün hata kodu.
const invalidActiveAssignmentCode = 'InvalidActiveAssignment';

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

        // Yerel Docker/WSL2 ortamında Postgres bağlantısı ara sıra birkaç
        // saniye gecikebiliyor (bkz. GymAppApi Registration.cs'teki Npgsql
        // KeepAlive notu) - refresh isteği TAMAMEN geçerli bir refresh
        // token'la bile bu yüzden zaman zaman yavaşlayıp zaman aşımına
        // uğrayabiliyor. Sunucunun token'ı GERÇEKTEN reddettiği (bir yanıt
        // döndüğü, statusCode 400/401 gibi) durumla, isteğin hiç yanıt
        // ALAMADIĞI (bağlantı/zaman aşımı) durumu ayırt edip sadece ikincisi
        // için kısa bir bekleyişle yeniden deniyoruz - tek bir geçici ağ
        // sorunu kullanıcıyı gereksiz yere kalıcı olarak çıkışa zorlamamalı.
        Response<Map<String, dynamic>>? refreshResponse;
        for (var attempt = 1; attempt <= 3; attempt++) {
          try {
            refreshResponse = await rawDio.post<Map<String, dynamic>>(
              '/api/auth/refresh',
              data: {'refreshToken': refreshToken},
            );
            break;
          } on DioException catch (refreshError) {
            final isDefinitiveRejection = refreshError.response != null;
            if (isDefinitiveRejection || attempt == 3) {
              await tokenStore.clear();
              handler.next(error);
              return;
            }
            await Future.delayed(const Duration(seconds: 1));
          }
        }

        try {
          final data = refreshResponse!.data!;
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

// Çözümlenmiş aktif görev: seçim + /me'deki atamalar. Kullanıcı henüz
// yüklenmemişse null döner - ref.read'in currentUserProvider'ı burada
// başlatması, ör. /login isteği sırasında token'sız bir /me isteği atıp
// giriş-yönlendirme yarışını yeniden doğururdu (bkz. main.dart'taki not).
// Auth uçları aktif görev bağlamına ihtiyaç duymaz; /me'nin header'sız
// gitmesi, geçersiz bir seçimin kendi düzeltmesini (GetMe yenilemesi)
// engellemesini de önler.
MeAssignment? _activeAssignmentFor(Ref ref, String path) {
  if (path.startsWith('/api/auth/')) return null;
  if (!ref.exists(currentUserProvider)) return null;
  final active = ref.read(currentUserProvider).value?.activeAssignment(ref.read(activeStaffAssignmentProvider));
  // Sistem Sahibi olarak hareket ederken header gönderilmez - backend
  // header'sız isteği SuperAdmin olarak işler.
  return (active?.isStaffRole ?? false) ? active : null;
}

bool _isInvalidActiveAssignment(Response<dynamic>? response) {
  if (response?.statusCode != 403) return false;
  final data = response!.data;
  // Hata DTO'su PascalCase (bkz. ApiException.fromDioException); yine de
  // camelCase'e karşı dayanıklı.
  return data is Map && (data['Code'] ?? data['code']) == invalidActiveAssignmentCode;
}

// keepAlive: interceptor'lar her istekte bu provider'ın kendi `ref`'ini
// kullanıyor (ref.read(activeStaffAssignmentProvider) vb.). autoDispose iken,
// o an provider'ı dinleyen kimse yoksa (ör. /login ekranı) bir istek
// sürerken provider dispose ediliyor ve ref.read "dispose edilmiş Ref"
// hatası fırlatıyordu - Dio bunu yanıtsız bir DioException'a çevirdiği için
// login ekranında sunucuya hiç gitmeyen bir "bağlantı kurulamadı" hatası
// olarak görünüyordu. Dio zaten uygulama genelinde tek bir örnek olmalı.
@Riverpod(keepAlive: true)
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
        final activeAssignment = _activeAssignmentFor(ref, options.path);
        if (activeAssignment?.id != null) {
          options.headers[activeAssignmentHeaderName] = activeAssignment!.id.toString();
        }
        if (activeAssignment?.companyId != null) {
          options.headers[activeCompanyHeaderName] = activeAssignment!.companyId.toString();
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
      // Seçili görev artık geçerli değil (atama kaldırıldı/pasif): seçimi
      // varsayılan kurala sıfırla ve /me'yi yenile ki çözümleme güncel
      // atamalarla yapılsın. İstek TEKRARLANMAZ - hata çağırana iletilir;
      // /me header'sız gittiği için bu yenileme kendisi 403'e düşüp döngü
      // oluşturamaz.
      onError: (error, handler) {
        if (_isInvalidActiveAssignment(error.response)) {
          ref.read(activeStaffAssignmentProvider.notifier).reset();
          if (ref.exists(currentUserProvider)) ref.invalidate(currentUserProvider);
        }
        handler.next(error);
      },
    ),
  );
  return dio;
}
