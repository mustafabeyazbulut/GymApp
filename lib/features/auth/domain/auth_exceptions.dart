import 'package:flutter/widgets.dart' show BuildContext;

import '../../../l10n/generated/app_localizations.dart';

sealed class AuthException implements Exception {
  const AuthException();
}

class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException();
}

class NetworkAuthException extends AuthException {
  const NetworkAuthException();
}

class ConflictAuthException extends AuthException {
  const ConflictAuthException(this.serverMessage);
  // Sunucu bir Errors gövdesi döndürmediyse null olabilir (ör. beklenmeyen
  // bir 409) - bu durumda sabit bir Türkçe metinle doldurmak yerine
  // localizedMessage'da l10n.commonError'a düşülür.
  final String? serverMessage;
}

class GenericAuthException extends AuthException {
  const GenericAuthException(this.serverMessage);
  // Sunucu bir Errors gövdesi döndürmediyse null olabilir - yukarıdaki not.
  final String? serverMessage;
}

class RateLimitedAuthException extends AuthException {
  const RateLimitedAuthException();
}

extension AuthExceptionLocalization on AuthException {
  /// Gösterilecek metni ÇAĞRILDIĞI ANDA (BuildContext olan yerde) çözer -
  /// server tarafından üretilen mesajlar (Conflict/Generic) zaten doğru
  /// dilde geliyor; sabit istemci-tarafı durumlar (kimlik/bağlantı/rate
  /// limit) burada AppLocalizations'a bakıyor.
  String localizedMessage(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (this) {
      InvalidCredentialsException() => l10n.authInvalidCredentials,
      NetworkAuthException() => l10n.commonConnectionError,
      RateLimitedAuthException() => l10n.authTooManyAttempts,
      ConflictAuthException(serverMessage: final m) => m ?? l10n.commonError,
      GenericAuthException(serverMessage: final m) => m ?? l10n.commonError,
    };
  }
}
