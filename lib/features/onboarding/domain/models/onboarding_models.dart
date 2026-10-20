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
  final int currentStep; // 1 to 16/17
  final String? gender; // 'male', 'female', 'prefer_not_to_say'
  final int age;
  final double heightCm;
  final double weightKg;
  final double? targetWeightKg;
  final bool useMetricUnits;
  // Step 5: Body Composition
  final double? bodyFatPercentage;
  final double? waistCm;
  final double? hipCm;
  final double? chestCm;
  final double? neckCm;
  // Step 6: Main Goal
  final List<String> goals; // 'lose_weight', 'build_muscle', 'recomp', 'maintain'
  // Step 7: Target Timeline
  final int targetWeeks; // 4 to 52
  // Step 8: Focus Areas
  final List<String> focusAreas;
  // Step 8b: Gender Specific Goals
  final List<String> genderSpecificGoals;
  // Step 9: Experience Level
  final String experienceLevel; // 'beginner', 'intermediate', 'advanced'
  // Step 10: Training Location
  final String workoutLocation; // 'home', 'gym', 'outdoors'
  final List<String> workoutLocations; // ['gym', 'home', 'outdoors']
  // Step 11: Equipment
  final List<String> equipment;
  // Step 12: Schedule & Duration
  final int workoutDaysPerWeek; // 1 to 7
  final List<int> selectedWeekdays; // 0=Mon..6=Sun
  final bool usesEveryDay;
  final int sessionDurationMinutes; // 15 to 120 or custom up to 180
  // Step 13: Diet
  final String dietPreference; // 'vegetarian', 'non_vegetarian', 'eggetarian', 'vegan', 'pescatarian', 'other'
  final String allergies;
  // Step 14: Meals
  final int mealsPerDay; // 2 to 6
  final List<OnboardingMealSchedule> mealSchedules;
  // Step 15: Hydration
  final int dailyWaterMl; // 1000 to 5000 ml
  final String waterUnit; // 'ml', 'oz', 'glasses'
  final String drinkingFrequency;
  final bool enableWaterReminders;
  final int reminderFrequencyHours;
  final String quietHoursStart;
  final String quietHoursEnd;
  // Step 16: Lifestyle
  final String activityLevel; // 'sedentary', 'lightly_active', 'moderately_active', 'very_active'
  final double sleepHours;
  final int workHours;
  final String stressLevel; // 'low', 'moderate', 'high'
  final String workoutTimePreference;
  final String beveragePreferences;
  final List<String> motivations;
  final bool isGenderBranch;
  final bool isCompleted;
  final bool isGuest;

  const OnboardingState({
    this.currentStep = 1,
    this.gender,
    this.age = 26,
    this.heightCm = 175.0,
    this.weightKg = 72.0,
    this.targetWeightKg = 70.0,
    this.useMetricUnits = true,
    this.bodyFatPercentage,
    this.waistCm,
    this.hipCm,
    this.chestCm,
    this.neckCm,
    this.goals = const ['build_muscle'],
    this.targetWeeks = 12,
    this.focusAreas = const ['Full Body'],
    this.genderSpecificGoals = const [],
    this.experienceLevel = 'intermediate',
    this.workoutLocation = 'gym',
    this.workoutLocations = const ['gym'],
    this.equipment = const ['Dumbbells', 'Barbells'],
    this.workoutDaysPerWeek = 4,
    this.selectedWeekdays = const [0, 1, 2, 3],
    this.usesEveryDay = false,
    this.sessionDurationMinutes = 45,
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
    this.reminderFrequencyHours = 2,
    this.quietHoursStart = '10:00 PM',
    this.quietHoursEnd = '07:00 AM',
    this.activityLevel = 'moderately_active',
    this.sleepHours = 7.5,
    this.workHours = 8,
    this.stressLevel = 'moderate',
    this.workoutTimePreference = 'morning',
    this.beveragePreferences = 'Water, Coffee',
    this.motivations = const ['improve_health'],
    this.isGenderBranch = false,
    this.isCompleted = false,
    this.isGuest = true,
  });

  // Height and weight conversion helpers
  double get heightInFeet => heightCm / 30.48;
  double get weightInLbs => weightKg * 2.20462;
  double? get targetWeightInLbs =>
      targetWeightKg != null ? targetWeightKg! * 2.20462 : null;

  // Pace in kg/week
  double get calculatedPaceKgPerWeek {
    if (targetWeightKg == null || targetWeeks <= 0) return 0.5;
    final diff = (weightKg - targetWeightKg!).abs();
    return double.parse((diff / targetWeeks).toStringAsFixed(2));
  }

  bool get isPaceAggressive => calculatedPaceKgPerWeek > 1.0;

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
    int? age,
    double? heightCm,
    double? weightKg,
    double? targetWeightKg,
    bool? useMetricUnits,
    double? bodyFatPercentage,
    double? waistCm,
    double? hipCm,
    double? chestCm,
    double? neckCm,
    List<String>? goals,
    int? targetWeeks,
    List<String>? focusAreas,
    List<String>? genderSpecificGoals,
    String? experienceLevel,
    List<String>? workoutLocations,
    String? workoutLocation,
    List<String>? equipment,
    int? workoutDaysPerWeek,
    List<int>? selectedWeekdays,
    bool? usesEveryDay,
    int? sessionDurationMinutes,
    String? dietPreference,
    String? allergies,
    int? mealsPerDay,
    List<OnboardingMealSchedule>? mealSchedules,
    int? dailyWaterMl,
    String? waterUnit,
    String? drinkingFrequency,
    bool? enableWaterReminders,
    int? reminderFrequencyHours,
    String? quietHoursStart,
    String? quietHoursEnd,
    String? activityLevel,
    double? sleepHours,
    int? workHours,
    String? stressLevel,
    String? workoutTimePreference,
    String? beveragePreferences,
    List<String>? motivations,
    bool? isGenderBranch,
    bool? isCompleted,
    bool? isGuest,
  }) {
    List<String>? resolvedLocations = workoutLocations;
    if (resolvedLocations == null && workoutLocation != null) {
      resolvedLocations = [workoutLocation];
    }

    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      useMetricUnits: useMetricUnits ?? this.useMetricUnits,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      waistCm: waistCm ?? this.waistCm,
      hipCm: hipCm ?? this.hipCm,
      chestCm: chestCm ?? this.chestCm,
      neckCm: neckCm ?? this.neckCm,
      goals: goals ?? this.goals,
      targetWeeks: targetWeeks ?? this.targetWeeks,
      focusAreas: focusAreas ?? this.focusAreas,
      genderSpecificGoals: genderSpecificGoals ?? this.genderSpecificGoals,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      workoutLocations: resolvedLocations ?? this.workoutLocations,
      equipment: equipment ?? this.equipment,
      workoutDaysPerWeek: workoutDaysPerWeek ?? this.workoutDaysPerWeek,
      selectedWeekdays: selectedWeekdays ?? this.selectedWeekdays,
      usesEveryDay: usesEveryDay ?? this.usesEveryDay,
      sessionDurationMinutes:
          sessionDurationMinutes ?? this.sessionDurationMinutes,
      dietPreference: dietPreference ?? this.dietPreference,
      allergies: allergies ?? this.allergies,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      mealSchedules: mealSchedules ?? this.mealSchedules,
      dailyWaterMl: dailyWaterMl ?? this.dailyWaterMl,
      waterUnit: waterUnit ?? this.waterUnit,
      drinkingFrequency: drinkingFrequency ?? this.drinkingFrequency,
      enableWaterReminders:
          enableWaterReminders ?? this.enableWaterReminders,
      reminderFrequencyHours:
          reminderFrequencyHours ?? this.reminderFrequencyHours,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      activityLevel: activityLevel ?? this.activityLevel,
      sleepHours: sleepHours ?? this.sleepHours,
      workHours: workHours ?? this.workHours,
      stressLevel: stressLevel ?? this.stressLevel,
      workoutTimePreference:
          workoutTimePreference ?? this.workoutTimePreference,
      beveragePreferences: beveragePreferences ?? this.beveragePreferences,
      motivations: motivations ?? this.motivations,
      isGenderBranch: isGenderBranch ?? this.isGenderBranch,
      isCompleted: isCompleted ?? this.isCompleted,
      isGuest: isGuest ?? this.isGuest,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStep': currentStep,
      'gender': gender,
      'age': age,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'targetWeightKg': targetWeightKg,
      'useMetricUnits': useMetricUnits,
      'bodyFatPercentage': bodyFatPercentage,
      'waistCm': waistCm,
      'hipCm': hipCm,
      'chestCm': chestCm,
      'neckCm': neckCm,
      'goals': goals,
      'targetWeeks': targetWeeks,
      'focusAreas': focusAreas,
      'genderSpecificGoals': genderSpecificGoals,
      'experienceLevel': experienceLevel,
      'workoutLocations': workoutLocations,
      'equipment': equipment,
      'workoutDaysPerWeek': workoutDaysPerWeek,
      'selectedWeekdays': selectedWeekdays,
      'usesEveryDay': usesEveryDay,
      'sessionDurationMinutes': sessionDurationMinutes,
      'dietPreference': dietPreference,
      'allergies': allergies,
      'mealsPerDay': mealsPerDay,
      'mealSchedules': mealSchedules.map((m) => m.toJson()).toList(),
      'dailyWaterMl': dailyWaterMl,
      'waterUnit': waterUnit,
      'drinkingFrequency': drinkingFrequency,
      'enableWaterReminders': enableWaterReminders,
      'reminderFrequencyHours': reminderFrequencyHours,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'activityLevel': activityLevel,
      'sleepHours': sleepHours,
      'workHours': workHours,
      'stressLevel': stressLevel,
      'workoutTimePreference': workoutTimePreference,
      'beveragePreferences': beveragePreferences,
      'motivations': motivations,
      'isGenderBranch': isGenderBranch,
      'isCompleted': isCompleted,
      'isGuest': isGuest,
    };
  }

  factory OnboardingState.fromJson(Map<String, dynamic> json) {
    List<String> parsedLocations;
    if (json['workoutLocations'] != null) {
      parsedLocations = (json['workoutLocations'] as List<dynamic>)
          .map((e) => e.toString())
          .toList();
    } else if (json['workoutLocation'] != null) {
      parsedLocations = [json['workoutLocation'].toString()];
    } else {
      parsedLocations = const ['gym'];
    }

    return OnboardingState(
      currentStep: json['currentStep'] as int? ?? 1,
      gender: json['gender'] as String?,
      age: json['age'] as int? ?? 26,
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 175.0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 72.0,
      targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble() ?? 70.0,
      useMetricUnits: json['useMetricUnits'] as bool? ?? true,
      bodyFatPercentage: (json['bodyFatPercentage'] as num?)?.toDouble(),
      waistCm: (json['waistCm'] as num?)?.toDouble(),
      hipCm: (json['hipCm'] as num?)?.toDouble(),
      chestCm: (json['chestCm'] as num?)?.toDouble(),
      neckCm: (json['neckCm'] as num?)?.toDouble(),
      goals: (json['goals'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['build_muscle'],
      targetWeeks: json['targetWeeks'] as int? ?? 12,
      focusAreas: (json['focusAreas'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['Full Body'],
      genderSpecificGoals: (json['genderSpecificGoals'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      experienceLevel: json['experienceLevel'] as String? ?? 'intermediate',
      workoutLocations: parsedLocations,
      equipment: (json['equipment'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['Dumbbells', 'Barbells'],
      workoutDaysPerWeek: json['workoutDaysPerWeek'] as int? ?? 4,
      selectedWeekdays: (json['selectedWeekdays'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [0, 1, 2, 3],
      usesEveryDay: json['usesEveryDay'] as bool? ?? false,
      sessionDurationMinutes: json['sessionDurationMinutes'] as int? ?? 45,
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
      reminderFrequencyHours: json['reminderFrequencyHours'] as int? ?? 2,
      quietHoursStart: json['quietHoursStart'] as String? ?? '10:00 PM',
      quietHoursEnd: json['quietHoursEnd'] as String? ?? '07:00 AM',
      activityLevel: json['activityLevel'] as String? ?? 'moderately_active',
      sleepHours: (json['sleepHours'] as num?)?.toDouble() ?? 7.5,
      workHours: json['workHours'] as int? ?? 8,
      stressLevel: json['stressLevel'] as String? ?? 'moderate',
      workoutTimePreference:
          json['workoutTimePreference'] as String? ?? 'morning',
      beveragePreferences:
          json['beveragePreferences'] as String? ?? 'Water, Coffee',
      motivations: (json['motivations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['improve_health'],
      isGenderBranch: json['isGenderBranch'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isGuest: json['isGuest'] as bool? ?? true,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory OnboardingState.fromJsonString(String source) =>
      OnboardingState.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
