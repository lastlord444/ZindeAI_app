import '../models/user_profile.dart';

/// Makro hedef sonuçları.
class MacroTargets {
  final double bmr;
  final double tdee;
  final double targetKcal;
  final double proteinG;
  final double carbG;
  final double fatG;

  const MacroTargets({
    required this.bmr,
    required this.tdee,
    required this.targetKcal,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
  });

  @override
  String toString() =>
      'MacroTargets(kcal: ${targetKcal.round()}, P: ${proteinG.round()}g, '
      'C: ${carbG.round()}g, F: ${fatG.round()}g, BMR: ${bmr.round()}, TDEE: ${tdee.round()})';
}

/// Mifflin-St Jeor formülü ile BMR, TDEE ve makro hedeflerini hesaplar.
///
/// BMR formülleri:
///   Erkek:  10 × kilo(kg) + 6.25 × boy(cm) − 5 × yaş − 161 + 166
///           = 10 × kilo + 6.25 × boy − 5 × yaş + 5
///   Kadın:  10 × kilo(kg) + 6.25 × boy(cm) − 5 × yaş − 161
///
/// TDEE = BMR × activity_factor
///
/// Hedef kalori:
///   cut:      TDEE × 0.80 (-%20 açık)
///   maintain: TDEE × 1.00
///   bulk:     TDEE × 1.15 (+%15 fazla)
///
/// Makro dağılımı (gram cinsinden):
///   Protein: weightKg × proteinMultiplier (goal'e göre 1.6-2.2 g/kg)
///   Yağ:     targetKcal × fatRatio / 9
///   Karbonhidrat: kalan kalori / 4
class MacroCalculator {
  const MacroCalculator();

  /// Profil'den makro hedeflerini hesaplar.
  MacroTargets calculate(UserProfile profile) {
    final bmr = _calculateBMR(profile);
    final tdee = bmr * profile.activityLevel.multiplier;
    final targetKcal = _applyGoalModifier(tdee, profile.goal);

    final proteinG = _calculateProtein(profile);
    final fatG = _calculateFat(targetKcal, profile.goal);
    // Kalan kaloriler karbonhidrata gider
    final remainingKcal = targetKcal - (proteinG * 4) - (fatG * 9);
    final carbG = remainingKcal > 0 ? remainingKcal / 4 : 0.0;

    return MacroTargets(
      bmr: bmr,
      tdee: tdee,
      targetKcal: targetKcal,
      proteinG: proteinG,
      carbG: carbG,
      fatG: fatG,
    );
  }

  /// Mifflin-St Jeor BMR hesabı.
  double _calculateBMR(UserProfile profile) {
    // Erkek:  10 × kilo + 6.25 × boy − 5 × yaş + 5
    // Kadın:  10 × kilo + 6.25 × boy − 5 × yaş − 161
    final base =
        10.0 * profile.weightKg + 6.25 * profile.heightCm - 5.0 * profile.age;

    switch (profile.gender) {
      case Gender.male:
        return base + 5;
      case Gender.female:
        return base - 161;
    }
  }

  /// Hedefe göre kalori çarpanı.
  double _applyGoalModifier(double tdee, GoalType goal) {
    switch (goal) {
      case GoalType.cut:
        return tdee * 0.80; // -%20
      case GoalType.maintain:
        return tdee * 1.00;
      case GoalType.bulk:
        return tdee * 1.15; // +%15
    }
  }

  /// Protein hesabı (g/kg cinsinden).
  /// Cut:      2.2 g/kg (kas kaybını önlemek için yüksek)
  /// Maintain: 1.8 g/kg
  /// Bulk:     2.0 g/kg
  double _calculateProtein(UserProfile profile) {
    final double gPerKg;
    switch (profile.goal) {
      case GoalType.cut:
        gPerKg = 2.2;
      case GoalType.maintain:
        gPerKg = 1.8;
      case GoalType.bulk:
        gPerKg = 2.0;
    }
    return profile.weightKg * gPerKg;
  }

  /// Yağ hesabı — toplam kalorinin %25'i (cut'ta %22, bulk'ta %28).
  double _calculateFat(double targetKcal, GoalType goal) {
    final double fatRatio;
    switch (goal) {
      case GoalType.cut:
        fatRatio = 0.22;
      case GoalType.maintain:
        fatRatio = 0.25;
      case GoalType.bulk:
        fatRatio = 0.28;
    }
    return (targetKcal * fatRatio) / 9;
  }
}
