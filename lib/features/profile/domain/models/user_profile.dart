import 'dart:convert';

class UserProfile {
  final String id;
  final String name;
  final int age;
  final String gender; // 'male', 'female', 'other'
  final double heightCm;
  final double weightKg;
  final double? targetWeightKg;
  final bool useMetricUnits;

  // 'lose_weight', 'gain_weight', 'maintain_weight'
  final String fitnessGoal;

  // 'balanced', 'high_protein', 'low_carb', 'vegetarian', 'vegan', 'mediterranean'
  final String dietType;

  // 'suggested' or 'custom'
  final String targetMode;

  // Nutrition targets
  final int dailyCaloriesTarget;
  final int targetProteinGrams;
  final int targetCarbsGrams;
  final int targetFatsGrams;
  final int targetWaterMl;

  // Workout targets
  final int weeklyWorkoutDays;
  final int dailyWorkoutMinutes;
  final int dailyCaloriesBurnTarget;
  final String? customTargetNote;

  // Real-world Advanced Health & Lifestyle parameters
  final String activityLevel; // 'sedentary', 'light', 'moderate', 'very_active', 'athlete'
  final String experienceLevel; // 'beginner', 'intermediate', 'advanced'
  final double? bodyFatPercentage; // e.g. 15.0%
  final int? restingHeartRate; // e.g. 62 bpm
  final double targetPaceKgPerWeek; // e.g. 0.5 kg/week
  final String fastingProtocol; // 'none', '16:8', '18:6', 'circadian'
  final int dailyStepsGoal; // e.g. 10000 steps
  final double targetSleepHours; // e.g. 8.0 hours
  final double? strideLengthCm; // e.g. 72.5 cm (walking or running configured)

  final String avatarId; // 'male_1', 'male_2', 'female_1', 'female_2', 'neutral', 'initial'
  final List<String> focusAreas;
  final bool isProfileSetupCompleted;
  final DateTime updatedAt;

  // Extended Wizard & Personalization parameters
  final List<String> genderSpecificGoals;
  final double? waistCm;
  final double? hipCm;
  final double? chestCm;
  final double? neckCm;
  final int? targetWeeks;
  final List<int> selectedWeekdays;
  final int sessionDurationMinutes;
  final bool usesEveryDay;
  final int mealsPerDay;
  final String? stressLevel;
  final int reminderFrequencyHours;
  final String? quietHoursStart;
  final String? quietHoursEnd;
  final String? allergyNotes;
  final int? workHours;

  double? get bodyFatPercent => bodyFatPercentage;

  const UserProfile({
    this.id = 'guest_user',
    this.name = 'Guest Athlete',
    this.avatarId = 'initial',
    this.focusAreas = const ['full_body'],
    this.age = 26,
    this.gender = 'male',
    this.heightCm = 175.0,
    this.weightKg = 72.0,
    this.targetWeightKg = 70.0,
    this.useMetricUnits = true,
    this.fitnessGoal = 'maintain_weight',
    this.dietType = 'balanced',
    this.targetMode = 'suggested',
    this.dailyCaloriesTarget = 2250,
    this.targetProteinGrams = 145,
    this.targetCarbsGrams = 250,
    this.targetFatsGrams = 60,
    this.targetWaterMl = 2500,
    this.weeklyWorkoutDays = 4,
    this.dailyWorkoutMinutes = 45,
    this.dailyCaloriesBurnTarget = 350,
    this.customTargetNote,
    this.activityLevel = 'moderate',
    this.experienceLevel = 'intermediate',
    this.bodyFatPercentage,
    this.restingHeartRate,
    this.targetPaceKgPerWeek = 0.5,
    this.fastingProtocol = 'none',
    this.dailyStepsGoal = 10000,
    this.targetSleepHours = 8.0,
    this.strideLengthCm,
    this.isProfileSetupCompleted = true,
    this.genderSpecificGoals = const [],
    this.waistCm,
    this.hipCm,
    this.chestCm,
    this.neckCm,
    this.targetWeeks = 12,
    this.selectedWeekdays = const [0, 1, 2, 3],
    this.sessionDurationMinutes = 45,
    this.usesEveryDay = false,
    this.mealsPerDay = 3,
    this.stressLevel,
    this.reminderFrequencyHours = 2,
    this.quietHoursStart = '10:00 PM',
    this.quietHoursEnd = '07:00 AM',
    this.allergyNotes,
    this.workHours = 8,
    required this.updatedAt,
  });

