import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:zindeai_app/services/api_client.dart';
import 'package:zindeai_app/services/plan_service.dart';
import 'package:zindeai_app/services/models/plan_models.dart';
import 'package:zindeai_app/services/models/plan_request.dart';

@GenerateMocks([ApiClient])
import 'plan_service_test.mocks.dart';

void main() {
  late MockApiClient mockApiClient;
  late PlanService planService;

  setUp(() {
    mockApiClient = MockApiClient();
    planService = PlanService(apiClient: mockApiClient);
  });

  group('PlanService Tests', () {
    const tPlanRequest = GeneratePlanRequest(
      userId: 'test-user',
      weekStart: '2024-01-01',
      goalTag: 'cut',
      budgetMode: 'medium',
    );

    final tPlanJson = {
      'plan_id': '123',
      'week_start': '2024-01-01',
      'days': [],
    };

    test('generatePlan returns Plan from ApiClient', () async {
      // Arrange
      when(mockApiClient.post('/plans/generate', data: tPlanRequest.toJson()))
          .thenAnswer((_) async => tPlanJson);

      // Act
      final result = await planService.generatePlan(tPlanRequest);

      // Assert
      expect(result, isA<Plan>());
      expect(result.planId, '123');
      verify(
          mockApiClient.post('/plans/generate', data: tPlanRequest.toJson()));
    });
  });
}
