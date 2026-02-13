import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Swap Alternatives Service (ALG-001) yapılandırması.
///
/// Öncelik sırası:
///   1. dart-define ile override: --dart-define=ALGO_BASE_URL=https://xxxx.trycloudflare.com
///   2. assets/.env dosyasındaki ALGO_BASE_URL
///   3. Varsayılan: http://10.0.2.2:8000 (Android emulator)
///
/// Kullanım:
///   flutter run --dart-define=ALGO_BASE_URL=http://10.0.2.2:8000
///   flutter run --dart-define=ALGO_BASE_URL=https://xxxx.trycloudflare.com
class AlgoConfig {
  AlgoConfig._();

  /// dart-define ile gelen değer (boşsa null gibi davranır).
  static const String _dartDefineUrl = String.fromEnvironment('ALGO_BASE_URL');

  /// Backend base URL.
  /// Öncelik: dart-define > dotenv > varsayılan.
  static String get baseUrl {
    // 1. dart-define
    if (_dartDefineUrl.isNotEmpty) return _dartDefineUrl;
    // 2. dotenv (assets/.env)
    final envUrl = dotenv.env['ALGO_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;
    // 3. varsayılan (Android emulator host erişimi)
    return 'http://10.0.2.2:8000';
  }

  /// HTTP timeout süresi.
  static const Duration timeout = Duration(seconds: 5);

  /// Maksimum yeniden deneme sayısı.
  static const int maxRetries = 3;

  /// Backoff süreleri (saniye): 1s, 2s, 4s
  static const List<int> backoffSeconds = [1, 2, 4];
}
