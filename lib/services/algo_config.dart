import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'log_service.dart';

/// Swap Alternatives Service (ALG-001) yapılandırması.
///
/// Öncelik sırası (deterministik):
///   1. dart-define: `--dart-define=ALGO_BASE_URL=https://xxxx.trycloudflare.com`
///   2. dotenv (assets/.env): `ALGO_BASE_URL=http://10.0.2.2:8000`
///   3. Safe fallback: `http://10.0.2.2:8000` (Android emulator host)
///
/// Kurulum:
///   Local dev: assets/.env dosyası `ALGO_BASE_URL=http://10.0.2.2:8000`
///   CI: workflow'da `env: ALGO_BASE_URL: ${{ secrets.ALGO_BASE_URL }}` (optional)
///   Prod: `flutter run --dart-define=ALGO_BASE_URL=https://xxxx.trycloudar.com`
///
/// Web notu: dotenv erişimi kısıtlı, dart-define önerelikli.
class AlgoConfig {
  AlgoConfig._();

  /// dart-define ile gelen değer (boş string = fallback).
  static const String _dartDefineUrl = String.fromEnvironment('ALGO_BASE_URL', defaultValue: '');

  /// Backend base URL.
  /// Öncelik: dart-define > dotenv > fallback.
  static String get baseUrl {
    // 1. dart-define (boş string kontrolü)
    if (_dartDefineUrl.isNotEmpty && _isValidUrl(_dartDefineUrl)) {
      return _dartDefineUrl;
    }

    // 2. dotenv (assets/.env) — web'de yüklenmemiş olabilir
    try {
      final envUrl = dotenv.env['ALGO_BASE_URL'];
      if (envUrl != null && envUrl.isNotEmpty && _isValidUrl(envUrl)) {
        return envUrl;
      }
    } catch (e) {
      // Web'de dotenv erişimi başarısız olabilir, logla ve devam et
      LogService.w('AlgoConfig', 'dotenv erişim hatası', error: e);
    }

    // 3. Safe fallback (Android emulator host erişimi)
    return 'http://10.0.2.2:8000';
  }

  /// URL geçerli mi? — http/https scheme + boş olmalı.
  static bool _isValidUrl(String url) {
    if (url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    return uri != null &&
           uri.hasScheme &&
           (uri.scheme == 'http' || uri.scheme == 'https') &&
           uri.host.isNotEmpty;
  }

  /// HTTP timeout süresi.
  static const Duration timeout = Duration(seconds: 5);

  /// Maksimum yeniden deneme sayısı.
  static const int maxRetries = 3;

  /// Backoff süreleri (saniye): 1s, 2s, 4s
  static const List<int> backoffSeconds = [1, 2, 4];
}
