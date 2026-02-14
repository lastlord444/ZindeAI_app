import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zindeai_app/services/plan_cache_service.dart';
import 'package:zindeai_app/services/models/plan_models.dart';

void main() {
  late PlanCacheService cacheService;

  /// Test Plan factory.
  Plan createTestPlan({int dayCount = 2}) {
    return Plan(
      planId: 'test-plan-001',
      weekStart: '2026-02-10',
      days: List.generate(
        dayCount,
        (i) => DailyPlan(
          date: '2026-02-${10 + i}',
          meals: [
            MealItem(
              mealId: 'meal-$i-1',
              mealType: 'breakfast',
              name: 'Yulaf',
              kcal: 350,
              p: 12,
              c: 50,
              f: 8,
            ),
          ],
        ),
      ),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    cacheService = PlanCacheService(prefs: prefs);
  });

  group('PlanCacheService', () {
    test('get() boş cache → null döner', () async {
      final result = await cacheService.get();
      expect(result, isNull);
    });

    test('save() + get() → plan round-trip doğru', () async {
      final plan = createTestPlan();
      await cacheService.save(plan);
      final cached = await cacheService.get();

      expect(cached, isNotNull);
      expect(cached!.planId, equals('test-plan-001'));
      expect(cached.days.length, equals(2));
      expect(cached.days[0].meals[0].name, equals('Yulaf'));
      expect(cached.days[0].meals[0].kcal, equals(350));
    });

    test('clear() → cache temizlenir', () async {
      final plan = createTestPlan();
      await cacheService.save(plan);

      // Verinin var olduğunu doğrula
      expect(await cacheService.get(), isNotNull);

      // Temizle
      await cacheService.clear();
      expect(await cacheService.get(), isNull);
    });

    test('TTL expired → null döner ve cache temizlenir', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // 0 TTL → anında expire
      final expiredCache = PlanCacheService(
        prefs: prefs,
        ttl: Duration.zero,
      );

      final plan = createTestPlan();
      await expiredCache.save(plan);

      // Kısa gecikme (TTL=0, anında expire)
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final result = await expiredCache.get();
      expect(result, isNull);
    });

    test('getStatus() → doğru durum bilgisi', () async {
      // Boş cache
      var status = await cacheService.getStatus();
      expect(status.exists, isFalse);

      // Plan kaydet
      final plan = createTestPlan(dayCount: 3);
      await cacheService.save(plan);

      status = await cacheService.getStatus();
      expect(status.exists, isTrue);
      expect(status.expired, isFalse);
      expect(status.sizeBytes, greaterThan(0));
      expect(status.cachedAt, isNotNull);
    });

    test('bozuk JSON → null döner (cache temizlenir)', () async {
      SharedPreferences.setMockInitialValues({
        'cached_plan_data': 'INVALID_JSON{{{',
        'cached_plan_timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      final prefs = await SharedPreferences.getInstance();
      final service = PlanCacheService(prefs: prefs);

      final result = await service.get();
      expect(result, isNull);

      // Cache temizlenmiş olmalı
      final status = await service.getStatus();
      expect(status.exists, isFalse);
    });

    test('save() üzerine yazar (bounded: tek plan)', () async {
      final plan1 = createTestPlan(dayCount: 1);
      final plan2 = createTestPlan(dayCount: 5);

      await cacheService.save(plan1);
      var cached = await cacheService.get();
      expect(cached!.days.length, equals(1));

      // Üzerine yaz
      await cacheService.save(plan2);
      cached = await cacheService.get();
      expect(cached!.days.length, equals(5));
    });
  });
}
