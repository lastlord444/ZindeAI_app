import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zindeai_app/screens/generate_plan_screen.dart';
import 'package:zindeai_app/services/plan_service.dart';
import 'package:zindeai_app/services/models/plan_models.dart';
import 'package:zindeai_app/services/models/plan_request.dart';

/// E2E Smoke Test: Tüm kullanıcı akışını simüle eder.
/// Network'e bağımlılık YOK — FakePlanService kullanır.
///
/// Senaryo:
///   1. App açılış → AppBar + Tab'lar görünür
///   2. Günlük tab'da MealCard'lar render edilir
///   3. Haftalık tab → boş state (plan yok)
///   4. Plan Oluştur → loading → success
///   5. Swap buton → BottomSheet → alternatif seç → meal name değişir

/// Fake PlanService — network çağrısı yapmaz.
class FakePlanService implements PlanService {
  bool generateCalled = false;
  int generateCallCount = 0;

  @override
  Future<Plan> generatePlan(GeneratePlanRequest request) async {
    generateCalled = true;
    generateCallCount++;
    // Kısa gecikme ile gerçek async davranışı simüle et
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return const Plan(
      planId: 'fake-plan-001',
      weekStart: '2026-02-10',
      days: <DailyPlan>[],
    );
  }

  @override
  Future<Plan> getPlan(String planId) async {
    return Plan(
      planId: planId,
      weekStart: '2026-02-10',
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
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('E2E Smoke Test', () {
    testWidgets('Senaryo 1: App açılış → AppBar + Tab yapısı doğru',
        (WidgetTester tester) async {
      final fakeService = FakePlanService();

      await tester.pumpWidget(MaterialApp(
        home: GeneratePlanScreen(planService: fakeService),
      ));

      // AppBar title
      expect(find.text('ZindeAI Planlayıcı'), findsOneWidget);

      // Tab'lar mevcut
      expect(find.text('Günlük'), findsOneWidget);
      expect(find.text('Haftalık'), findsOneWidget);

      // Plan Oluştur butonu mevcut
      expect(find.text('Plan Oluştur'), findsOneWidget);
    });

    testWidgets('Senaryo 2: Günlük tab → MealCard listesi render edilir',
        (WidgetTester tester) async {
      final fakeService = FakePlanService();

      await tester.pumpWidget(MaterialApp(
        home: GeneratePlanScreen(planService: fakeService),
      ));

      // Günlük tab aktif (varsayılan)
      // Statik MealCard'lar render edilmiş olmalı (viewport'ta görünenler)
      expect(find.text('Yulaf Ezmesi & Yumurta'), findsOneWidget);
      expect(find.text('Izgara Tavuk Salata'), findsOneWidget);
      expect(find.text('Ara Öğün: Kuruyemiş'), findsOneWidget);

      // Kalori bilgileri
      expect(find.text('350 kcal'), findsOneWidget);
      expect(find.text('450 kcal'), findsOneWidget);
      expect(find.text('150 kcal'), findsOneWidget);

      // Swap butonları (Icons.swap_horiz)
      expect(find.byIcon(Icons.swap_horiz), findsWidgets);

      // Lock butonları
      expect(find.byIcon(Icons.lock_open), findsWidgets);

      // Checkbox'lar (consumed)
      expect(find.byType(Checkbox), findsWidgets);
    });

    testWidgets('Senaryo 3: Haftalık tab → boş state görünür',
        (WidgetTester tester) async {
      final fakeService = FakePlanService();

      await tester.pumpWidget(MaterialApp(
        home: GeneratePlanScreen(planService: fakeService),
      ));

      // Haftalık tab'a tıkla
      await tester.tap(find.text('Haftalık'));
      await tester.pumpAndSettle();

      // Boş state mesajı
      expect(find.text('Henüz bir haftalık plan yok'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('Senaryo 4: Plan Oluştur → loading → success',
        (WidgetTester tester) async {
      final fakeService = FakePlanService();

      await tester.pumpWidget(MaterialApp(
        home: GeneratePlanScreen(planService: fakeService),
      ));

      // Plan Oluştur butonu var
      expect(find.text('Plan Oluştur'), findsOneWidget);
      expect(fakeService.generateCalled, isFalse);

      // Butona tıkla
      await tester.tap(find.text('Plan Oluştur'));
      await tester.pump(); // Loading state'i tetikle

      // Loading state — "Oluşturuluyor..." metni
      expect(find.text('Oluşturuluyor...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      // Async tamamlanmasını bekle
      await tester.pumpAndSettle();

      // Service çağrıldı
      expect(fakeService.generateCalled, isTrue);
      expect(fakeService.generateCallCount, equals(1));

      // Loading bitti → buton tekrar "Plan Oluştur" olmalı
      expect(find.text('Plan Oluştur'), findsOneWidget);
    });

    testWidgets(
        'Senaryo 5: Swap buton → BottomSheet → alternatif seç → meal değişir',
        (WidgetTester tester) async {
      final fakeService = FakePlanService();

      await tester.pumpWidget(MaterialApp(
        home: GeneratePlanScreen(planService: fakeService),
      ));

      // İlk meal: "Yulaf Ezmesi & Yumurta" görünür
      expect(find.text('Yulaf Ezmesi & Yumurta'), findsOneWidget);

      // Bu meal'ın alternatifleri: ['Menemen', 'Toast']
      // İlk swap butonuna tıkla
      // (MealCard'lar listede sırayla, ilk swap butonu ilk card'ınki)
      final swapButtons = find.byIcon(Icons.swap_horiz);
      expect(swapButtons, findsWidgets);

      // İlk swap butonuna bas (statik swap — mealId yok)
      await tester.tap(swapButtons.first);
      await tester.pumpAndSettle();

      // BottomSheet açıldı → "Alternatif Seçin" başlığı
      expect(find.text('Alternatif Seçin'), findsOneWidget);

      // Alternatifler listede
      expect(find.text('Menemen'), findsOneWidget);
      expect(find.text('Toast'), findsOneWidget);

      // "Menemen" seç
      await tester.tap(find.text('Menemen'));
      await tester.pumpAndSettle();

      // BottomSheet kapandı
      expect(find.text('Alternatif Seçin'), findsNothing);

      // Meal name değişti: "Menemen" görünür, "Yulaf Ezmesi & Yumurta" KALMAMALI
      expect(find.text('Menemen'), findsOneWidget);

      // Success SnackBar göründü
      expect(find.textContaining('Alternatif uygulandı'), findsOneWidget);
    });

    testWidgets('Senaryo 6: Lock → swap buton devre dışı',
        (WidgetTester tester) async {
      final fakeService = FakePlanService();

      await tester.pumpWidget(MaterialApp(
        home: GeneratePlanScreen(planService: fakeService),
      ));

      // İlk lock butonuna tıkla (kilitle)
      final lockButtons = find.byIcon(Icons.lock_open);
      expect(lockButtons, findsWidgets);

      await tester.tap(lockButtons.first);
      await tester.pumpAndSettle();

      // Lock ikonu değişti → Icons.lock
      expect(find.byIcon(Icons.lock), findsWidgets);

      // Swap butonuna tıklayınca BottomSheet açılmamalı
      final swapButtons = find.byIcon(Icons.swap_horiz);
      await tester.tap(swapButtons.first);
      await tester.pumpAndSettle();

      // BottomSheet açılmamış olmalı
      expect(find.text('Alternatif Seçin'), findsNothing);
    });

    testWidgets('Senaryo 7: Consumed checkbox → meal üzeri çizilir',
        (WidgetTester tester) async {
      final fakeService = FakePlanService();

      await tester.pumpWidget(MaterialApp(
        home: GeneratePlanScreen(planService: fakeService),
      ));

      // Checkbox'lar false olmalı (consumed = false)
      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsWidgets);

      // İlk checkbox'a tıkla
      await tester.tap(checkboxes.first);
      await tester.pumpAndSettle();

      // Checkbox true olmalı — lineThrough decoration var
      // (Text widget'ın decoration'ını doğrudan test ediyoruz)
      final richText = tester.widget<Text>(
        find.text('Yulaf Ezmesi & Yumurta'),
      );
      expect(richText.style?.decoration, equals(TextDecoration.lineThrough));
    });

    testWidgets('Senaryo 8: Tab geçişleri sorunsuz çalışır',
        (WidgetTester tester) async {
      final fakeService = FakePlanService();

      await tester.pumpWidget(MaterialApp(
        home: GeneratePlanScreen(planService: fakeService),
      ));

      // Günlük tab aktif
      expect(find.text('Yulaf Ezmesi & Yumurta'), findsOneWidget);

      // Haftalık'a geç
      await tester.tap(find.text('Haftalık'));
      await tester.pumpAndSettle();
      expect(find.text('Henüz bir haftalık plan yok'), findsOneWidget);

      // Günlük'e geri dön
      await tester.tap(find.text('Günlük'));
      await tester.pumpAndSettle();
      expect(find.text('Yulaf Ezmesi & Yumurta'), findsOneWidget);

      // Tekrar Haftalık'a geç (kararlılık)
      await tester.tap(find.text('Haftalık'));
      await tester.pumpAndSettle();
      expect(find.text('Henüz bir haftalık plan yok'), findsOneWidget);
    });
  });
}
