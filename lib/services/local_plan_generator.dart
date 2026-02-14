import 'dart:math';

import '../models/user_profile.dart';
import 'macro_calculator.dart';
import 'meal_database.dart';
import 'tolerance_validator.dart';

/// Plan üretim sonucu.
class PlanGenerationResult {
  final bool success;
  final GeneratedDayPlan? plan;
  final ToleranceResult? toleranceResult;
  final String? errorMessage;
  final int attempts;
  final List<AdjusterApplied> adjustments;

  const PlanGenerationResult({
    required this.success,
    this.plan,
    this.toleranceResult,
    this.errorMessage,
    this.attempts = 1,
    this.adjustments = const [],
  });
}

/// Üretilen günlük plan.
class GeneratedDayPlan {
  final String date;
  final List<GeneratedMealSlot> slots;
  final double totalKcal;
  final double totalProtein;
  final double totalCarb;
  final double totalFat;
  final ToleranceResult toleranceResult;

  const GeneratedDayPlan({
    required this.date,
    required this.slots,
    required this.totalKcal,
    required this.totalProtein,
    required this.totalCarb,
    required this.totalFat,
    required this.toleranceResult,
  });
}

/// Bir öğün slot'u — ana yemek + 2 alternatif.
class GeneratedMealSlot {
  final String mealType;
  final String mealTypeDisplay;
  final SelectedMeal primary;
  final SelectedMeal alt1;
  final SelectedMeal alt2;

  const GeneratedMealSlot({
    required this.mealType,
    required this.mealTypeDisplay,
    required this.primary,
    required this.alt1,
    required this.alt2,
  });
}

/// Seçilen yemek (gramaj ayarlanmış).
class SelectedMeal {
  final LocalMeal meal;
  final double portionG;
  final double kcal;
  final double protein;
  final double carb;
  final double fat;

  const SelectedMeal({
    required this.meal,
    required this.portionG,
    required this.kcal,
    required this.protein,
    required this.carb,
    required this.fat,
  });
}

/// Adjuster uygulandıysa kaydı.
class AdjusterApplied {
  final String adjusterName;
  final double addedG;
  final double addedKcal;
  final double addedProtein;
  final double addedCarb;
  final double addedFat;

  const AdjusterApplied({
    required this.adjusterName,
    required this.addedG,
    required this.addedKcal,
    required this.addedProtein,
    required this.addedCarb,
    required this.addedFat,
  });
}

/// meal_type display adları
const Map<String, String> mealTypeDisplayNames = {
  'kahvalti': 'Kahvaltı',
  'ara_ogun_1': 'Ara Öğün 1',
  'ogle': 'Öğle Yemeği',
  'ara_ogun_2': 'Ara Öğün 2',
  'aksam': 'Akşam Yemeği',
  'gece_atistirmasi': 'Gece Atıştırması',
};

/// Öğün başına kalori dağılım oranları.
const Map<String, Map<String, double>> slotKcalRatios = {
  'cut': {
    'kahvalti': 0.25,
    'ara_ogun_1': 0.10,
    'ogle': 0.35,
    'aksam': 0.30,
  },
  'maintain': {
    'kahvalti': 0.25,
    'ara_ogun_1': 0.10,
    'ogle': 0.35,
    'aksam': 0.30,
  },
  'bulk': {
    'kahvalti': 0.20,
    'ara_ogun_1': 0.10,
    'ogle': 0.25,
    'ara_ogun_2': 0.10,
    'aksam': 0.25,
    'gece_atistirmasi': 0.10,
  },
};

/// Lokal plan üretim motoru — Macro-Aware Greedy Selection.
///
/// Strateji:
/// 1. Her slot için hedef kcal + P/C/F hesapla (slot ratio × toplam hedef).
/// 2. Yemek havuzundan her yemeği slot hedefine scale et.
/// 3. Scale edilmiş makroları slot hedefiyle karşılaştır (L2 mesafe).
/// 4. En iyi 3 yemeği seç (primary + 2 alt).
/// 5. Kalan slot'larda kümülatif açığa göre yemek seç (greedy).
/// 6. Sonuçta tolerans kontrol et.
/// 7. Geçmezse adjuster uygula, hâlâ geçmezse yeniden dene.
class LocalPlanGenerator {
  final MacroCalculator _calculator;
  final MealDatabase _database;
  final ToleranceValidator _validator;
  final Random _random;

