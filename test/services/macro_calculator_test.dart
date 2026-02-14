import 'package:flutter_test/flutter_test.dart';
import 'package:zindeai_app/models/user_profile.dart';
import 'package:zindeai_app/services/macro_calculator.dart';

void main() {
  const calculator = MacroCalculator();

  group('Mifflin-St Jeor BMR Hesaplama', () {
    test('Erkek BMR dogru hesaplanmali', () {
      // BMR = 10*80 + 6.25*180 - 5*25 + 5
      //     = 800 + 1125 - 125 + 5 = 1805
      const profile = UserProfile(
        userId: 'test', age: 25, heightCm: 180, weightKg: 80,
        gender: Gender.male, activityLevel: ActivityLevel.moderate,
        goal: GoalType.cut, experience: ExperienceLevel.intermediate,
      );
      final result = calculator.calculate(profile);
      expect(result.bmr, closeTo(1805, 0.5));
    });

    test('Kadin BMR dogru hesaplanmali', () {
      // BMR = 10*60 + 6.25*165 - 5*30 - 161
      //     = 600 + 1031.25 - 150 - 161 = 1320.25
      const profile = UserProfile(
        userId: 'test', age: 30, heightCm: 165, weightKg: 60,
        gender: Gender.female, activityLevel: ActivityLevel.moderate,
        goal: GoalType.maintain, experience: ExperienceLevel.beginner,
      );
      final result = calculator.calculate(profile);
      expect(result.bmr, closeTo(1320.25, 0.5));
    });
  });

  group('TDEE Hesaplama', () {
    test('Sedentary TDEE = BMR * 1.2', () {
      const profile = UserProfile(
        userId: 'test', age: 25, heightCm: 180, weightKg: 80,
        gender: Gender.male, activityLevel: ActivityLevel.sedentary,
        goal: GoalType.maintain, experience: ExperienceLevel.intermediate,
      );
      final result = calculator.calculate(profile);
      expect(result.tdee, closeTo(result.bmr * 1.2, 0.5));
    });

    test('Active TDEE = BMR * 1.725', () {
      const profile = UserProfile(
        userId: 'test', age: 25, heightCm: 180, weightKg: 80,
        gender: Gender.male, activityLevel: ActivityLevel.active,
        goal: GoalType.maintain, experience: ExperienceLevel.intermediate,
      );
      final result = calculator.calculate(profile);
      expect(result.tdee, closeTo(result.bmr * 1.725, 0.5));
    });
  });

  group('Goal Modifier', () {
    test('Cut: targetKcal = TDEE * 0.80', () {
      const profile = UserProfile(
        userId: 'test', age: 25, heightCm: 175, weightKg: 70,
        gender: Gender.male, activityLevel: ActivityLevel.moderate,
        goal: GoalType.cut, experience: ExperienceLevel.intermediate,
      );
      final result = calculator.calculate(profile);
      expect(result.targetKcal, closeTo(result.tdee * 0.80, 0.5));
    });

    test('Maintain: targetKcal = TDEE * 1.00', () {
      const profile = UserProfile(
        userId: 'test', age: 25, heightCm: 175, weightKg: 70,
        gender: Gender.male, activityLevel: ActivityLevel.moderate,
        goal: GoalType.maintain, experience: ExperienceLevel.intermediate,
      );
      final result = calculator.calculate(profile);
      expect(result.targetKcal, closeTo(result.tdee, 0.5));
    });

    test('Bulk: targetKcal = TDEE * 1.15', () {
      const profile = UserProfile(
        userId: 'test', age: 25, heightCm: 175, weightKg: 70,
        gender: Gender.male, activityLevel: ActivityLevel.moderate,
        goal: GoalType.bulk, experience: ExperienceLevel.intermediate,
      );
      final result = calculator.calculate(profile);
      expect(result.targetKcal, closeTo(result.tdee * 1.15, 0.5));
    });
  });

  group('Makro Dagilimi', () {
    test('Cut: protein = 2.2 g/kg', () {
      const profile = UserProfile(
        userId: 'test', age: 25, heightCm: 175, weightKg: 80,
        gender: Gender.male, activityLevel: ActivityLevel.moderate,
        goal: GoalType.cut, experience: ExperienceLevel.intermediate,
      );
      final result = calculator.calculate(profile);
      expect(result.proteinG, closeTo(80 * 2.2, 0.5)); // 176g
    });

    test('Maintain: protein = 1.8 g/kg', () {
      const profile = UserProfile(
        userId: 'test', age: 25, heightCm: 175, weightKg: 80,
        gender: Gender.male, activityLevel: ActivityLevel.moderate,
        goal: GoalType.maintain, experience: ExperienceLevel.intermediate,
      );
      final result = calculator.calculate(profile);
      expect(result.proteinG, closeTo(80 * 1.8, 0.5)); // 144g
    });

    test('Bulk: protein = 2.0 g/kg', () {
      const profile = UserProfile(
        userId: 'test', age: 25, heightCm: 175, weightKg: 80,
        gender: Gender.male, activityLevel: ActivityLevel.moderate,
        goal: GoalType.bulk, experience: ExperienceLevel.intermediate,
      );
      final result = calculator.calculate(profile);
      expect(result.proteinG, closeTo(80 * 2.0, 0.5)); // 160g
    });

    test('P + C + F kalorisi targetKcal e esit olmali', () {
      const profile = UserProfile(
        userId: 'test', age: 25, heightCm: 175, weightKg: 70,
        gender: Gender.male, activityLevel: ActivityLevel.moderate,
        goal: GoalType.maintain, experience: ExperienceLevel.intermediate,
      );
      final result = calculator.calculate(profile);
      final fromMacros =
          result.proteinG * 4 + result.carbG * 4 + result.fatG * 9;
      expect(fromMacros, closeTo(result.targetKcal, 1.0));
    });

    test('Karb 0 dan buyuk olmali', () {
      const profile = UserProfile(
        userId: 'test', age: 25, heightCm: 175, weightKg: 70,
        gender: Gender.male, activityLevel: ActivityLevel.moderate,
        goal: GoalType.cut, experience: ExperienceLevel.intermediate,
      );
      final result = calculator.calculate(profile);
      expect(result.carbG, greaterThan(0));
    });
  });

  group('Video Parity — Referans Profiller', () {
    test('Erkek, 25 yas, 80kg, 180cm, moderate, cut', () {
      // BMR = 10*80 + 6.25*180 - 5*25 + 5 = 1805
      // TDEE = 1805 * 1.55 = 2797.75
      // Target = 2797.75 * 0.80 = 2238.2
      // Protein = 80 * 2.2 = 176g
      // Fat = 2238.2 * 0.22 / 9 = 54.7g
      // Carb = (2238.2 - 176*4 - 54.7*9) / 4 = (2238.2 - 704 - 492.3) / 4 = 260.5g
      const profile = UserProfile(
        userId: 'ref1', age: 25, heightCm: 180, weightKg: 80,
        gender: Gender.male, activityLevel: ActivityLevel.moderate,
        goal: GoalType.cut, experience: ExperienceLevel.intermediate,
      );
      final r = calculator.calculate(profile);
      expect(r.bmr, closeTo(1805, 1));
      expect(r.tdee, closeTo(2797.75, 1));
      expect(r.targetKcal, closeTo(2238.2, 1));
      expect(r.proteinG, closeTo(176, 1));
      expect(r.fatG, closeTo(54.7, 1));
      expect(r.carbG, closeTo(260.5, 1));
    });

    test('Kadin, 35 yas, 65kg, 165cm, light, maintain', () {
      // BMR = 10*65 + 6.25*165 - 5*35 - 161
      //     = 650 + 1031.25 - 175 - 161 = 1345.25
      // TDEE = 1345.25 * 1.375 = 1849.72
      // Target = 1849.72 * 1.0 = 1849.72
      // Protein = 65 * 1.8 = 117g
      // Fat = 1849.72 * 0.25 / 9 = 51.38g
      // Carb = (1849.72 - 117*4 - 51.38*9) / 4
      //      = (1849.72 - 468 - 462.42) / 4 = 229.83g
      const profile = UserProfile(
        userId: 'ref2', age: 35, heightCm: 165, weightKg: 65,
        gender: Gender.female, activityLevel: ActivityLevel.light,
        goal: GoalType.maintain, experience: ExperienceLevel.beginner,
      );
      final r = calculator.calculate(profile);
      expect(r.bmr, closeTo(1345.25, 1));
      expect(r.tdee, closeTo(1849.72, 1));
      expect(r.targetKcal, closeTo(1849.72, 1));
      expect(r.proteinG, closeTo(117, 1));
      expect(r.fatG, closeTo(51.38, 1));
      expect(r.carbG, closeTo(229.83, 1));
    });
  });
}
