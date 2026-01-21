import 'api_client.dart';
import 'models/plan_models.dart';
import 'models/plan_request.dart';

class PlanService {
  final ApiClient _apiClient;

  PlanService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Generates a new diet plan based on user preferences.
  Future<Plan> generatePlan(GeneratePlanRequest request) async {
    final responseData =
        await _apiClient.post('/plans/generate', data: request.toJson());
    return Plan.fromJson(responseData);
  }

  /// Retrieves an existing plan by ID.
  Future<Plan> getPlan(String planId) async {
    final responseData = await _apiClient.get('/plans/$planId');
    return Plan.fromJson(responseData);
  }

  /// Marks a specific meal as consumed.
  Future<void> markMealConsumed(
      String planId, String mealId, bool isConsumed) async {
    await _apiClient.put(
      '/plans/$planId/meals/$mealId/consume',
      data: {'isConsumed': isConsumed},
    );
  }
}
