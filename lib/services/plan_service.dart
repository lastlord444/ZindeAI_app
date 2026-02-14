import 'api_client.dart';
import 'log_service.dart';
import 'models/plan_models.dart';
import 'models/plan_request.dart';

class PlanService {
  static const String _tag = 'PlanService';
  final ApiClient _apiClient;

  PlanService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Generates a new diet plan based on user preferences.
  Future<Plan> generatePlan(GeneratePlanRequest request) async {
    LogService.i(_tag, 'generatePlan started (goal=${request.goalTag}, budget=${request.budgetMode})');
    try {
      final responseData = await _apiClient.post(
        '/plans/generate',
        data: request.toJson(),
      );
      final plan = Plan.fromJson(responseData);
      LogService.i(_tag, 'generatePlan success: ${plan.days.length} days');
      return plan;
    } catch (e, st) {
      LogService.e(_tag, 'generatePlan failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Retrieves an existing plan by ID.
  Future<Plan> getPlan(String planId) async {
    LogService.d(_tag, 'getPlan($planId)');
    try {
      final responseData = await _apiClient.get('/plans/$planId');
      return Plan.fromJson(responseData);
    } catch (e, st) {
      LogService.e(_tag, 'getPlan($planId) failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Marks a specific meal as consumed.
  Future<void> markMealConsumed(String planId, String mealId, bool isConsumed) async {
    LogService.d(_tag, 'markMealConsumed(plan=$planId, meal=$mealId, consumed=$isConsumed)');
    try {
      await _apiClient.put(
        '/plans/$planId/meals/$mealId/consume',
        data: {'isConsumed': isConsumed},
      );
    } catch (e, st) {
      LogService.e(_tag, 'markMealConsumed failed', error: e, stackTrace: st);
      rethrow;
    }
  }
}
