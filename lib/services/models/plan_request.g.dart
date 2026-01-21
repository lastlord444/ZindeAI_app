// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeneratePlanRequest _$GeneratePlanRequestFromJson(Map<String, dynamic> json) =>
    GeneratePlanRequest(
      userId: json['user_id'] as String,
      weekStart: json['week_start'] as String,
      goalTag: json['goal_tag'] as String,
      budgetMode: json['budget_mode'] as String,
      prepMaxMinutes: (json['prep_max_minutes'] as num?)?.toInt(),
      fishPreference: json['fish_preference'] as String?,
      tariffMode: json['tariff_mode'] as String? ?? 'normal',
    );

Map<String, dynamic> _$GeneratePlanRequestToJson(
        GeneratePlanRequest instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'week_start': instance.weekStart,
      'goal_tag': instance.goalTag,
      'budget_mode': instance.budgetMode,
      'prep_max_minutes': instance.prepMaxMinutes,
      'fish_preference': instance.fishPreference,
      'tariff_mode': instance.tariffMode,
    };
