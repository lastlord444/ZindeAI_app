import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'plan_request.g.dart';

@JsonSerializable()
class GeneratePlanRequest extends Equatable {
  final int targetCalories;
  final String dietType; // e.g., 'keto', 'vegan'
  final List<String> allergies;
  final int numberOfDays;

  const GeneratePlanRequest({
    required this.targetCalories,
    required this.dietType,
    this.allergies = const [],
    this.numberOfDays = 7,
  });

  factory GeneratePlanRequest.fromJson(Map<String, dynamic> json) => _$GeneratePlanRequestFromJson(json);
  Map<String, dynamic> toJson() => _$GeneratePlanRequestToJson(this);

  @override
  List<Object?> get props => [targetCalories, dietType, allergies, numberOfDays];
}
