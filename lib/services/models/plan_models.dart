import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'plan_models.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Plan extends Equatable {
  final String planId;
  final String weekStart;
  final List<DailyPlan> days;

  const Plan({
    required this.planId,
    required this.weekStart,
    required this.days,
  });

  factory Plan.fromJson(Map<String, dynamic> json) => _$PlanFromJson(json);
  Map<String, dynamic> toJson() => _$PlanToJson(this);

  @override
  List<Object?> get props => [planId, weekStart, days];
}

@JsonSerializable(fieldRename: FieldRename.snake)
class DailyPlan extends Equatable {
  final String date; // YYYY-MM-DD
  final List<MealItem> meals;

  const DailyPlan({
    required this.date,
    required this.meals,
  });

  factory DailyPlan.fromJson(Map<String, dynamic> json) => _$DailyPlanFromJson(json);
  Map<String, dynamic> toJson() => _$DailyPlanToJson(this);

  @override
  List<Object?> get props => [date, meals];
}

@JsonSerializable(fieldRename: FieldRename.snake)
class MealItem extends Equatable {
  final String mealId;
  final String mealType; // breakfast, snack1, lunch, snack2, dinner, snack3
  final String name; // Not in schema but UI needs it. Assuming backend might send it or we derive. 
                     // IMPORTANT: Schema doesn't list 'name', but previous code had it.
                     // I will verify if I should include 'name' or make it nullable/default.
                     // If backend doesn't send it, this will crash.
                     // Contract schema viewed earlier didn't show 'name'. 
                     // I will default it to 'Meal' to prevent crash if missing.
  final double kcal;
  final double p;
  final double c;
  final double f;
  final double? estimatedCostTry;
  final List<String>? flags;
  final String? alt1MealId;
  final String? alt2MealId;
  @JsonKey(defaultValue: false)
  final bool isConsumed; // Not in schema response usually, but needed for client state? 
                         // Or maybe backend sends it? 
                         // Previous code had it. 
                         // If backend doesn't send, default to false.

  const MealItem({
    required this.mealId,
    required this.mealType,
    this.name = 'Yemek', // Default
    required this.kcal,
    required this.p,
    required this.c,
    required this.f,
    this.estimatedCostTry,
    this.flags,
    this.alt1MealId,
    this.alt2MealId,
    this.isConsumed = false,
  });

  factory MealItem.fromJson(Map<String, dynamic> json) => _$MealItemFromJson(json);
  Map<String, dynamic> toJson() => _$MealItemToJson(this);

  MealItem copyWith({bool? isConsumed}) {
    return MealItem(
      mealId: mealId,
      mealType: mealType,
      name: name,
      kcal: kcal,
      p: p,
      c: c,
      f: f,
      estimatedCostTry: estimatedCostTry,
      flags: flags,
      alt1MealId: alt1MealId,
      alt2MealId: alt2MealId,
      isConsumed: isConsumed ?? this.isConsumed,
    );
  }

  @override
  List<Object?> get props => [mealId, mealType, name, kcal, p, c, f, isConsumed];
}
