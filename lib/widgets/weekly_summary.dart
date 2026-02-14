import 'package:flutter/material.dart';
import '../services/models/plan_models.dart';

/// Haftalık özet widget: Toplam kcal, P/C/F ve adherence.
/// Edge case'leri güvenli handle eder: boş gün, eksik macro, 0 öğün.
class WeeklySummary extends StatelessWidget {
  final Plan plan;

  const WeeklySummary({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final stats = WeeklyStatsCalculator.calculate(plan);

    // 7 gün boş → empty state
    if (stats.totalMeals == 0) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.calendar_today, size: 40, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'Henüz haftalık plan yok',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Plan oluşturulduktan sonra haftalık özetiniz burada görünecek.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Haftalık Özet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${stats.daysWithMeals}/7 gün',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatColumn(
                    'Kalori', '${stats.totalKcal.toStringAsFixed(0)} kcal'),
                _buildStatColumn(
                    'Protein', '${stats.totalProtein.toStringAsFixed(0)}g'),
                _buildStatColumn(
                    'Karb', '${stats.totalCarbs.toStringAsFixed(0)}g'),
                _buildStatColumn(
                    'Yağ', '${stats.totalFat.toStringAsFixed(0)}g'),
              ],
            ),
            if (stats.daysWithMeals > 0) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatColumn('Gün Ort. Kcal',
                      '${stats.dailyAvgKcal.toStringAsFixed(0)} kcal'),
                  _buildStatColumn('Gün Ort. P',
                      '${stats.dailyAvgProtein.toStringAsFixed(0)}g'),
                  _buildStatColumn('Gün Ort. K',
                      '${stats.dailyAvgCarbs.toStringAsFixed(0)}g'),
                  _buildStatColumn('Gün Ort. Y',
                      '${stats.dailyAvgFat.toStringAsFixed(0)}g'),
                ],
              ),
            ],
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: stats.adherence.clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade200,
                color: _adherenceColor(stats.adherence),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Uyum: ${(stats.adherence * 100).toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                Text(
                  '${stats.consumedMeals}/${stats.totalMeals} öğün',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _adherenceColor(double adherence) {
    if (adherence >= 0.8) return Colors.green;
    if (adherence >= 0.5) return Colors.orange;
    return Colors.red;
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value,
            style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

/// Haftalık istatistik hesaplama — test edilebilir, saf fonksiyon.
class WeeklyStatsCalculator {
  /// Plan verisi üzerinden haftalık toplam ve adherence hesapla.
  /// Null/NaN/Infinity makro değerleri 0 kabul edilir.
  static WeeklyStats calculate(Plan plan) {
    double totalKcal = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    int consumedMeals = 0;
    int totalMeals = 0;
    int daysWithMeals = 0;

    for (final day in plan.days) {
      if (day.meals.isNotEmpty) {
        daysWithMeals++;
      }
      for (final meal in day.meals) {
        totalKcal += _safeDouble(meal.kcal);
        totalProtein += _safeDouble(meal.p);
        totalCarbs += _safeDouble(meal.c);
        totalFat += _safeDouble(meal.f);
        totalMeals++;
        if (meal.isConsumed) consumedMeals++;
      }
    }

    // Adherence: consumedMeals / totalMeals (division-by-zero koruması)
    final adherence = totalMeals > 0 ? consumedMeals / totalMeals : 0.0;

    return WeeklyStats(
      totalKcal: totalKcal,
      totalProtein: totalProtein,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
      adherence: adherence,
      consumedMeals: consumedMeals,
      totalMeals: totalMeals,
      daysWithMeals: daysWithMeals,
    );
  }

  /// NaN ve Infinity kontrolü: güvenli double dönüşümü.
  static double _safeDouble(double value) {
    if (value.isNaN || value.isInfinite) return 0.0;
    return value;
  }
}

/// Haftalık istatistikler — immutable, test edilebilir.
class WeeklyStats {
  final double totalKcal;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double adherence;
  final int consumedMeals;
  final int totalMeals;
  final int daysWithMeals;

  const WeeklyStats({
    required this.totalKcal,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.adherence,
    required this.consumedMeals,
    required this.totalMeals,
    required this.daysWithMeals,
  });

  /// Günlük ortalama kcal (daysWithMeals > 0 kontrolü).
  double get dailyAvgKcal =>
      daysWithMeals > 0 ? totalKcal / daysWithMeals : 0.0;

  /// Günlük ortalama protein.
  double get dailyAvgProtein =>
      daysWithMeals > 0 ? totalProtein / daysWithMeals : 0.0;

  /// Günlük ortalama karbonhidrat.
  double get dailyAvgCarbs =>
      daysWithMeals > 0 ? totalCarbs / daysWithMeals : 0.0;

  /// Günlük ortalama yağ.
  double get dailyAvgFat =>
      daysWithMeals > 0 ? totalFat / daysWithMeals : 0.0;
}
