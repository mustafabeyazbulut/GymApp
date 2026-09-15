import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/token_store.dart';
import 'package:gym_app/core/network/secure_token_store.dart';
import 'package:gym_app/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockTokenStore extends Mock implements TokenStore {}

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

    final result = await container.read(authStateProvider.future);

    expect(result, isTrue);
  });

  test('build() is false when no token is stored', () async {
    when(() => tokenStore.readAccessToken()).thenAnswer((_) async => null);

    final result = await container.read(authStateProvider.future);

    expect(result, isFalse);
  });

  test('logIn() sets state to true', () async {
    when(() => tokenStore.readAccessToken()).thenAnswer((_) async => null);
    await container.read(authStateProvider.future);

    container.read(authStateProvider.notifier).logIn();

    expect(container.read(authStateProvider).value, isTrue);
  });

  test('logOut() clears the token store and sets state to false', () async {
    when(() => tokenStore.readAccessToken()).thenAnswer((_) async => 'stored-token');
    when(() => tokenStore.clear()).thenAnswer((_) async {});
    await container.read(authStateProvider.future);

    await container.read(authStateProvider.notifier).logOut();

    verify(() => tokenStore.clear()).called(1);
    expect(container.read(authStateProvider).value, isFalse);
  });
}
