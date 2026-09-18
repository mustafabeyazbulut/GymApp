import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Android emulator, host makinenin localhost'una localhost'un kendisi
/// yerine özel 10.0.2.2 adresi üzerinden ulaşır — Chrome ve aynı ağdaki
/// gerçek bir cihaz ise bunun yerine localhost/host'un gerçek adresini kullanır.
abstract final class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5195';
    if (Platform.isAndroid) return 'http://10.0.2.2:5195';
    return 'http://localhost:5195';
  }
}
