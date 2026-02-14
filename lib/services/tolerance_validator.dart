import 'macro_calculator.dart';

/// Tolerans kontrol sonucu.
class ToleranceResult {
  final bool passed;
  final double kcalDeviation; // yüzde sapma
  final double proteinDeviation;
  final double carbDeviation;
  final double fatDeviation;
  final double actualKcal;
  final double actualProtein;
  final double actualCarb;
  final double actualFat;
  final MacroTargets targets;

  const ToleranceResult({
    required this.passed,
    required this.kcalDeviation,
    required this.proteinDeviation,
    required this.carbDeviation,
    required this.fatDeviation,
    required this.actualKcal,
    required this.actualProtein,
    required this.actualCarb,
    required this.actualFat,
    required this.targets,
  });

  /// Hangi makrolar sınır dışı?
  List<String> get failedMacros {
    final failed = <String>[];
    if (kcalDeviation.abs() > tolerancePercent) failed.add('kcal');
    if (proteinDeviation.abs() > tolerancePercent) failed.add('protein');
    if (carbDeviation.abs() > tolerancePercent) failed.add('karb');
    if (fatDeviation.abs() > tolerancePercent) failed.add('yağ');
    return failed;
  }

  @override
  String toString() {
    final status = passed ? 'PASS' : 'FAIL';
    return 'Tolerans[$status] kcal: ${kcalDeviation.toStringAsFixed(1)}%, '
        'P: ${proteinDeviation.toStringAsFixed(1)}%, '
        'C: ${carbDeviation.toStringAsFixed(1)}%, '
        'F: ${fatDeviation.toStringAsFixed(1)}%';
  }
}

/// Sabit tolerans yüzdesi — ±%15
const double tolerancePercent = 15.0;

/// Hard gate tolerans validatörü.
///
/// Plan total kcal + P/C/F hedefleri ±%15 dışına çıkarsa plan INVALID.
/// INVALID plan UI'ya basılmayacak. Sistem yeniden deneyecek.
class ToleranceValidator {
  const ToleranceValidator();

  /// Plan makrolarını hedeflerle karşılaştırır.
  ///
  /// [actualKcal], [actualProtein], [actualCarb], [actualFat]: planın toplam günlük makroları.
  /// [targets]: hedef makrolar (MacroTargets).
  ///
  /// Returns: ToleranceResult (passed: true ise plan geçerli)
  ToleranceResult validate({
    required double actualKcal,
    required double actualProtein,
    required double actualCarb,
    required double actualFat,
    required MacroTargets targets,
  }) {
    final kcalDev = _deviationPercent(actualKcal, targets.targetKcal);
    final pDev = _deviationPercent(actualProtein, targets.proteinG);
    final cDev = _deviationPercent(actualCarb, targets.carbG);
    final fDev = _deviationPercent(actualFat, targets.fatG);

    final passed = kcalDev.abs() <= tolerancePercent &&
        pDev.abs() <= tolerancePercent &&
        cDev.abs() <= tolerancePercent &&
        fDev.abs() <= tolerancePercent;

    return ToleranceResult(
      passed: passed,
      kcalDeviation: kcalDev,
      proteinDeviation: pDev,
      carbDeviation: cDev,
      fatDeviation: fDev,
      actualKcal: actualKcal,
      actualProtein: actualProtein,
      actualCarb: actualCarb,
      actualFat: actualFat,
      targets: targets,
    );
  }

  /// Swap sonrası toleransı kontrol eder.
  ///
  /// Eski yemeği çıkarıp yeni yemeği koyduktan sonra
  /// planın hâlâ tolerans içinde kalıp kalmadığını kontrol eder.
  ToleranceResult validateSwap({
    required double currentTotalKcal,
    required double currentTotalProtein,
    required double currentTotalCarb,
    required double currentTotalFat,
    required double removedKcal,
    required double removedProtein,
    required double removedCarb,
    required double removedFat,
    required double addedKcal,
    required double addedProtein,
    required double addedCarb,
    required double addedFat,
    required MacroTargets targets,
  }) {
    final newKcal = currentTotalKcal - removedKcal + addedKcal;
    final newProtein = currentTotalProtein - removedProtein + addedProtein;
    final newCarb = currentTotalCarb - removedCarb + addedCarb;
    final newFat = currentTotalFat - removedFat + addedFat;

    return validate(
      actualKcal: newKcal,
      actualProtein: newProtein,
      actualCarb: newCarb,
      actualFat: newFat,
      targets: targets,
    );
  }

  /// Yüzde sapma hesabı.
  /// hedef 0 ise sapma 0 kabul edilir (bölme hatası önlenir).
  double _deviationPercent(double actual, double target) {
    if (target == 0) return 0;
    return ((actual - target) / target) * 100;
  }
}
