import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/locale/app_locale_provider.dart';
import 'package:gym_app/core/network/dio_client.dart';
import 'package:gym_app/core/network/fake_token_store.dart';
import 'package:gym_app/core/network/secure_token_store.dart';
import 'package:gym_app/core/providers/active_staff_assignment_provider.dart';
import 'package:gym_app/features/auth/data/real_auth_repository.dart';
import 'package:gym_app/features/auth/domain/auth_repository.dart';
import 'package:gym_app/features/auth/domain/me_result.dart';
import 'package:gym_app/features/auth/presentation/providers/current_user_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MemoryStore implements ActiveAssignmentStore {
  @override
  Future<int?> read() async => null;

  @override
  Future<void> write(int? assignmentId) async {}
}

const _trainerA = MeAssignment(id: 11, companyId: 1, companyName: 'A', branchId: 3, role: 'Trainer');
const _branchManagerB = MeAssignment(id: 22, companyId: 2, companyName: 'B', branchId: 9, role: 'BranchManager');

MeResult _me(List<MeAssignment> assignments) => MeResult(
      id: 1,
      fullName: 'Test',
      phone: '+905550000000',
      email: null,
      preferredLanguage: 'tr',
      isAccountFrozen: false,
      assignments: assignments,
      packageAssignments: const [],
    );