  /// Stride length in cm, defaults to height * 0.415 if unset
  double get effectiveStrideLengthCm =>
      (strideLengthCm != null && strideLengthCm! > 0)
          ? strideLengthCm!
          : (heightCm * 0.415);

  // Clean Default Guest profile
  static UserProfile defaultGuest() {
    return UserProfile(
      id: 'guest_user',
      name: 'Guest Athlete',
      avatarId: 'initial',
      focusAreas: const ['full_body'],
      age: 26,
      gender: 'male',
      heightCm: 175.0,
      weightKg: 72.0,
      targetWeightKg: 70.0,
      useMetricUnits: true,
      fitnessGoal: 'maintain_weight',
      dietType: 'balanced',
      targetMode: 'suggested',
      dailyCaloriesTarget: 2250,
      targetProteinGrams: 145,
      targetCarbsGrams: 250,
      targetFatsGrams: 60,
      targetWaterMl: 2500,
      weeklyWorkoutDays: 4,
      dailyWorkoutMinutes: 45,
      dailyCaloriesBurnTarget: 350,
      customTargetNote: null,
      activityLevel: 'moderate',
      experienceLevel: 'intermediate',
      bodyFatPercentage: null,
      restingHeartRate: null,
      targetPaceKgPerWeek: 0.5,
      fastingProtocol: 'none',
      dailyStepsGoal: 10000,
      targetSleepHours: 8.0,
      isProfileSetupCompleted: true,
      genderSpecificGoals: const [],
      waistCm: null,
      hipCm: null,
      chestCm: null,
      neckCm: null,
      targetWeeks: 12,
      selectedWeekdays: const [0, 1, 2, 3],
      sessionDurationMinutes: 45,
      usesEveryDay: false,
      mealsPerDay: 3,
      stressLevel: null,
      reminderFrequencyHours: 2,
      quietHoursStart: '10:00 PM',
      quietHoursEnd: '07:00 AM',
      allergyNotes: null,
      workHours: 8,
      updatedAt: DateTime.now(),
    );
  }

  // Real-world Health Intelligence Calculations
  double get bmi {
    if (heightCm <= 0) return 22.0;
    final hMeters = heightCm / 100.0;
    return double.parse((weightKg / (hMeters * hMeters)).toStringAsFixed(1));
  }

  String get bmiCategory {
    final v = bmi;
    if (v < 18.5) return 'Underweight';
    if (v < 25.0) return 'Healthy / Optimal';
    if (v < 30.0) return 'Overweight';
    return 'Obese';
  }

  // Mifflin-St Jeor Basal Metabolic Rate (BMR)
  double get bmrCalculated {
    if (gender == 'female') {
      return (10 * weightKg + 6.25 * heightCm - 5 * age - 161);
    } else if (gender == 'male') {
      return (10 * weightKg + 6.25 * heightCm - 5 * age + 5);
    } else {
      return (10 * weightKg + 6.25 * heightCm - 5 * age - 78);
    }
  }

  // Activity Multiplier based on Level
  double get activityMultiplier {
    switch (activityLevel) {
      case 'sedentary':
        return 1.2;
      case 'light':
        return 1.375;
      case 'moderate':
        return 1.55;
      case 'very_active':
        return 1.725;
      case 'athlete':
        return 1.9;
      default:
        if (weeklyWorkoutDays >= 5) return 1.65;
        if (weeklyWorkoutDays >= 3) return 1.45;
        if (weeklyWorkoutDays >= 1) return 1.35;
        return 1.2;
    }
  }

