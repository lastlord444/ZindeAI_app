import 'package:flutter/material.dart';
import '../services/models/plan_models.dart';

/// Haftalık özet widget: Toplam kcal, P/C/F ve adherence (demo polish).
class WeeklySummary extends StatelessWidget {
  final Plan plan;

  const WeeklySummary({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final stats = _calculateWeeklyStats(plan);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Haftalık Özet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatColumn('Kalori', '${stats.totalKcal.toStringAsFixed(0)} kcal'),
                _buildStatColumn('Protein', '${stats.totalProtein.toStringAsFixed(0)}g'),
                _buildStatColumn('Karb', '${stats.totalCarbs.toStringAsFixed(0)}g'),
                _buildStatColumn('Yağ', '${stats.totalFat.toStringAsFixed(0)}g'),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: stats.adherence,
              backgroundColor: Colors.grey.shade300,
              color: stats.adherence > 0.7 ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 4),
            Text(
              'Uyum: ${(stats.adherence * 100).toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  _WeeklyStats _calculateWeeklyStats(Plan plan) {
    double totalKcal = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    int consumedMeals = 0;
    int totalMeals = 0;

    for (var day in plan.days) {
      for (var meal in day.meals) {
        totalKcal += meal.kcal;
        totalProtein += meal.p;
        totalCarbs += meal.c;
        totalFat += meal.f;
        totalMeals++;
        if (meal.isConsumed) consumedMeals++;
      }
    }

    final adherence = totalMeals > 0 ? consumedMeals / totalMeals : 0.0;

    return _WeeklyStats(
      totalKcal: totalKcal,
      totalProtein: totalProtein,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
      adherence: adherence,
    );
  }
}

class _WeeklyStats {
  final double totalKcal;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double adherence;

  _WeeklyStats({
    required this.totalKcal,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.adherence,
  });
}
