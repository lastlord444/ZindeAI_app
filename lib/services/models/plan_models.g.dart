// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Plan _$PlanFromJson(Map<String, dynamic> json) => Plan(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      days: (json['days'] as List<dynamic>)
          .map((e) => DailyPlan.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PlanToJson(Plan instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'createdAt': instance.createdAt.toIso8601String(),
      'days': instance.days,
    };

DailyPlan _$DailyPlanFromJson(Map<String, dynamic> json) => DailyPlan(
      dayNumber: (json['dayNumber'] as num).toInt(),
      date: DateTime.parse(json['date'] as String),
      meals: (json['meals'] as List<dynamic>)
          .map((e) => MealItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      dailyNutrients: json['dailyNutrients'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$DailyPlanToJson(DailyPlan instance) => <String, dynamic>{
      'dayNumber': instance.dayNumber,
      'date': instance.date.toIso8601String(),
      'meals': instance.meals,
      'dailyNutrients': instance.dailyNutrients,
    };

MealItem _$MealItemFromJson(Map<String, dynamic> json) => MealItem(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      calories: (json['calories'] as num).toInt(),
      macros: json['macros'] as Map<String, dynamic>?,
      isConsumed: json['isConsumed'] as bool? ?? false,
    );

Map<String, dynamic> _$MealItemToJson(MealItem instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'calories': instance.calories,
      'macros': instance.macros,
      'isConsumed': instance.isConsumed,
    };
