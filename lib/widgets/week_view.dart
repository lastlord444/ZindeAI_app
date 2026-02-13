import 'package:flutter/material.dart';
import '../services/models/plan_models.dart';
import 'weekly_summary.dart';

/// Haftalık plan görünümü: Gün bazlı expansion + özet.
/// Loading ve empty state desteği ile (demo polish).
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Henüz bir haftalık plan yok',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Yukarıdaki "Plan Oluştur" butonuyla başlayın',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    // Plan var — özet + gün bazlı liste
    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        // Haftalık özet kartı
        WeeklySummary(plan: plan!),
        const SizedBox(height: 8),
        // Gün bazlı expansion tiles
        ...plan!.days.map((day) => _buildDayTile(day)),
      ],
    );
  }

  Widget _buildDayTile(DailyPlan day) {
    final dayKcal = day.meals.fold<double>(0, (sum, m) => sum + m.kcal);
    final consumed = day.meals.where((m) => m.isConsumed).length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: const Icon(Icons.calendar_today, size: 20),
        title: Text(
          _formatDate(day.date),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${day.meals.length} öğün • ${dayKcal.toStringAsFixed(0)} kcal • $consumed/${day.meals.length} tamamlandı',
          style: const TextStyle(fontSize: 12),
        ),
        children: day.meals.map((item) => ListTile(
          leading: Icon(
            _mealTypeIcon(item.mealType),
            color: item.isConsumed ? Colors.green : Colors.grey,
          ),
          title: Text(
            item.name,
            style: TextStyle(
              decoration: item.isConsumed ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text(
            '${item.kcal.toStringAsFixed(0)} kcal  •  '
            'P: ${item.p.toStringAsFixed(0)}g  '
            'K: ${item.c.toStringAsFixed(0)}g  '
            'Y: ${item.f.toStringAsFixed(0)}g',
            style: const TextStyle(fontSize: 11),
          ),
          trailing: item.isConsumed
              ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
              : const Icon(Icons.circle_outlined, size: 20, color: Colors.grey),
        )).toList(),
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
