import 'dart:convert';

class OnboardingMealSchedule {
  final String name;
  final String time;

  const OnboardingMealSchedule({required this.name, required this.time});

  Map<String, dynamic> toJson() => {'name': name, 'time': time};

  factory OnboardingMealSchedule.fromJson(Map<String, dynamic> json) =>
      OnboardingMealSchedule(
        name: json['name'] as String? ?? 'Meal',
        time: json['time'] as String? ?? '12:00 PM',
      );
}

class OnboardingState {
  final int currentStep; // 1 to 12
  final String? gender; // 'male', 'female', 'prefer_not_to_say'
  final List<String> focusAreas;
  final List<String> goals;
  final List<String> motivations;
  final String experienceLevel; // 'beginner', 'intermediate', 'advanced'
  final String workoutLocation; // 'home', 'gym', 'outdoors'
  final List<String> equipment;
  final int sessionDurationMinutes; // 15, 30, 45, 60, 90
  final int workoutDaysPerWeek; // 2 to 6
  final int age;
  final double heightCm;
  final double weightKg;
  final double? targetWeightKg;
  final bool useMetricUnits;
  final String dietPreference; // 'vegetarian', 'non_vegetarian', 'eggetarian', 'vegan', 'pescatarian', 'other'
  final String allergies;
  final int mealsPerDay; // 2 to 6
  final List<OnboardingMealSchedule> mealSchedules;
  final int dailyWaterMl;
  final String waterUnit; // 'ml', 'oz', 'glasses'
  final String drinkingFrequency;
  final bool enableWaterReminders;
  final String quietHoursStart;
  final String quietHoursEnd;
  final String activityLevel; // 'sedentary', 'lightly_active', 'moderately_active', 'very_active'
  final double sleepHours;
  final String workoutTimePreference; // 'morning', 'afternoon', 'evening'
  final String beveragePreferences;
  final bool isCompleted;
  final bool isGuest;

  const OnboardingState({
    this.currentStep = 1,
    this.gender,
    this.focusAreas = const ['full_body'],
    this.goals = const ['build_muscle'],
    this.motivations = const ['improve_health'],
    this.experienceLevel = 'intermediate',
    this.workoutLocation = 'gym',
    this.equipment = const ['dumbbells', 'barbells'],
    this.sessionDurationMinutes = 45,
    this.workoutDaysPerWeek = 4,
    this.age = 26,
    this.heightCm = 175.0,
    this.weightKg = 72.0,
    this.targetWeightKg = 70.0,
    this.useMetricUnits = true,
    this.dietPreference = 'non_vegetarian',
    this.allergies = '',
    this.mealsPerDay = 3,
    this.mealSchedules = const [
      OnboardingMealSchedule(name: 'Breakfast', time: '08:30 AM'),
      OnboardingMealSchedule(name: 'Lunch', time: '01:00 PM'),
      OnboardingMealSchedule(name: 'Dinner', time: '07:30 PM'),
    ],
    this.dailyWaterMl = 2500,
    this.waterUnit = 'ml',
    this.drinkingFrequency = 'every_2_hours',
    this.enableWaterReminders = false,
    this.quietHoursStart = '10:00 PM',
    this.quietHoursEnd = '07:00 AM',
    this.activityLevel = 'moderately_active',
    this.sleepHours = 7.5,
    this.workoutTimePreference = 'morning',
    this.beveragePreferences = 'Water, Coffee',
    this.isCompleted = false,
    this.isGuest = true,
  });

  // Height conversion helpers
  double get heightInFeet => heightCm / 30.48;
  double get weightInLbs => weightKg * 2.20462;
  double? get targetWeightInLbs =>
      targetWeightKg != null ? targetWeightKg! * 2.20462 : null;

