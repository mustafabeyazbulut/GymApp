import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Android emulator reaches the host machine's localhost via the special
/// address 10.0.2.2, not localhost itself — Chrome and a real device on the
/// same network both use localhost/the host's real address instead.
abstract final class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5195';
    if (Platform.isAndroid) return 'http://10.0.2.2:5195';
    return 'http://localhost:5195';
  }
}
