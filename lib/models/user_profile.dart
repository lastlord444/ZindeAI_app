import 'package:equatable/equatable.dart';

/// Kullanıcı profili — makro hesaplama için gerekli tüm parametreler.
class UserProfile extends Equatable {
  final String userId;
  final int age;
  final int heightCm;
  final double weightKg;
  final Gender gender;
  final ActivityLevel activityLevel;
  final GoalType goal;
  final ExperienceLevel experience;

  const UserProfile({
    required this.userId,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.gender,
    required this.activityLevel,
    required this.goal,
    required this.experience,
  });

  UserProfile copyWith({
    String? userId,
    int? age,
    int? heightCm,
    double? weightKg,
    Gender? gender,
    ActivityLevel? activityLevel,
    GoalType? goal,
    ExperienceLevel? experience,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      experience: experience ?? this.experience,
    );
  }

  @override
  List<Object?> get props => [
        userId, age, heightCm, weightKg, gender, activityLevel, goal, experience,
      ];
}

enum Gender {
  male,
  female;

  String get displayName {
    switch (this) {
      case Gender.male:
        return 'Erkek';
      case Gender.female:
        return 'Kadın';
    }
  }
}

enum ActivityLevel {
  sedentary,
  light,
  moderate,
  active,
  veryActive;

  double get multiplier {
    switch (this) {
      case ActivityLevel.sedentary:
        return 1.2;
      case ActivityLevel.light:
        return 1.375;
      case ActivityLevel.moderate:
        return 1.55;
      case ActivityLevel.active:
        return 1.725;
      case ActivityLevel.veryActive:
        return 1.9;
    }
  }

  String get displayName {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Hareketsiz (Ofis isi)';
      case ActivityLevel.light:
        return 'Hafif Aktif (Haftada 1-3 gun)';
      case ActivityLevel.moderate:
        return 'Orta Aktif (Haftada 3-5 gun)';
      case ActivityLevel.active:
        return 'Aktif (Haftada 6-7 gun)';
      case ActivityLevel.veryActive:
        return 'Cok Aktif (Gunde 2x antrenman)';
    }
  }
}

enum GoalType {
  cut,
  maintain,
  bulk;

  String get displayName {
    switch (this) {
      case GoalType.cut:
        return 'Yag Yakma (Cut)';
      case GoalType.maintain:
        return 'Koruma (Maintain)';
      case GoalType.bulk:
        return 'Kas Yapma (Bulk)';
    }
  }

  int get mealSlotCount {
    switch (this) {
      case GoalType.bulk:
        return 6;
      case GoalType.cut:
      case GoalType.maintain:
        return 4;
    }
  }

  List<String> get activeMealTypes {
    switch (this) {
      case GoalType.bulk:
        return [
          'kahvalti', 'ara_ogun_1', 'ogle',
          'ara_ogun_2', 'aksam', 'gece_atistirmasi',
        ];
      case GoalType.cut:
      case GoalType.maintain:
        return ['kahvalti', 'ara_ogun_1', 'ogle', 'aksam'];
    }
  }
}

enum ExperienceLevel {
  beginner,
  intermediate,
  advanced;

  String get displayName {
    switch (this) {
      case ExperienceLevel.beginner:
        return 'Baslangic';
      case ExperienceLevel.intermediate:
        return 'Orta';
      case ExperienceLevel.advanced:
        return 'Ileri';
    }
  }
}
