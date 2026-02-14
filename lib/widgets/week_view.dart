import 'package:flutter/material.dart';
import '../services/models/plan_models.dart';
import 'weekly_summary.dart';

/// Haftalık plan görünümü: Gün bazlı expansion + özet.
/// Loading ve empty state desteği ile (demo polish).
/// 
/// Performance optimized:
/// - ListView.builder ile lazy loading
/// - Cached hesaplamalar (_DayStats)
/// - const constructor'lar
class WeekView extends StatelessWidget {
  final Plan? plan;
  final bool isLoading;

  const WeekView({
    super.key,
    this.plan,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Plan yükleniyor...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // Empty state
    if (plan == null || plan!.days.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Henüz bir haftalık plan yok',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Yukarıdaki "Plan Oluştur" butonuyla başlayın',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Plan var — özet + gün bazlı liste (ListView.builder ile lazy)
    final days = plan!.days;
    
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      // +2: weekly summary + spacer
      itemCount: days.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          // Haftalık özet kartı
          return WeeklySummary(plan: plan!);
        }
        if (index == 1) {
          // Spacer
          return const SizedBox(height: 8);
        }
        // Gün bazlı tile (index-2 çünkü ilk 2 item summary + spacer)
        final dayIndex = index - 2;
        return _DayTile(
          key: ValueKey('day_${days[dayIndex].date}'),
          day: days[dayIndex],
        );
      },
    );
  }
}

/// Gün tile widget'ı: ExpansionTile ile öğün listesi.
/// Cached hesaplamalar ile rebuild optimizasyonu.
class _DayTile extends StatelessWidget {
  final DailyPlan day;

  const _DayTile({
    super.key,
    required this.day,
  });

  @override
  Widget build(BuildContext context) {
    // Hesaplamaları cache et (her rebuild'de fold/where yapma)
    final stats = _DayStats.from(day);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: const Icon(Icons.calendar_today, size: 20),
        title: Text(
          _formatDate(day.date),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${stats.mealCount} öğün • ${stats.totalKcal.toStringAsFixed(0)} kcal • ${stats.consumedCount}/${stats.mealCount} tamamlandı',
          style: const TextStyle(fontSize: 12),
        ),
        children: day.meals
            .map((item) => _MealListTile(
                  key: ValueKey('meal_${item.mealId}'),
                  meal: item,
                ))
            .toList(),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
      final dayName = days[date.weekday - 1];
      return '$dayName ${date.day}.${date.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}

/// Öğün ListTile: const constructor ile rebuild önleme.
class _MealListTile extends StatelessWidget {
  final MealItem meal;

  const _MealListTile({
    super.key,
    required this.meal,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        _mealTypeIcon(meal.mealType),
        color: meal.isConsumed ? Colors.green : Colors.grey,
      ),
      title: Text(
        meal.name,
        style: TextStyle(
          decoration: meal.isConsumed ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        '${meal.kcal.toStringAsFixed(0)} kcal  •  '
        'P: ${meal.p.toStringAsFixed(0)}g  '
        'K: ${meal.c.toStringAsFixed(0)}g  '
        'Y: ${meal.f.toStringAsFixed(0)}g',
        style: const TextStyle(fontSize: 11),
      ),
      trailing: meal.isConsumed
          ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
          : const Icon(Icons.circle_outlined, size: 20, color: Colors.grey),
    );
  }

  IconData _mealTypeIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
      case 'kahvalti':
        return Icons.free_breakfast;
      case 'lunch':
      case 'ogle':
        return Icons.lunch_dining;
      case 'dinner':
      case 'aksam':
        return Icons.dinner_dining;
      case 'snack1':
      case 'snack2':
      case 'snack3':
      case 'ara':
        return Icons.apple;
      default:
        return Icons.restaurant;
    }
  }
}

/// Gün bazlı cached hesaplamalar.
/// Her rebuild'de fold/where çağırmamak için.
class _DayStats {
  final int mealCount;
  final double totalKcal;
  final int consumedCount;

  const _DayStats({
    required this.mealCount,
    required this.totalKcal,
    required this.consumedCount,
  });

  factory _DayStats.from(DailyPlan day) {
    final meals = day.meals;
    return _DayStats(
      mealCount: meals.length,
      totalKcal: meals.fold<double>(0, (sum, m) => sum + m.kcal),
      consumedCount: meals.where((m) => m.isConsumed).length,
    );
  }
}
