import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/token_store.dart';
import 'package:gym_app/core/network/secure_token_store.dart';
import 'package:gym_app/core/providers/active_staff_assignment_provider.dart';
import 'package:gym_app/features/auth/data/real_auth_repository.dart';
import 'package:gym_app/features/auth/domain/auth_repository.dart';
import 'package:gym_app/features/auth/domain/me_result.dart';
import 'package:gym_app/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:gym_app/features/auth/presentation/providers/current_user_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockTokenStore extends Mock implements TokenStore {}

class _MockAuthRepository extends Mock implements AuthRepository {}

class _RecordingAssignmentStore implements ActiveAssignmentStore {
  final writes = <int?>[];

  @override
  Future<int?> read() async => null;

  @override
  Future<void> write(int? assignmentId) async => writes.add(assignmentId);
}

MeResult _fakeUser(String fullName) => MeResult(
      id: 1,
      fullName: fullName,
      phone: '+905551112233',
      email: null,
      preferredLanguage: 'tr',
      isAccountFrozen: false,
      assignments: const [],
      packageAssignments: const [],
    );

void main() {
  late _MockTokenStore tokenStore;
  late ProviderContainer container;

  setUp(() {
    tokenStore = _MockTokenStore();
    container = ProviderContainer(overrides: [tokenStoreProvider.overrideWithValue(tokenStore)]);
    addTearDown(container.dispose);
  });

  test('build() is true when a stored access token exists', () async {
    when(() => tokenStore.readAccessToken()).thenAnswer((_) async => 'stored-token');
    when(() => tokenStore.readRefreshToken()).thenAnswer((_) async => 'stored-refresh-token');

    final result = await container.read(authStateProvider.future);

    expect(result, isTrue);
  });

  test('build() is false when no token is stored', () async {
    when(() => tokenStore.readAccessToken()).thenAnswer((_) async => null);
    when(() => tokenStore.readRefreshToken()).thenAnswer((_) async => null);

    final result = await container.read(authStateProvider.future);

    expect(result, isFalse);
  });

  test('build() is false when access token exists but refresh token is missing (partial pair)', () async {
    when(() => tokenStore.readAccessToken()).thenAnswer((_) async => 'stored-token');
    when(() => tokenStore.readRefreshToken()).thenAnswer((_) async => null);

    final result = await container.read(authStateProvider.future);

    expect(result, isFalse);
  });

  test('logIn() sets state to true', () async {
    when(() => tokenStore.readAccessToken()).thenAnswer((_) async => null);
    when(() => tokenStore.readRefreshToken()).thenAnswer((_) async => null);
    await container.read(authStateProvider.future);

    container.read(authStateProvider.notifier).logIn();

    expect(container.read(authStateProvider).value, isTrue);
  });

  test('logOut() clears the token store and sets state to false', () async {
    when(() => tokenStore.readAccessToken()).thenAnswer((_) async => 'stored-token');
    when(() => tokenStore.readRefreshToken()).thenAnswer((_) async => 'stored-refresh-token');
    when(() => tokenStore.clear()).thenAnswer((_) async {});
    await container.read(authStateProvider.future);

    await container.read(authStateProvider.notifier).logOut();

    verify(() => tokenStore.clear()).called(1);
    expect(container.read(authStateProvider).value, isFalse);
  });

  // Paylaşılan cihazda bir sonraki hesap, öncekinin aktif görev seçimiyle
  // değil kendi varsayılanıyla başlamalı.
  test('logOut() aktif görev seçimini sıfırlar ve saklanan değeri siler', () async {
    when(() => tokenStore.readAccessToken()).thenAnswer((_) async => 'stored-token');
    when(() => tokenStore.readRefreshToken()).thenAnswer((_) async => 'stored-refresh-token');
    when(() => tokenStore.clear()).thenAnswer((_) async {});
    final assignmentStore = _RecordingAssignmentStore();
    final container2 = ProviderContainer(overrides: [
      tokenStoreProvider.overrideWithValue(tokenStore),
      activeAssignmentStoreProvider.overrideWithValue(assignmentStore),
    ]);
    addTearDown(container2.dispose);
    await container2.read(authStateProvider.future);
    container2.read(activeStaffAssignmentProvider.notifier).select(5);

    await container2.read(authStateProvider.notifier).logOut();

    expect(container2.read(activeStaffAssignmentProvider), isNull);
    expect(assignmentStore.writes, [5, null]);
  });

  // flutter_secure_storage (ör. Android Keystore) silme sırasında
  // PlatformException fırlatabiliyor - kullanıcı yine de çıkış yapabilmeli.
  test('logOut() token deposu temizlenemese bile çıkışı tamamlar ve hata fırlatmaz', () async {
    when(() => tokenStore.readAccessToken()).thenAnswer((_) async => 'stored-token');
    when(() => tokenStore.readRefreshToken()).thenAnswer((_) async => 'stored-refresh-token');
    when(() => tokenStore.clear()).thenThrow(PlatformException(code: 'keystore'));
    final assignmentStore = _RecordingAssignmentStore();
    final container2 = ProviderContainer(overrides: [
      tokenStoreProvider.overrideWithValue(tokenStore),
      activeAssignmentStoreProvider.overrideWithValue(assignmentStore),
    ]);
    addTearDown(container2.dispose);
    await container2.read(authStateProvider.future);
    container2.read(activeStaffAssignmentProvider.notifier).select(5);

    await container2.read(authStateProvider.notifier).logOut();

    // authState false -> router /login'e yönlendirir.
    expect(container2.read(authStateProvider).value, isFalse);
    expect(container2.read(activeStaffAssignmentProvider), isNull);
  });

  test('logIn() invalidates currentUserProvider - önceki kullanıcının önbelleğe alınmış '
      'kimliği yeni girişten sonra artık gösterilmiyor', () async {
    when(() => tokenStore.readAccessToken()).thenAnswer((_) async => null);
    when(() => tokenStore.readRefreshToken()).thenAnswer((_) async => null);
    final repository = _MockAuthRepository();
    var callCount = 0;
    when(() => repository.getMe()).thenAnswer((_) async {
      callCount++;
      return _fakeUser(callCount == 1 ? 'GymApp SuperAdmin' : 'Test GymAdmin');
    });
    final container2 = ProviderContainer(overrides: [
      tokenStoreProvider.overrideWithValue(tokenStore),
      authRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container2.dispose);
    final keepAlive = container2.listen(currentUserProvider, (_, _) {});

    final first = await container2.read(currentUserProvider.future);
    expect(first.fullName, 'GymApp SuperAdmin');

    // Kritik bug buradaydı: farklı bir hesapla (SuperAdmin -> GymAdmin) art
    // arda giriş yapıldığında logIn() currentUserProvider'ı hiç
    // invalidate etmiyordu, bu yüzden bu ikinci okuma HİÇBİR ZAMAN
    // getMe()'yi tekrar çağırmıyor, hâlâ önbelleğe alınmış ilk kullanıcıyı
    // döndürüyordu.
    container2.read(authStateProvider.notifier).logIn();
    final second = await container2.read(currentUserProvider.future);

    expect(callCount, 2);
    expect(second.fullName, 'Test GymAdmin');
    keepAlive.close();
  });
}