  // Total Daily Energy Expenditure (TDEE)
  double get tdeeCalculated => bmrCalculated * activityMultiplier;

  // Calorie deficit or surplus compared to maintenance
  int get calorieDelta => dailyCaloriesTarget - tdeeCalculated.round();

  // Macro Caloric Percentages
  int get proteinCaloriesPercent {
    if (dailyCaloriesTarget <= 0) return 25;
    return ((targetProteinGrams * 4) / dailyCaloriesTarget * 100).round();
  }

  int get carbsCaloriesPercent {
    if (dailyCaloriesTarget <= 0) return 50;
    return ((targetCarbsGrams * 4) / dailyCaloriesTarget * 100).round();
  }

  int get fatsCaloriesPercent {
    if (dailyCaloriesTarget <= 0) return 25;
    return ((targetFatsGrams * 9) / dailyCaloriesTarget * 100).round();
  }

  // Estimated weeks to goal weight
  int? get estimatedWeeksToGoal {
    if (targetWeightKg == null) return null;
    final diff = (weightKg - targetWeightKg!).abs();
    if (diff < 0.2) return 0;
    final pace = targetPaceKgPerWeek > 0 ? targetPaceKgPerWeek : 0.5;
    return (diff / pace).ceil();
  }

  // Display labels
  String get goalLabel {
    switch (fitnessGoal) {
      case 'lose_weight':
        return 'Weight Loss (Fat Loss)';
      case 'gain_weight':
      case 'build_muscle':
        return 'Weight Gain (Muscle Building)';
      case 'maintain_weight':
      case 'keep_fit':
      default:
        return 'Maintain Weight & Health';
    }
  }

  String get dietTypeTitle {
    switch (dietType) {
      case 'high_protein':
        return 'High Protein Nutrition';
      case 'low_carb':
        return 'Low Carb / Keto Nutrition';
      case 'vegetarian':
        return 'Vegetarian Nutrition';
      case 'vegan':
        return 'Vegan Plant Fuel';
      case 'mediterranean':
        return 'Mediterranean Nutrition';
      case 'balanced':
      default:
        return 'Balanced Nutrition';
    }
  }

  String get activityLevelLabel {
    switch (activityLevel) {
      case 'sedentary':
        return 'Sedentary (Desk Job)';
      case 'light':
        return 'Lightly Active (1-2 days)';
      case 'moderate':
        return 'Moderately Active (3-4 days)';
      case 'very_active':
        return 'Very Active (5-6 days)';
      case 'athlete':
        return 'Athlete / High Intensity';
      default:
        return 'Active Lifestyle';
    }
  }

  String get experienceLevelLabel {
    switch (experienceLevel) {
      case 'beginner':
        return 'Beginner (<1 yr)';
      case 'intermediate':
        return 'Intermediate (1-3 yrs)';
      case 'advanced':
        return 'Advanced (>3 yrs)';
      default:
        return 'Intermediate';
    }
  }

  String get fastingProtocolLabel {
    switch (fastingProtocol) {
      case '16:8':
        return '16:8 Intermittent Fasting';
      case '18:6':
        return '18:6 Intermittent Fasting';
      case 'circadian':
        return 'Circadian Rhythm Fasting';
      case 'none':
      default:
        return 'Standard Meal Timing';
    }
  }

  // Unit helpers
  double get heightInFeet => heightCm / 30.48;
  double get weightInLbs => weightKg * 2.20462;
  double? get targetWeightInLbs =>
      targetWeightKg != null ? targetWeightKg! * 2.20462 : null;

