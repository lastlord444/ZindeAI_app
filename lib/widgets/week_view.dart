import 'package:flutter/material.dart';
import '../services/models/plan_models.dart';

class WeekView extends StatelessWidget {
  final Plan plan;

  const WeekView({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: plan.days.length,
      itemBuilder: (context, index) {
        final day = plan.days[index];
        
        return ExpansionTile(
          title: Text('Tarih ${day.date}'),
          subtitle: Text('${day.meals.length} öğün planlandı'),
          children: day.meals.map((item) => ListTile(
            leading: const Icon(Icons.restaurant),
            title: Text(item.name),
            subtitle: Text('${item.mealType} - ${item.kcal} kcal'),
            trailing: item.isConsumed 
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.circle_outlined),
          )).toList(),
        );
      },
    );
  }
}
