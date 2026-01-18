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
    );

Map<String, dynamic> _$GeneratePlanRequestToJson(
        GeneratePlanRequest instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'week_start': instance.weekStart,
      'goal_tag': instance.goalTag,
    };