  // Scientific estimates for summary plan (Harris-Benedict BMR / TDEE approximation)
  int get estimatedDailyCalories {
    double bmr;
    if (gender == 'female') {
      bmr = 655.1 + (9.563 * weightKg) + (1.850 * heightCm) - (4.676 * age);
    } else {
      bmr = 66.5 + (13.75 * weightKg) + (5.003 * heightCm) - (6.75 * age);
    }
    double multiplier;
    switch (activityLevel) {
      case 'sedentary':
        multiplier = 1.2;
        break;
      case 'lightly_active':
        multiplier = 1.375;
        break;
      case 'very_active':
        multiplier = 1.725;
        break;
      case 'moderately_active':
      default:
        multiplier = 1.55;
    }
    double tdee = bmr * multiplier;
    if (goals.contains('lose_weight')) {
      tdee -= 400;
    } else if (goals.contains('build_muscle')) {
      tdee += 300;
    }
    return tdee.round().clamp(1400, 3800);
  }

  int get recommendedProteinGrams => (weightKg * 2.0).round().clamp(80, 240);
  int get recommendedCarbsGrams =>
      ((estimatedDailyCalories * 0.45) / 4).round().clamp(100, 450);
  int get recommendedFatsGrams =>
      ((estimatedDailyCalories * 0.25) / 9).round().clamp(40, 120);

  String get recommendedWorkoutPlanName {
    if (workoutDaysPerWeek <= 3) {
      return '3-Day Full Body Conditioning';
    } else if (workoutDaysPerWeek == 4) {
      return '4-Day Upper / Lower Hypertrophy Split';
    } else {
      return '5-Day Push / Pull / Legs + Conditioning';
    }
  }

  OnboardingState copyWith({
    int? currentStep,
    String? gender,
    List<String>? focusAreas,
    List<String>? goals,
    List<String>? motivations,
    String? experienceLevel,
    String? workoutLocation,
    List<String>? equipment,
    int? sessionDurationMinutes,
    int? workoutDaysPerWeek,
    int? age,
    double? heightCm,
    double? weightKg,
    double? targetWeightKg,
    bool? useMetricUnits,
    String? dietPreference,
    String? allergies,
    int? mealsPerDay,
    List<OnboardingMealSchedule>? mealSchedules,
    int? dailyWaterMl,
    String? waterUnit,
    String? drinkingFrequency,
    bool? enableWaterReminders,
    String? quietHoursStart,
    String? quietHoursEnd,
    String? activityLevel,
    double? sleepHours,
    String? workoutTimePreference,
    String? beveragePreferences,
    bool? isCompleted,
    bool? isGuest,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      gender: gender ?? this.gender,
      focusAreas: focusAreas ?? this.focusAreas,
      goals: goals ?? this.goals,
      motivations: motivations ?? this.motivations,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      workoutLocation: workoutLocation ?? this.workoutLocation,
      equipment: equipment ?? this.equipment,
      sessionDurationMinutes:
          sessionDurationMinutes ?? this.sessionDurationMinutes,
      workoutDaysPerWeek: workoutDaysPerWeek ?? this.workoutDaysPerWeek,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      useMetricUnits: useMetricUnits ?? this.useMetricUnits,
      dietPreference: dietPreference ?? this.dietPreference,
      allergies: allergies ?? this.allergies,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      mealSchedules: mealSchedules ?? this.mealSchedules,
      dailyWaterMl: dailyWaterMl ?? this.dailyWaterMl,
      waterUnit: waterUnit ?? this.waterUnit,
      drinkingFrequency: drinkingFrequency ?? this.drinkingFrequency,
      enableWaterReminders: enableWaterReminders ?? this.enableWaterReminders,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      activityLevel: activityLevel ?? this.activityLevel,
      sleepHours: sleepHours ?? this.sleepHours,
      workoutTimePreference:
          workoutTimePreference ?? this.workoutTimePreference,
      beveragePreferences: beveragePreferences ?? this.beveragePreferences,
      isCompleted: isCompleted ?? this.isCompleted,
      isGuest: isGuest ?? this.isGuest,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStep': currentStep,
      'gender': gender,
      'focusAreas': focusAreas,
      'goals': goals,
      'motivations': motivations,
      'experienceLevel': experienceLevel,
      'workoutLocation': workoutLocation,
      'equipment': equipment,
      'sessionDurationMinutes': sessionDurationMinutes,
      'workoutDaysPerWeek': workoutDaysPerWeek,
      'age': age,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'targetWeightKg': targetWeightKg,
      'useMetricUnits': useMetricUnits,
      'dietPreference': dietPreference,
      'allergies': allergies,
      'mealsPerDay': mealsPerDay,
      'mealSchedules': mealSchedules.map((m) => m.toJson()).toList(),
      'dailyWaterMl': dailyWaterMl,
      'waterUnit': waterUnit,
      'drinkingFrequency': drinkingFrequency,
      'enableWaterReminders': enableWaterReminders,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'activityLevel': activityLevel,
      'sleepHours': sleepHours,
      'workoutTimePreference': workoutTimePreference,
      'beveragePreferences': beveragePreferences,
      'isCompleted': isCompleted,
      'isGuest': isGuest,
    };
  }

