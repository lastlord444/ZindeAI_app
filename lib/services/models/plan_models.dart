import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'plan_models.g.dart';

@JsonSerializable()
class Plan extends Equatable {
  final String id;
  final String title;
  final DateTime createdAt;
  final List<DailyPlan> days;

  const Plan({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.days,
  });

  factory Plan.fromJson(Map<String, dynamic> json) => _$PlanFromJson(json);
  Map<String, dynamic> toJson() => _$PlanToJson(this);

  @override
  List<Object?> get props => [id, title, createdAt, days];
}

@JsonSerializable()
class DailyPlan extends Equatable {
  final int dayNumber;
  final DateTime date;
  final List<MealItem> meals;
  final Map<String, dynamic>? dailyNutrients;

  const DailyPlan({
    required this.dayNumber,
    required this.date,
    required this.meals,
    this.dailyNutrients,
  });

  factory DailyPlan.fromJson(Map<String, dynamic> json) => _$DailyPlanFromJson(json);
  Map<String, dynamic> toJson() => _$DailyPlanToJson(this);

  @override
  List<Object?> get props => [dayNumber, date, meals, dailyNutrients];
}

@JsonSerializable()
class MealItem extends Equatable {
  final String id;
  final String name;
  final String type; // Breakfast, Lunch, Dinner, Snack
  final int calories;
  final Map<String, dynamic>? macros; // protein, carbs, fat
  final bool isConsumed;

  const MealItem({
    required this.id,
    required this.name,
    required this.type,
    required this.calories,
    this.macros,
    this.isConsumed = false,
  });

  factory MealItem.fromJson(Map<String, dynamic> json) => _$MealItemFromJson(json);
  Map<String, dynamic> toJson() => _$MealItemToJson(this);

  MealItem copyWith({bool? isConsumed}) {
    return MealItem(
      id: id,
      name: name,
      type: type,
      calories: calories,
      macros: macros,
      isConsumed: isConsumed ?? this.isConsumed,
    );
  }

  @override
  List<Object?> get props => [id, name, isConsumed];
}