  // Factory to calculate suggested balanced values from body stats & goals
  static UserProfile calculateSuggestedTargets({
    String id = 'guest_user',
    String name = 'Guest Athlete',
    int age = 26,
    String gender = 'male',
    double heightCm = 175.0,
    double weightKg = 72.0,
    double? targetWeightKg,
    bool useMetricUnits = true,
    String fitnessGoal = 'maintain_weight',
    String dietType = 'balanced',
    int weeklyWorkoutDays = 4,
    int dailyWorkoutMinutes = 45,
    String? customTargetNote,
    String activityLevel = 'moderate',
    String experienceLevel = 'intermediate',
    double? bodyFatPercentage,
    int? restingHeartRate,
    double targetPaceKgPerWeek = 0.5,
    String fastingProtocol = 'none',
    int dailyStepsGoal = 10000,
    double targetSleepHours = 8.0,
    String avatarId = 'initial',
    List<String> focusAreas = const ['full_body'],
    bool isCompleted = true,
    List<String> genderSpecificGoals = const [],
    double? waistCm,
    double? hipCm,
    double? chestCm,
    double? neckCm,
    int? targetWeeks = 12,
    List<int> selectedWeekdays = const [0, 1, 2, 3],
    int sessionDurationMinutes = 45,
    bool usesEveryDay = false,
    int mealsPerDay = 3,
    String? stressLevel,
    int reminderFrequencyHours = 2,
    String? quietHoursStart = '10:00 PM',
    String? quietHoursEnd = '07:00 AM',
    String? allergyNotes,
    int? workHours = 8,
  }) {
    // Mifflin-St Jeor BMR formula
    double bmr;
    if (gender == 'female') {
      bmr = 10 * weightKg + 6.25 * heightCm - 5 * age - 161;
    } else if (gender == 'male') {
      bmr = 10 * weightKg + 6.25 * heightCm - 5 * age + 5;
    } else {
      bmr = 10 * weightKg + 6.25 * heightCm - 5 * age - 78;
    }

    // Activity multiplier based on weekly workout commitment or explicit level
    double activityMult = 1.2;
    if (activityLevel == 'athlete') {
      activityMult = 1.9;
    } else if (activityLevel == 'very_active' || weeklyWorkoutDays >= 5) {
      activityMult = 1.65;
    } else if (activityLevel == 'moderate' || weeklyWorkoutDays >= 3) {
      activityMult = 1.45;
    } else if (activityLevel == 'light' || weeklyWorkoutDays >= 1) {
      activityMult = 1.35;
    }

    final double tdee = bmr * activityMult;

    // Caloric deficit or surplus based on user's primary target
    int calories;
    if (fitnessGoal == 'lose_weight') {
      calories = (tdee - 450).round().clamp(1400, 3600);
    } else if (fitnessGoal == 'gain_weight' || fitnessGoal == 'build_muscle') {
      calories = (tdee + 350).round().clamp(1800, 4200);
    } else {
      calories = tdee.round().clamp(1600, 3800);
    }

    // Macro breakdown according to diet type & fitness goal
    int protein;
    int fat;
    int carbs;

    if (dietType == 'high_protein' || fitnessGoal == 'gain_weight' || fitnessGoal == 'build_muscle') {
      protein = (weightKg * 2.2).round().clamp(90, 240);
      fat = ((calories * 0.25) / 9).round().clamp(40, 110);
      carbs = ((calories - (protein * 4) - (fat * 9)) / 4).round().clamp(60, 450);
    } else if (dietType == 'low_carb') {
      protein = (weightKg * 2.0).round().clamp(90, 220);
      carbs = 50;
      fat = ((calories - (protein * 4) - (carbs * 4)) / 9).round().clamp(50, 160);
    } else {
      protein = (weightKg * 1.8).round().clamp(75, 200);
      fat = ((calories * 0.25) / 9).round().clamp(40, 100);
      carbs = ((calories - (protein * 4) - (fat * 9)) / 4).round().clamp(100, 400);
    }

    final int water = (weightKg * 35).round().clamp(2000, 4000);
    final int burnTarget = (dailyWorkoutMinutes * 7.5).round();

    return UserProfile(
      id: id,
      name: name.trim().isNotEmpty ? name.trim() : 'Guest Athlete',
      avatarId: avatarId,
      focusAreas: focusAreas,
      age: age,
      gender: gender,
      heightCm: heightCm,
      weightKg: weightKg,
      targetWeightKg: targetWeightKg,
      useMetricUnits: useMetricUnits,
      fitnessGoal: fitnessGoal,
      dietType: dietType,
      targetMode: 'suggested',
      dailyCaloriesTarget: calories,
      targetProteinGrams: protein,
      targetCarbsGrams: carbs,
      targetFatsGrams: fat,
      targetWaterMl: water,
      weeklyWorkoutDays: weeklyWorkoutDays,
      dailyWorkoutMinutes: dailyWorkoutMinutes,
      dailyCaloriesBurnTarget: burnTarget,
      customTargetNote: customTargetNote,
      activityLevel: activityLevel,
      experienceLevel: experienceLevel,
      bodyFatPercentage: bodyFatPercentage,
      restingHeartRate: restingHeartRate,
      targetPaceKgPerWeek: targetPaceKgPerWeek,
      fastingProtocol: fastingProtocol,
      dailyStepsGoal: dailyStepsGoal,
      targetSleepHours: targetSleepHours,
      isProfileSetupCompleted: isCompleted,
      genderSpecificGoals: genderSpecificGoals,
      waistCm: waistCm,
      hipCm: hipCm,
      chestCm: chestCm,
      neckCm: neckCm,
      targetWeeks: targetWeeks,
      selectedWeekdays: selectedWeekdays,
      sessionDurationMinutes: sessionDurationMinutes,
      usesEveryDay: usesEveryDay,
      mealsPerDay: mealsPerDay,
      stressLevel: stressLevel,
      reminderFrequencyHours: reminderFrequencyHours,
      quietHoursStart: quietHoursStart,
      quietHoursEnd: quietHoursEnd,
      allergyNotes: allergyNotes,
      workHours: workHours,
      updatedAt: DateTime.now(),
    );
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? avatarId,
    List<String>? focusAreas,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    double? targetWeightKg,
    bool? useMetricUnits,
    String? fitnessGoal,
    String? dietType,
    String? targetMode,
    int? dailyCaloriesTarget,
    int? targetProteinGrams,
    int? targetCarbsGrams,
    int? targetFatsGrams,
    int? targetWaterMl,
    int? weeklyWorkoutDays,
    int? dailyWorkoutMinutes,
    int? dailyCaloriesBurnTarget,
    String? customTargetNote,
    String? activityLevel,
    String? experienceLevel,
    double? bodyFatPercentage,
    int? restingHeartRate,
    double? targetPaceKgPerWeek,
    String? fastingProtocol,
    int? dailyStepsGoal,
    double? targetSleepHours,
    double? strideLengthCm,
    bool? isProfileSetupCompleted,
    List<String>? genderSpecificGoals,
    double? waistCm,
    double? hipCm,
    double? chestCm,
    double? neckCm,
    int? targetWeeks,
    List<int>? selectedWeekdays,
    int? sessionDurationMinutes,
    bool? usesEveryDay,
    int? mealsPerDay,
    String? stressLevel,
    int? reminderFrequencyHours,
    String? quietHoursStart,
    String? quietHoursEnd,
    String? allergyNotes,
    int? workHours,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarId: avatarId ?? this.avatarId,
      focusAreas: focusAreas ?? this.focusAreas,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      useMetricUnits: useMetricUnits ?? this.useMetricUnits,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      dietType: dietType ?? this.dietType,
      targetMode: targetMode ?? this.targetMode,
      dailyCaloriesTarget: dailyCaloriesTarget ?? this.dailyCaloriesTarget,
      targetProteinGrams: targetProteinGrams ?? this.targetProteinGrams,
      targetCarbsGrams: targetCarbsGrams ?? this.targetCarbsGrams,
      targetFatsGrams: targetFatsGrams ?? this.targetFatsGrams,
      targetWaterMl: targetWaterMl ?? this.targetWaterMl,
      weeklyWorkoutDays: weeklyWorkoutDays ?? this.weeklyWorkoutDays,
      dailyWorkoutMinutes: dailyWorkoutMinutes ?? this.dailyWorkoutMinutes,
      dailyCaloriesBurnTarget: dailyCaloriesBurnTarget ?? this.dailyCaloriesBurnTarget,
      customTargetNote: customTargetNote ?? this.customTargetNote,
      activityLevel: activityLevel ?? this.activityLevel,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      restingHeartRate: restingHeartRate ?? this.restingHeartRate,
      targetPaceKgPerWeek: targetPaceKgPerWeek ?? this.targetPaceKgPerWeek,
      fastingProtocol: fastingProtocol ?? this.fastingProtocol,
      dailyStepsGoal: dailyStepsGoal ?? this.dailyStepsGoal,
      targetSleepHours: targetSleepHours ?? this.targetSleepHours,
      strideLengthCm: strideLengthCm ?? this.strideLengthCm,
      isProfileSetupCompleted: isProfileSetupCompleted ?? this.isProfileSetupCompleted,
      genderSpecificGoals: genderSpecificGoals ?? this.genderSpecificGoals,
      waistCm: waistCm ?? this.waistCm,
      hipCm: hipCm ?? this.hipCm,
      chestCm: chestCm ?? this.chestCm,
      neckCm: neckCm ?? this.neckCm,
      targetWeeks: targetWeeks ?? this.targetWeeks,
      selectedWeekdays: selectedWeekdays ?? this.selectedWeekdays,
      sessionDurationMinutes: sessionDurationMinutes ?? this.sessionDurationMinutes,
      usesEveryDay: usesEveryDay ?? this.usesEveryDay,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      stressLevel: stressLevel ?? this.stressLevel,
      reminderFrequencyHours: reminderFrequencyHours ?? this.reminderFrequencyHours,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      allergyNotes: allergyNotes ?? this.allergyNotes,
      workHours: workHours ?? this.workHours,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatarId': avatarId,
        'focusAreas': focusAreas,
        'age': age,
        'gender': gender,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'targetWeightKg': targetWeightKg,
        'useMetricUnits': useMetricUnits,
        'fitnessGoal': fitnessGoal,
        'dietType': dietType,
        'targetMode': targetMode,
        'dailyCaloriesTarget': dailyCaloriesTarget,
        'targetProteinGrams': targetProteinGrams,
        'targetCarbsGrams': targetCarbsGrams,
        'targetFatsGrams': targetFatsGrams,
        'targetWaterMl': targetWaterMl,
        'weeklyWorkoutDays': weeklyWorkoutDays,
        'dailyWorkoutMinutes': dailyWorkoutMinutes,
        'dailyCaloriesBurnTarget': dailyCaloriesBurnTarget,
        'customTargetNote': customTargetNote,
        'activityLevel': activityLevel,
        'experienceLevel': experienceLevel,
        'bodyFatPercentage': bodyFatPercentage,
        'restingHeartRate': restingHeartRate,
        'targetPaceKgPerWeek': targetPaceKgPerWeek,
        'fastingProtocol': fastingProtocol,
        'dailyStepsGoal': dailyStepsGoal,
        'targetSleepHours': targetSleepHours,
        'strideLengthCm': strideLengthCm,
        'isProfileSetupCompleted': isProfileSetupCompleted,
        'genderSpecificGoals': genderSpecificGoals,
        'waistCm': waistCm,
        'hipCm': hipCm,
        'chestCm': chestCm,
        'neckCm': neckCm,
        'targetWeeks': targetWeeks,
        'selectedWeekdays': selectedWeekdays,
        'sessionDurationMinutes': sessionDurationMinutes,
        'usesEveryDay': usesEveryDay,
        'mealsPerDay': mealsPerDay,
        'stressLevel': stressLevel,
        'reminderFrequencyHours': reminderFrequencyHours,
        'quietHoursStart': quietHoursStart,
        'quietHoursEnd': quietHoursEnd,
        'allergyNotes': allergyNotes,
        'workHours': workHours,
        'updatedAt': updatedAt.toIso8601String(),
      };

