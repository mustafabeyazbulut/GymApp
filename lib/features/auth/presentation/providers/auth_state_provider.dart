import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/secure_token_store.dart';

part 'auth_state_provider.g.dart';

/// Whether the app should show the tab shell (true) or `/login` (false).
/// On startup, this checks for a stored access token rather than always
/// resetting to false — real sessions now persist across app launches.
@riverpod
class AuthState extends _$AuthState {
  @override
  Future<bool> build() async {
    final token = await ref.watch(tokenStoreProvider).readAccessToken();
    return token != null;
  }

  void logIn() => state = const AsyncData(true);

  Future<void> logOut() async {
    await ref.read(tokenStoreProvider).clear();
    state = const AsyncData(false);
  }
}
