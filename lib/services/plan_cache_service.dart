import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'log_service.dart';
import 'models/plan_models.dart';

/// Plan önbellekleme servisi.
///
/// SharedPreferences ile JSON serialization kullanır.
/// TTL: 3 saat (varsayılan), expired cache = null.
/// Bounded payload: tek plan tutulur (storage overflow yok).
class PlanCacheService {
  static const String _tag = 'PlanCache';
  static const String _cacheKey = 'cached_plan_data';
  static const String _timestampKey = 'cached_plan_timestamp';
  static const Duration _defaultTTL = Duration(hours: 3);

  final SharedPreferences _prefs;
  final Duration ttl;

  PlanCacheService({
    required SharedPreferences prefs,
    this.ttl = _defaultTTL,
  }) : _prefs = prefs;

  /// Singleton factory (lazy init).
  static Future<PlanCacheService> create({Duration? ttl}) async {
    final prefs = await SharedPreferences.getInstance();
    return PlanCacheService(prefs: prefs, ttl: ttl ?? _defaultTTL);
  }

  /// Plan'ı cache'den al.
  /// Expired veya yoksa null döner.
  Future<Plan?> get() async {
    try {
      final jsonStr = _prefs.getString(_cacheKey);
      final timestamp = _prefs.getInt(_timestampKey);

      if (jsonStr == null || timestamp == null) {
        LogService.d(_tag, 'Cache miss (no data)');
        return null;
      }

      // TTL check
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final age = now.difference(cachedAt);

      if (age > ttl) {
        LogService.i(_tag, 'Cache expired (age: ${age.inMinutes}min, TTL: ${ttl.inMinutes}min)');
        await clear(); // Expired cache'i temizle
        return null;
      }

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final plan = Plan.fromJson(json);
      LogService.i(_tag, 'Cache hit (age: ${age.inMinutes}min, ${plan.days.length} days)');
      return plan;
    } catch (e, st) {
      LogService.e(_tag, 'Cache read failed', error: e, stackTrace: st);
      await clear(); // Bozuk cache'i temizle
      return null;
    }
  }

  /// Plan'ı cache'e yaz.
  Future<void> save(Plan plan) async {
    try {
      final jsonStr = jsonEncode(plan.toJson());
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      await _prefs.setString(_cacheKey, jsonStr);
      await _prefs.setInt(_timestampKey, timestamp);

      LogService.i(_tag, 'Saved plan to cache (${plan.days.length} days, ${jsonStr.length} bytes)');
    } catch (e, st) {
      LogService.e(_tag, 'Cache write failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Cache'i temizle.
  Future<void> clear() async {
    try {
      await _prefs.remove(_cacheKey);
      await _prefs.remove(_timestampKey);
      LogService.d(_tag, 'Cache cleared');
    } catch (e, st) {
      LogService.e(_tag, 'Cache clear failed', error: e, stackTrace: st);
    }
  }

  /// Cache durumu (debug için).
  Future<CacheStatus> getStatus() async {
    final jsonStr = _prefs.getString(_cacheKey);
    final timestamp = _prefs.getInt(_timestampKey);

    if (jsonStr == null || timestamp == null) {
      return CacheStatus(exists: false);
    }

    final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final age = DateTime.now().difference(cachedAt);
    final expired = age > ttl;

    return CacheStatus(
      exists: true,
      cachedAt: cachedAt,
      age: age,
      expired: expired,
      sizeBytes: jsonStr.length,
    );
  }
}

/// Cache durumu (debug/UI için).
class CacheStatus {
  final bool exists;
  final DateTime? cachedAt;
  final Duration? age;
  final bool expired;
  final int? sizeBytes;

  CacheStatus({
    required this.exists,
    this.cachedAt,
    this.age,
    this.expired = false,
    this.sizeBytes,
  });
}