  String toJsonString() => jsonEncode(toJson());

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? 'guest_user',
      name: json['name'] as String? ?? 'Guest Athlete',
      avatarId: json['avatarId'] as String? ?? 'initial',
      focusAreas: (json['focusAreas'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['full_body'],
      age: json['age'] as int? ?? 26,
      gender: json['gender'] as String? ?? 'male',
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 175.0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 72.0,
      targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble(),
      useMetricUnits: json['useMetricUnits'] as bool? ?? true,
      fitnessGoal: json['fitnessGoal'] as String? ?? 'maintain_weight',
      dietType: json['dietType'] as String? ?? 'balanced',
      targetMode: json['targetMode'] as String? ?? 'suggested',
      dailyCaloriesTarget: json['dailyCaloriesTarget'] as int? ?? 2250,
      targetProteinGrams: json['targetProteinGrams'] as int? ?? 145,
      targetCarbsGrams: json['targetCarbsGrams'] as int? ?? 250,
      targetFatsGrams: json['targetFatsGrams'] as int? ?? 60,
      targetWaterMl: json['targetWaterMl'] as int? ?? 2500,
      weeklyWorkoutDays: json['weeklyWorkoutDays'] as int? ?? 4,
      dailyWorkoutMinutes: json['dailyWorkoutMinutes'] as int? ?? 45,
      dailyCaloriesBurnTarget: json['dailyCaloriesBurnTarget'] as int? ?? 350,
      customTargetNote: json['customTargetNote'] as String?,
      activityLevel: json['activityLevel'] as String? ?? 'moderate',
      experienceLevel: json['experienceLevel'] as String? ?? 'intermediate',
      bodyFatPercentage: (json['bodyFatPercentage'] as num?)?.toDouble(),
      restingHeartRate: json['restingHeartRate'] as int?,
      targetPaceKgPerWeek: (json['targetPaceKgPerWeek'] as num?)?.toDouble() ?? 0.5,
      fastingProtocol: json['fastingProtocol'] as String? ?? 'none',
      dailyStepsGoal: json['dailyStepsGoal'] as int? ?? 10000,
      targetSleepHours: (json['targetSleepHours'] as num?)?.toDouble() ?? 8.0,
      strideLengthCm: (json['strideLengthCm'] as num?)?.toDouble(),
      isProfileSetupCompleted: json['isProfileSetupCompleted'] as bool? ?? true,
      genderSpecificGoals: (json['genderSpecificGoals'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      waistCm: (json['waistCm'] as num?)?.toDouble(),
      hipCm: (json['hipCm'] as num?)?.toDouble(),
      chestCm: (json['chestCm'] as num?)?.toDouble(),
      neckCm: (json['neckCm'] as num?)?.toDouble(),
      targetWeeks: json['targetWeeks'] as int? ?? 12,
      selectedWeekdays: (json['selectedWeekdays'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [0, 1, 2, 3],
      sessionDurationMinutes: json['sessionDurationMinutes'] as int? ?? 45,
      usesEveryDay: json['usesEveryDay'] as bool? ?? false,
      mealsPerDay: json['mealsPerDay'] as int? ?? 3,
      stressLevel: json['stressLevel'] as String?,
      reminderFrequencyHours: json['reminderFrequencyHours'] as int? ?? 2,
      quietHoursStart: json['quietHoursStart'] as String? ?? '10:00 PM',
      quietHoursEnd: json['quietHoursEnd'] as String? ?? '07:00 AM',
      allergyNotes: json['allergyNotes'] as String?,
      workHours: json['workHours'] as int? ?? 8,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  factory UserProfile.fromJsonString(String source) =>
      UserProfile.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
