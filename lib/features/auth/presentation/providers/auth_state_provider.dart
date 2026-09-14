import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_state_provider.g.dart';

/// Whether the app should show the tab shell (true) or `/login` (false).
/// No persistence — resets to false every app launch, by design (see spec).
@riverpod
class AuthState extends _$AuthState {
  @override
  bool build() => false;

  void logIn() => state = true;
  void logOut() => state = false;
}