  factory OnboardingState.fromJson(Map<String, dynamic> json) {
    return OnboardingState(
      currentStep: json['currentStep'] as int? ?? 1,
      gender: json['gender'] as String?,
      focusAreas: (json['focusAreas'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['full_body'],
      goals: (json['goals'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['build_muscle'],
      motivations: (json['motivations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['improve_health'],
      experienceLevel: json['experienceLevel'] as String? ?? 'intermediate',
      workoutLocation: json['workoutLocation'] as String? ?? 'gym',
      equipment: (json['equipment'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['dumbbells', 'barbells'],
      sessionDurationMinutes: json['sessionDurationMinutes'] as int? ?? 45,
      workoutDaysPerWeek: json['workoutDaysPerWeek'] as int? ?? 4,
      age: json['age'] as int? ?? 26,
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 175.0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 72.0,
      targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble() ?? 70.0,
      useMetricUnits: json['useMetricUnits'] as bool? ?? true,
      dietPreference: json['dietPreference'] as String? ?? 'non_vegetarian',
      allergies: json['allergies'] as String? ?? '',
      mealsPerDay: json['mealsPerDay'] as int? ?? 3,
      mealSchedules: (json['mealSchedules'] as List<dynamic>?)
              ?.map((e) =>
                  OnboardingMealSchedule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [
            OnboardingMealSchedule(name: 'Breakfast', time: '08:30 AM'),
            OnboardingMealSchedule(name: 'Lunch', time: '01:00 PM'),
            OnboardingMealSchedule(name: 'Dinner', time: '07:30 PM'),
          ],
      dailyWaterMl: json['dailyWaterMl'] as int? ?? 2500,
      waterUnit: json['waterUnit'] as String? ?? 'ml',
      drinkingFrequency: json['drinkingFrequency'] as String? ?? 'every_2_hours',
      enableWaterReminders: json['enableWaterReminders'] as bool? ?? false,
      quietHoursStart: json['quietHoursStart'] as String? ?? '10:00 PM',
      quietHoursEnd: json['quietHoursEnd'] as String? ?? '07:00 AM',
      activityLevel: json['activityLevel'] as String? ?? 'moderately_active',
      sleepHours: (json['sleepHours'] as num?)?.toDouble() ?? 7.5,
      workoutTimePreference: json['workoutTimePreference'] as String? ?? 'morning',
      beveragePreferences:
          json['beveragePreferences'] as String? ?? 'Water, Coffee',
      isCompleted: json['isCompleted'] as bool? ?? false,
      isGuest: json['isGuest'] as bool? ?? true,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory OnboardingState.fromJsonString(String source) =>
      OnboardingState.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
