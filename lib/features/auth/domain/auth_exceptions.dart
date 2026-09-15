sealed class AuthException implements Exception {
  const AuthException(this.message);

  final String message;
}

class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException() : super('Telefon numarası/e-posta veya şifre hatalı.');
}

class NetworkAuthException extends AuthException {
  const NetworkAuthException() : super('Bağlantı kurulamadı. Lütfen tekrar deneyin.');
}

class ConflictAuthException extends AuthException {
  const ConflictAuthException(super.message);
}

class GenericAuthException extends AuthException {
  const GenericAuthException(super.message);
}
