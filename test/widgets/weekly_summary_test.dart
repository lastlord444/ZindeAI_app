// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter_test/flutter_test.dart';
import 'package:zindeai_app/services/models/plan_models.dart';
import 'package:zindeai_app/widgets/weekly_summary.dart';

void main() {
  group('WeeklyStatsCalculator', () {
    test('Boş hafta (0 gün) → tüm toplamlar 0, adherence 0', () {
      const plan = Plan(
        planId: 'test-empty',
        weekStart: '2026-02-09',
        days: [],
      );

      final stats = WeeklyStatsCalculator.calculate(plan);

      expect(stats.totalKcal, 0.0);
      expect(stats.totalProtein, 0.0);
      expect(stats.totalCarbs, 0.0);
      expect(stats.totalFat, 0.0);
      expect(stats.adherence, 0.0);
      expect(stats.totalMeals, 0);
      expect(stats.consumedMeals, 0);
      expect(stats.daysWithMeals, 0);
      expect(stats.dailyAvgKcal, 0.0);
      expect(stats.dailyAvgProtein, 0.0);
      expect(stats.dailyAvgCarbs, 0.0);
      expect(stats.dailyAvgFat, 0.0);
    });

    test('Günler var ama öğün yok → tüm toplamlar 0', () {
      const plan = Plan(
        planId: 'test-empty-days',
        weekStart: '2026-02-09',
        days: [
          DailyPlan(date: '2026-02-09', meals: []),
          DailyPlan(date: '2026-02-10', meals: []),
          DailyPlan(date: '2026-02-11', meals: []),
        ],
      );

      final stats = WeeklyStatsCalculator.calculate(plan);

      expect(stats.totalKcal, 0.0);
      expect(stats.totalMeals, 0);
      expect(stats.daysWithMeals, 0);
      expect(stats.adherence, 0.0);
    });

    test('Tek gün, tek öğün → doğru toplamlar', () {
      const plan = Plan(
        planId: 'test-single',
        weekStart: '2026-02-09',
        days: [
          DailyPlan(
            date: '2026-02-09',
            meals: [
              MealItem(
                mealId: 'm1',
                mealType: 'breakfast',
                name: 'Yumurta',
                kcal: 350.0,
                p: 25.0,
                c: 10.0,
                f: 22.0,
                isConsumed: true,
              ),
            ],
          ),
        ],
      );

      final stats = WeeklyStatsCalculator.calculate(plan);

      expect(stats.totalKcal, 350.0);
      expect(stats.totalProtein, 25.0);
      expect(stats.totalCarbs, 10.0);
      expect(stats.totalFat, 22.0);
      expect(stats.totalMeals, 1);
      expect(stats.consumedMeals, 1);
      expect(stats.adherence, 1.0);
      expect(stats.daysWithMeals, 1);
      expect(stats.dailyAvgKcal, 350.0);
    });

    test('Karışık günler → doğru toplam + ortalama', () {
      const plan = Plan(
        planId: 'test-mixed',
        weekStart: '2026-02-09',
        days: [
          DailyPlan(
            date: '2026-02-09',
            meals: [
              MealItem(
                mealId: 'm1',
                mealType: 'breakfast',
                kcal: 400.0,
                p: 30.0,
                c: 40.0,
                f: 15.0,
                isConsumed: true,
              ),
              MealItem(
                mealId: 'm2',
                mealType: 'lunch',
                kcal: 600.0,
                p: 35.0,
                c: 60.0,
                f: 20.0,
                isConsumed: true,
              ),
            ],
          ),
          // Boş gün → toplama dahil değil
          DailyPlan(date: '2026-02-10', meals: []),
          DailyPlan(
            date: '2026-02-11',
            meals: [
              MealItem(
                mealId: 'm3',
                mealType: 'dinner',
                kcal: 500.0,
                p: 40.0,
                c: 30.0,
                f: 25.0,
                isConsumed: false,
              ),
            ],
          ),
        ],
      );

      final stats = WeeklyStatsCalculator.calculate(plan);

      // Toplam: 400 + 600 + 500 = 1500 kcal
      expect(stats.totalKcal, 1500.0);
      // P: 30 + 35 + 40 = 105
      expect(stats.totalProtein, 105.0);
      // C: 40 + 60 + 30 = 130
      expect(stats.totalCarbs, 130.0);
      // F: 15 + 20 + 25 = 60
      expect(stats.totalFat, 60.0);
      // 3 meal, 2 consumed
      expect(stats.totalMeals, 3);
      expect(stats.consumedMeals, 2);
      // Adherence: 2/3 ≈ 0.6667
      expect(stats.adherence, closeTo(0.6667, 0.001));
      // 2 gün ile meal var (boş gün sayılmaz)
      expect(stats.daysWithMeals, 2);
      // Günlük ortalama: 1500 / 2 = 750
      expect(stats.dailyAvgKcal, 750.0);
      // P ort: 105 / 2 = 52.5
      expect(stats.dailyAvgProtein, 52.5);
    });

    // NaN/Infinity const constructor'da kullanılamaz, bu yüzden const yok.
    test('NaN/Infinity makro değerleri → 0 olarak işlenir', () {
      final plan = Plan(
        planId: 'test-nan',
        weekStart: '2026-02-09',
        days: [
          DailyPlan(
            date: '2026-02-09',
            meals: [
              MealItem(
                mealId: 'm1',
                mealType: 'breakfast',
                kcal: double.nan,
                p: double.infinity,
                c: double.negativeInfinity,
                f: 10.0,
                isConsumed: false,
              ),
              const MealItem(
                mealId: 'm2',
                mealType: 'lunch',
                kcal: 500.0,
                p: 30.0,
                c: 50.0,
                f: 20.0,
                isConsumed: true,
              ),
            ],
          ),
        ],
      );

      final stats = WeeklyStatsCalculator.calculate(plan);

      // NaN → 0, Infinity → 0: kcal = 0 + 500 = 500
      expect(stats.totalKcal, 500.0);
      // P: 0 + 30 = 30
      expect(stats.totalProtein, 30.0);
      // C: 0 + 50 = 50
      expect(stats.totalCarbs, 50.0);
      // F: 10 + 20 = 30
      expect(stats.totalFat, 30.0);
      expect(stats.totalMeals, 2);
      expect(stats.consumedMeals, 1);
      expect(stats.adherence, 0.5);
    });

    test('Tam 7 günlük plan → adherence ve toplamlar doğru', () {
      final days = List.generate(
        7,
        (i) => DailyPlan(
          date: '2026-02-${(9 + i).toString().padLeft(2, '0')}',
          meals: [
            MealItem(
              mealId: 'b$i',
              mealType: 'breakfast',
              kcal: 300.0,
              p: 20.0,
              c: 30.0,
              f: 10.0,
              isConsumed: i < 5, // 5 gün consumed
            ),
            MealItem(
              mealId: 'l$i',
              mealType: 'lunch',
              kcal: 500.0,
              p: 35.0,
              c: 50.0,
              f: 18.0,
              isConsumed: i < 5,
            ),
            MealItem(
              mealId: 'd$i',
              mealType: 'dinner',
              kcal: 450.0,
              p: 30.0,
              c: 40.0,
              f: 20.0,
              isConsumed: i < 3, // 3 gün consumed
            ),
          ],
        ),
      );

      final plan = Plan(
        planId: 'test-full-week',
        weekStart: '2026-02-09',
        days: days,
      );

      final stats = WeeklyStatsCalculator.calculate(plan);

      // 7 gün × 3 öğün = 21 meal
      expect(stats.totalMeals, 21);
      expect(stats.daysWithMeals, 7);

      // Toplam kcal: 7 × (300 + 500 + 450) = 7 × 1250 = 8750
      expect(stats.totalKcal, 8750.0);
      // P: 7 × (20 + 35 + 30) = 7 × 85 = 595
      expect(stats.totalProtein, 595.0);
      // C: 7 × (30 + 50 + 40) = 7 × 120 = 840
      expect(stats.totalCarbs, 840.0);
      // F: 7 × (10 + 18 + 20) = 7 × 48 = 336
      expect(stats.totalFat, 336.0);

      // Consumed: breakfast 5 + lunch 5 + dinner 3 = 13
      expect(stats.consumedMeals, 13);
      // Adherence: 13/21 ≈ 0.619
      expect(stats.adherence, closeTo(0.619, 0.001));

      // Günlük ort: 8750 / 7 = 1250
      expect(stats.dailyAvgKcal, 1250.0);
    });
  });
}
