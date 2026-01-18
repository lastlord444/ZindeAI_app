import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'plan_request.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class GeneratePlanRequest extends Equatable {
  final String userId;
  final String weekStart; // YYYY-MM-DD
  final String goalTag; // cut, bulk, maintain
  final String budgetMode; // low, medium, high
  final int? prepMaxMinutes;
  final String? fishPreference; // allow, prefer, avoid

  const GeneratePlanRequest({
    required this.userId,
    required this.weekStart,
    required this.goalTag,
    required this.budgetMode,
    this.prepMaxMinutes,
    this.fishPreference,
  });

  factory GeneratePlanRequest.fromJson(Map<String, dynamic> json) => _$GeneratePlanRequestFromJson(json);
  Map<String, dynamic> toJson() => _$GeneratePlanRequestToJson(this);

  @override
  List<Object?> get props => [userId, weekStart, goalTag, budgetMode, prepMaxMinutes, fishPreference];
}