  LocalPlanGenerator({
    MacroCalculator? calculator,
    MealDatabase? database,
    ToleranceValidator? validator,
    Random? random,
  })  : _calculator = calculator ?? const MacroCalculator(),
        _database = database ?? const MealDatabase(),
        _validator = validator ?? const ToleranceValidator(),
        _random = random ?? Random();

  factory LocalPlanGenerator.seeded(int seed) {
    return LocalPlanGenerator(random: Random(seed));
  }

  static const int maxAttempts = 30;

  /// Profil'e göre günlük plan üretir.
  PlanGenerationResult generateDayPlan({
    required UserProfile profile,
    required String date,
  }) {
    final targets = _calculator.calculate(profile);
    final goalTag = profile.goal.name;
    final activeSlots = profile.goal.activeMealTypes;
    final ratios = slotKcalRatios[goalTag]!;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      final slots = <GeneratedMealSlot>[];
      double runningKcal = 0;
      double runningProtein = 0;
      double runningCarb = 0;
      double runningFat = 0;
      final adjustments = <AdjusterApplied>[];

      for (int si = 0; si < activeSlots.length; si++) {
        final mealType = activeSlots[si];
        final slotRatio = ratios[mealType] ?? 0.15;

        // Bu slot'un ideal hedef makroları
        final slotTargetKcal = targets.targetKcal * slotRatio;
        final slotTargetP = targets.proteinG * slotRatio;
        final slotTargetC = targets.carbG * slotRatio;
        final slotTargetF = targets.fatG * slotRatio;

        // Kalan slot'lar için kümülatif açık hesabı
        // Son slot'larda açığı kapatmaya çalış
        final remainingSlots = activeSlots.length - si;
        final remainingKcal = targets.targetKcal - runningKcal;
        final remainingP = targets.proteinG - runningProtein;
        final remainingC = targets.carbG - runningCarb;
        final remainingF = targets.fatG - runningFat;

        // Kalan slot'lara eşit dağılacak ideal hedef
        final adjustedTargetKcal =
            si == 0 ? slotTargetKcal : remainingKcal / remainingSlots;
        final adjustedTargetP =
            si == 0 ? slotTargetP : remainingP / remainingSlots;
        final adjustedTargetC =
            si == 0 ? slotTargetC : remainingC / remainingSlots;
        final adjustedTargetF =
            si == 0 ? slotTargetF : remainingF / remainingSlots;

        final candidates =
            _database.getMealsFor(mealType: mealType, goalTag: goalTag);

        if (candidates.length < 3) {
          return PlanGenerationResult(
            success: false,
            errorMessage:
                '$mealType slotu icin yeterli yemek yok '
                '(${candidates.length} yemek var, 3 gerekli).',
            attempts: attempt,
          );
        }

        // Her yemeği hedef kaloriye scale edip macro uzaklık hesapla
        final scored = <_ScoredMeal>[];
        for (final meal in candidates) {
          final scaled = _adjustPortion(meal, adjustedTargetKcal);
          // Normalize edilmiş L2 mesafe (P, C, F ayrı ağırlıklandırılır)
          // Protein'e 2x ağırlık (en kritik makro)
          final pErr = adjustedTargetP > 0
              ? ((scaled.protein - adjustedTargetP) / adjustedTargetP)
              : 0.0;
          final cErr = adjustedTargetC > 0
              ? ((scaled.carb - adjustedTargetC) / adjustedTargetC)
              : 0.0;
          final fErr = adjustedTargetF > 0
              ? ((scaled.fat - adjustedTargetF) / adjustedTargetF)
              : 0.0;

          final distance = (pErr * pErr * 4) + (cErr * cErr) + (fErr * fErr);
          scored.add(_ScoredMeal(meal: scaled, score: distance));
        }

        // En düşük mesafe = en iyi uyum
        scored.sort((a, b) => a.score.compareTo(b.score));

        // Rastgelelik ekle — top 5'ten 3'ünü seç
        final topN = scored.take(min(scored.length, 5 + attempt)).toList();
        topN.shuffle(_random);

        final primary = topN[0].meal;
        final alt1 = topN[1].meal;
        final alt2 = topN[2].meal;

        runningKcal += primary.kcal;
        runningProtein += primary.protein;
        runningCarb += primary.carb;
        runningFat += primary.fat;

        slots.add(GeneratedMealSlot(
          mealType: mealType,
          mealTypeDisplay: mealTypeDisplayNames[mealType] ?? mealType,
          primary: primary,
          alt1: alt1,
          alt2: alt2,
        ));
      }

      // Tolerans kontrolü
      var toleranceResult = _validator.validate(
        actualKcal: runningKcal,
        actualProtein: runningProtein,
        actualCarb: runningCarb,
        actualFat: runningFat,
        targets: targets,
      );

      // Tolerans dışıysa adjuster uygula
      if (!toleranceResult.passed) {
        final adjResults = _applyMultipleAdjusters(
          totalKcal: runningKcal,
          totalProtein: runningProtein,
          totalCarb: runningCarb,
          totalFat: runningFat,
          targets: targets,
        );

        for (final adj in adjResults) {
          runningKcal += adj.addedKcal;
          runningProtein += adj.addedProtein;
          runningCarb += adj.addedCarb;
          runningFat += adj.addedFat;
          adjustments.add(adj);
        }

        toleranceResult = _validator.validate(
          actualKcal: runningKcal,
          actualProtein: runningProtein,
          actualCarb: runningCarb,
          actualFat: runningFat,
          targets: targets,
        );
      }

      if (toleranceResult.passed) {
        return PlanGenerationResult(
          success: true,
          plan: GeneratedDayPlan(
            date: date,
            slots: slots,
            totalKcal: runningKcal,
            totalProtein: runningProtein,
            totalCarb: runningCarb,
            totalFat: runningFat,
            toleranceResult: toleranceResult,
          ),
          toleranceResult: toleranceResult,
          attempts: attempt,
          adjustments: adjustments,
        );
      }
    }

