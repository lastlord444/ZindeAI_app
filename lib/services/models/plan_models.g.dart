// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Plan _$PlanFromJson(Map<String, dynamic> json) => Plan(
      planId: json['plan_id'] as String,
      weekStart: json['week_start'] as String,
      days: (json['days'] as List<dynamic>)
          .map((e) => DailyPlan.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PlanToJson(Plan instance) => <String, dynamic>{
      'plan_id': instance.planId,
      'week_start': instance.weekStart,
      'days': instance.days,
    };

DailyPlan _$DailyPlanFromJson(Map<String, dynamic> json) => DailyPlan(
      date: json['date'] as String,
      meals: (json['meals'] as List<dynamic>)
          .map((e) => MealItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DailyPlanToJson(DailyPlan instance) => <String, dynamic>{
      'date': instance.date,
      'meals': instance.meals,
    };

MealItem _$MealItemFromJson(Map<String, dynamic> json) => MealItem(
      mealId: json['meal_id'] as String,
      mealType: json['meal_type'] as String,
      name: json['name'] as String? ?? 'Yemek',
      kcal: (json['kcal'] as num).toDouble(),
      p: (json['p'] as num).toDouble(),
      c: (json['c'] as num).toDouble(),
      f: (json['f'] as num).toDouble(),
      estimatedCostTry: (json['estimated_cost_try'] as num?)?.toDouble(),
      flags:
          (json['flags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      alt1MealId: json['alt1_meal_id'] as String?,
      alt2MealId: json['alt2_meal_id'] as String?,
      isConsumed: json['is_consumed'] as bool? ?? false,
    );

Map<String, dynamic> _$MealItemToJson(MealItem instance) => <String, dynamic>{
      'meal_id': instance.mealId,
      'meal_type': instance.mealType,
      'name': instance.name,
      'kcal': instance.kcal,
      'p': instance.p,
      'c': instance.c,
      'f': instance.f,
      'estimated_cost_try': instance.estimatedCostTry,
      'flags': instance.flags,
      'alt1_meal_id': instance.alt1MealId,
      'alt2_meal_id': instance.alt2MealId,
      'is_consumed': instance.isConsumed,
    };
