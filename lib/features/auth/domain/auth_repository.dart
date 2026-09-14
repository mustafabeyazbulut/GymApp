abstract interface class AuthRepository {
  Future<void> login({required String identifier, required String password});
}
