/// Swap Alternatives Service (ALG-001) yapılandırması.
/// ALGO_BASE_URL dart-define ile override edilebilir.
///
/// Kullanım:
///   flutter run --dart-define=ALGO_BASE_URL=http://10.0.2.2:8000
///   flutter run --dart-define=ALGO_BASE_URL=https://xxxx.trycloudflare.com
class AlgoConfig {
  AlgoConfig._();

  /// Backend base URL.
  /// Default: Android emulator host erişimi (10.0.2.2).
  /// iOS simulator için http://127.0.0.1:8000 kullanın.
  /// Quick tunnel için https://xxxx.trycloudflare.com kullanın.
  static const String baseUrl = String.fromEnvironment(
    'ALGO_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// HTTP timeout süresi.
  static const Duration timeout = Duration(seconds: 5);

  /// Maksimum yeniden deneme sayısı.
  static const int maxRetries = 3;

  /// Backoff süreleri (saniye): 1s, 2s, 4s
  static const List<int> backoffSeconds = [1, 2, 4];
}
