import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/auth_repository.dart';

part 'fake_auth_repository.g.dart';

/// No real backend exists yet — any non-empty identifier/password is
/// accepted after a short artificial delay, so the login button's loading
/// state has something real to show. See `AuthState` (presentation layer)
/// for what "being logged in" actually gates in the app.
class FakeAuthRepository implements AuthRepository {
  @override
  Future<void> login({required String identifier, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }
}

@riverpod
AuthRepository authRepository(Ref ref) => FakeAuthRepository();
