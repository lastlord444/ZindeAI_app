import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zindeai_app/screens/generate_plan_screen.dart';
import 'package:zindeai_app/services/plan_service.dart';
import 'package:zindeai_app/services/models/plan_models.dart';
import 'package:zindeai_app/services/models/plan_request.dart';

class FakePlanService implements PlanService {
  @override
  Future<Plan> generatePlan(GeneratePlanRequest request) async {
    return const Plan(
      planId: '1',
      weekStart: '2024-01-01',
      days: <DailyPlan>[],
    );
  }

  @override
  Future<Plan> getPlan(String planId) async {
    return Plan(
      planId: planId,
      weekStart: '2024-01-01',
      days: const <DailyPlan>[],
    );
  }

  @override
  Future<void> markMealConsumed(
      String planId, String mealId, bool isConsumed) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('Generate Plan UI smoke test', (WidgetTester tester) async {
    final fakeService = FakePlanService();
    await tester.pumpWidget(MaterialApp(
      home: GeneratePlanScreen(planService: fakeService),
    ));

    expect(find.text('ZindeAI Planlayıcı'), findsOneWidget);
  });
}