void main() {
  late ProviderContainer container;
  late _MockAuthRepository repository;
  late List<RequestOptions> requests;
  late Dio dio;

  // [respond] verilmezse her istek 200 döner.
  Future<void> setUpWith(
    List<MeAssignment> assignments, {
    ResponseBody Function(RequestOptions options)? respond,
    bool loadUser = true,
  }) async {
    repository = _MockAuthRepository();
    when(() => repository.getMe()).thenAnswer((_) async => _me(assignments));
    container = ProviderContainer(overrides: [
      tokenStoreProvider.overrideWithValue(FakeTokenStore()),
      authRepositoryProvider.overrideWithValue(repository),
      activeAssignmentStoreProvider.overrideWithValue(_MemoryStore()),
    ]);
    addTearDown(container.dispose);
    // currentUserProvider ve appLocaleProvider autoDispose - gerçek uygulamada
    // main.dart'taki dinleyici/ekranlar canlı tutuyor.
    container.listen(appLocaleProvider, (_, _) {});
    if (loadUser) {
      container.listen(currentUserProvider, (_, _) {});
      await container.read(currentUserProvider.future);
    }

    requests = [];
    dio = container.read(dioProvider);
    dio.httpClientAdapter = _CapturingAdapter((options) {
      requests.add(options);
      return respond?.call(options) ?? ResponseBody.fromString('{}', 200, headers: _json);
    });
  }

  test('personel ataması olmayan üye hiçbir aktif görev header\'ı göndermez', () async {
    await setUpWith(const []);

    await dio.get('/api/ping');

    expect(requests.single.headers.containsKey(activeAssignmentHeaderName), isFalse);
    expect(requests.single.headers.containsKey(activeCompanyHeaderName), isFalse);
  });

  test('seçim yoksa varsayılan görevin Id\'sini ve firmasını gönderir', () async {
    await setUpWith([_trainerA, _branchManagerB]);

    await dio.get('/api/ping');

    expect(requests.single.headers[activeAssignmentHeaderName], '22');
    expect(requests.single.headers[activeCompanyHeaderName], '2');
  });

  test('seçimi her istekte yeniden okur', () async {
    await setUpWith([_trainerA, _branchManagerB]);

    await dio.get('/api/ping');
    container.read(activeStaffAssignmentProvider.notifier).select(11);
    await dio.get('/api/ping');

    expect(requests[0].headers[activeAssignmentHeaderName], '22');
    expect(requests[1].headers[activeAssignmentHeaderName], '11');
    expect(requests[1].headers[activeCompanyHeaderName], '1');
  });

  test('backend atama Id\'si göndermiyorsa sadece firma header\'ı gider', () async {
    await setUpWith([const MeAssignment(companyId: 5, companyName: 'C', branchId: null, role: 'GymAdmin')]);

    await dio.get('/api/ping');

    expect(requests.single.headers.containsKey(activeAssignmentHeaderName), isFalse);
    expect(requests.single.headers[activeCompanyHeaderName], '5');
  });

  // /api/auth/me aktif görev bağlamına ihtiyaç duymaz; header'sız gitmesi,
  // geçersiz bir seçimin GetMe yenilemesini de engellemesini önler.
  test('auth uçlarına aktif görev header\'ı eklenmez', () async {
    await setUpWith([_branchManagerB]);

    await dio.get('/api/auth/me');

    expect(requests.single.headers.containsKey(activeAssignmentHeaderName), isFalse);
    expect(requests.single.headers.containsKey(activeCompanyHeaderName), isFalse);
  });

  test('kullanıcı henüz yüklenmediyse header eklenmez ve kullanıcı yüklemesi tetiklenmez', () async {
    await setUpWith([_branchManagerB], loadUser: false);

    await dio.get('/api/ping');

    expect(requests.single.headers.containsKey(activeAssignmentHeaderName), isFalse);
    verifyNever(() => repository.getMe());
  });

  test('SuperAdmin + GymAdmin: Sistem Sahibi seçiliyken header yok, GymAdmin seçilince gönderilir', () async {
    const superAdmin = MeAssignment(id: 1, companyId: null, companyName: null, branchId: null, role: 'SuperAdmin');
    const gymAdmin = MeAssignment(id: 30, companyId: 4, companyName: 'D', branchId: null, role: 'GymAdmin');
    await setUpWith([superAdmin, gymAdmin]);

    // Varsayılan: Sistem Sahibi.
    await dio.get('/api/ping');
    container.read(activeStaffAssignmentProvider.notifier).select(30);
    await dio.get('/api/ping');
    container.read(activeStaffAssignmentProvider.notifier).select(1);
    await dio.get('/api/ping');

    expect(requests[0].headers.containsKey(activeAssignmentHeaderName), isFalse);
    expect(requests[0].headers.containsKey(activeCompanyHeaderName), isFalse);
    expect(requests[1].headers[activeAssignmentHeaderName], '30');
    expect(requests[1].headers[activeCompanyHeaderName], '4');
    expect(requests[2].headers.containsKey(activeAssignmentHeaderName), isFalse);
    expect(requests[2].headers.containsKey(activeCompanyHeaderName), isFalse);
  });

  group('403 InvalidActiveAssignment', () {
    ResponseBody invalidAssignment(RequestOptions options) => ResponseBody.fromString(
          jsonEncode({'Status': 403, 'Errors': ['Geçersiz görev'], 'Code': 'InvalidActiveAssignment'}),
          403,
          headers: _json,
        );

    test('seçimi sıfırlar, GetMe\'yi yeniler ve isteği tekrarlamaz', () async {
      await setUpWith([_trainerA, _branchManagerB], respond: invalidAssignment);
      container.read(activeStaffAssignmentProvider.notifier).select(11);

      await expectLater(dio.get('/api/ping'), throwsA(isA<DioException>()));
      await container.read(currentUserProvider.future);

      expect(container.read(activeStaffAssignmentProvider), isNull);
      expect(requests, hasLength(1));
      verify(() => repository.getMe()).called(2);
    });

    test('başka bir 403 seçimi değiştirmez', () async {
      await setUpWith(
        [_trainerA, _branchManagerB],
        respond: (_) => ResponseBody.fromString(
          jsonEncode({'Status': 403, 'Errors': ['Yetkiniz yok'], 'Code': 'Forbidden'}),
          403,
          headers: _json,
        ),
      );
      container.read(activeStaffAssignmentProvider.notifier).select(11);

      await expectLater(dio.get('/api/ping'), throwsA(isA<DioException>()));

      expect(container.read(activeStaffAssignmentProvider), 11);
      verify(() => repository.getMe()).called(1);
    });
  });
}

const _json = {
  'content-type': ['application/json'],
};

typedef _Responder = ResponseBody Function(RequestOptions options);

class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter(this._respond);

  final _Responder _respond;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      _respond(options);
}
