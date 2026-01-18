import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:zindeai_app/screens/generate_plan_screen.dart';
import 'package:zindeai_app/services/plan_service.dart';
import 'package:zindeai_app/services/models/plan_models.dart';

@GenerateMocks([PlanService])
import 'widget_test.mocks.dart';

void main() {
  late MockPlanService mockPlanService;

  setUp(() {
    mockPlanService = MockPlanService();
  });

  testWidgets('Generate Plan UI smoke test', (WidgetTester tester) async {
    // Stub the service call to return a future that never completes immediately 
    // (to show loading) or return a mock plan.
    // For "loading state" check, using a Completer is good, or just a delayed Future.
    
    when(mockPlanService.generatePlan(any)).thenAnswer((_) async {
       await Future.delayed(const Duration(seconds: 1));
       return Plan(id: '1', title: 'Test', createdAt: DateTime.now(), days: const []);
    });

    // Actually, let's fix the mock return value to be valid if needed.
    // But for UI smoke test of loading state, simply returning a Future is enough.
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(
      home: GeneratePlanScreen(planService: mockPlanService),
    ));

    // Verify initial state
    expect(find.text('ZindeAI Planlayıcı'), findsOneWidget);
    expect(find.text('Plan Oluştur'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);

    // Tap the button
    await tester.tap(find.byType(ElevatedButton));
    
    // Important: pump() without duration processes simple microtasks. 
    // Since our future is delayed, it should be pending, so loading state should appear.
    await tester.pump();

    // Verify loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    // To avoid pending timers exception at end of test:
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });
}
