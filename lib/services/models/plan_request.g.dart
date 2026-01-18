// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeneratePlanRequest _$GeneratePlanRequestFromJson(Map<String, dynamic> json) =>
    GeneratePlanRequest(
      targetCalories: (json['targetCalories'] as num).toInt(),
      dietType: json['dietType'] as String,
      allergies: (json['allergies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      numberOfDays: (json['numberOfDays'] as num?)?.toInt() ?? 7,
    );

Map<String, dynamic> _$GeneratePlanRequestToJson(
        GeneratePlanRequest instance) =>
    <String, dynamic>{
      'targetCalories': instance.targetCalories,
      'dietType': instance.dietType,
      'allergies': instance.allergies,
      'numberOfDays': instance.numberOfDays,
    };