    return PlanGenerationResult(
      success: false,
      errorMessage:
          '$maxAttempts deneme sonunda tolerans saglanamadi. '
          'Hedef: ${targets.targetKcal.round()} kcal, '
          'P:${targets.proteinG.round()}g, '
          'C:${targets.carbG.round()}g, '
          'F:${targets.fatG.round()}g.',
      attempts: maxAttempts,
    );
  }

  /// Haftalık plan üretir (7 gün).
  List<PlanGenerationResult> generateWeekPlan({
    required UserProfile profile,
    required String weekStart,
  }) {
    final results = <PlanGenerationResult>[];
    final startDate = DateTime.parse(weekStart);

    for (int i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      results.add(generateDayPlan(profile: profile, date: dateStr));
    }

    return results;
  }

  /// Swap: Mevcut slot'taki yemeği alternatifle değiştir.
  SwapResult trySwap({
    required GeneratedDayPlan currentPlan,
    required int slotIndex,
    required SelectedMeal newMeal,
    required MacroTargets targets,
  }) {
    if (slotIndex < 0 || slotIndex >= currentPlan.slots.length) {
      return const SwapResult(success: false, reason: 'Gecersiz slot index.');
    }

    final oldMeal = currentPlan.slots[slotIndex].primary;
    final newTotalKcal = currentPlan.totalKcal - oldMeal.kcal + newMeal.kcal;
    final newTotalProtein =
        currentPlan.totalProtein - oldMeal.protein + newMeal.protein;
    final newTotalCarb = currentPlan.totalCarb - oldMeal.carb + newMeal.carb;
    final newTotalFat = currentPlan.totalFat - oldMeal.fat + newMeal.fat;

    final toleranceResult = _validator.validate(
      actualKcal: newTotalKcal,
      actualProtein: newTotalProtein,
      actualCarb: newTotalCarb,
      actualFat: newTotalFat,
      targets: targets,
    );

    if (!toleranceResult.passed) {
      return SwapResult(
        success: false,
        reason:
            'Bu swap toleransi bozuyor. '
            'Sapma: kcal ${toleranceResult.kcalDeviation.toStringAsFixed(1)}%',
        toleranceResult: toleranceResult,
      );
    }

    return SwapResult(success: true, toleranceResult: toleranceResult);
  }

  /// Gramaj ayarla — hedef kaloriye ulaşmak için porsiyon gramını scale eder.
  SelectedMeal _adjustPortion(LocalMeal meal, double targetKcal) {
    final defaultKcal = meal.kcalForPortion(meal.defaultPortionG);
    final ratio = defaultKcal > 0 ? targetKcal / defaultKcal : 1.0;
    final newPortionG = (meal.defaultPortionG * ratio).clamp(20.0, 800.0);

    return SelectedMeal(
      meal: meal,
      portionG: newPortionG,
      kcal: meal.kcalForPortion(newPortionG),
      protein: meal.proteinForPortion(newPortionG),
      carb: meal.carbForPortion(newPortionG),
      fat: meal.fatForPortion(newPortionG),
    );
  }

  /// Birden fazla adjuster uygulayarak makro açıklarını kapat.
  List<AdjusterApplied> _applyMultipleAdjusters({
    required double totalKcal,
    required double totalProtein,
    required double totalCarb,
    required double totalFat,
    required MacroTargets targets,
  }) {
    final results = <AdjusterApplied>[];
    var curKcal = totalKcal;
    var curProtein = totalProtein;
    var curCarb = totalCarb;
    var curFat = totalFat;

    // 5 pass — her makro için ayrı adjuster
    for (int pass = 0; pass < 5; pass++) {
      final pDiff = targets.proteinG - curProtein;
      final cDiff = targets.carbG - curCarb;
      final fDiff = targets.fatG - curFat;

      final pPct =
          targets.proteinG > 0 ? (pDiff / targets.proteinG) * 100 : 0.0;
      final cPct = targets.carbG > 0 ? (cDiff / targets.carbG) * 100 : 0.0;
      final fPct = targets.fatG > 0 ? (fDiff / targets.fatG) * 100 : 0.0;

      // Tolerans kontrolü — hepsi ±%15 içindeyse dur
      if (pPct.abs() <= tolerancePercent &&
          cPct.abs() <= tolerancePercent &&
          fPct.abs() <= tolerancePercent) {
        // kcal de kontrol et
        final kcalPct = targets.targetKcal > 0
            ? ((curKcal - targets.targetKcal) / targets.targetKcal) * 100
            : 0.0;
        if (kcalPct.abs() <= tolerancePercent) break;
      }

      // En büyük pozitif açığı (eksik olan makro) bul
      String? adjustType;
      double maxPct = 3; // %3'ten az sapma önemsiz

      if (pDiff > 0 && pPct.abs() > maxPct) {
        maxPct = pPct.abs();
        adjustType = 'protein';
      }
      if (fDiff > 0 && fPct.abs() > maxPct) {
        maxPct = fPct.abs();
        adjustType = 'fat';
      }
      if (cDiff > 0 && cPct.abs() > maxPct) {
        maxPct = cPct.abs();
        adjustType = 'carb';
      }

      if (adjustType == null) break;

      final candidates = MealDatabase.adjusterItems
          .where((a) => a.adjustType == adjustType)
          .toList();

      if (candidates.isEmpty) continue;

      final adj = candidates.first;
      double neededG;

      switch (adjustType) {
        case 'protein':
          neededG = adj.proteinPer100g > 0
              ? (pDiff / (adj.proteinPer100g / 100))
              : 0;
        case 'fat':
          neededG =
              adj.fatPer100g > 0 ? (fDiff / (adj.fatPer100g / 100)) : 0;
        case 'carb':
          neededG =
              adj.carbPer100g > 0 ? (cDiff / (adj.carbPer100g / 100)) : 0;
        default:
          continue;
      }

      neededG = neededG.clamp(adj.minG, adj.maxG);
      if (neededG <= 0) continue;

      final addedKcal = adj.kcalPer100g * neededG / 100;
      final addedProtein = adj.proteinPer100g * neededG / 100;
      final addedCarb = adj.carbPer100g * neededG / 100;
      final addedFat = adj.fatPer100g * neededG / 100;

      curKcal += addedKcal;
      curProtein += addedProtein;
      curCarb += addedCarb;
      curFat += addedFat;

      results.add(AdjusterApplied(
        adjusterName: adj.ad,
        addedG: neededG,
        addedKcal: addedKcal,
        addedProtein: addedProtein,
        addedCarb: addedCarb,
        addedFat: addedFat,
      ));
    }

    return results;
  }
}

/// Swap sonucu.
class SwapResult {
  final bool success;
  final String? reason;
  final ToleranceResult? toleranceResult;
  final AdjusterApplied? adjustment;

  const SwapResult({
    required this.success,
    this.reason,
    this.toleranceResult,
    this.adjustment,
  });
}

/// Yemeğin makro mesafe puanı (dahili).
class _ScoredMeal {
  final SelectedMeal meal;
  final double score;

  const _ScoredMeal({required this.meal, required this.score});
}
