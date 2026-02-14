import 'package:flutter/foundation.dart';

/// Log seviyeleri (düşükten yükseğe).
enum LogLevel {
  debug,
  info,
  warn,
  error,
}

/// Minimal error logging servisi.
///
/// Format: [LEVEL] [TAG] message
/// Release modda debug loglar kapalı (kDebugMode guard).
/// Crashlytics hook point (interface, entegrasyon yok).
class LogService {
  LogService._();

  /// Singleton instance.
  static final LogService instance = LogService._();

  /// Minimum log seviyesi (release'de INFO).
  static LogLevel get minLevel => kDebugMode ? LogLevel.debug : LogLevel.info;

  /// Debug log (sadece debug modda).
  static void d(String tag, String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, tag, message, error: error, stackTrace: stackTrace);
  }

  /// Info log.
  static void i(String tag, String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, tag, message, error: error, stackTrace: stackTrace);
  }

  /// Warning log.
  static void w(String tag, String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.warn, tag, message, error: error, stackTrace: stackTrace);
  }

  /// Error log.
  static void e(String tag, String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, tag, message, error: error, stackTrace: stackTrace);
  }

  /// Internal log method.
  static void _log(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Seviye filtresi (release'de debug spam yok)
    if (level.index < minLevel.index) return;

    final levelStr = level.name.toUpperCase();
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] [$levelStr] [$tag] $message';

    // Console output (debugPrint kullanarak truncation önlenir)
    debugPrint(logMessage);

    if (error != null) {
      debugPrint('  Error: $error');
    }

    if (stackTrace != null) {
      debugPrint('  StackTrace: $stackTrace');
    }

    // Crashlytics hook point (şimdilik boş, gelecekte entegre edilebilir)
    if (level == LogLevel.error) {
      _reportToCrashlytics(tag, message, error, stackTrace);
    }
  }

  /// Crashlytics entegrasyonu için hook (interface only).
  /// Gerçek Crashlytics entegrasyonu ayrı PR'da yapılacak.
  static void _reportToCrashlytics(
    String tag,
    String message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    // TODO: Firebase Crashlytics entegrasyonu (optional, gelecekte)
    // FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: '[$tag] $message');
  }
}
