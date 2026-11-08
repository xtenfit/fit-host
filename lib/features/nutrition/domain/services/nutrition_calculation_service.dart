import '../../../profile/domain/models/user_profile.dart';

/// Nutrition targets calculated canonically from user profile or validated defaults.
class NutritionGoalTargets {
  final int dailyCalories;
  final int proteinGrams;
  final int carbsGrams;
  final int fatsGrams;
  final int targetWaterMl;
  final int dailyCaloriesBurnTarget;
  final bool isPersonalized;
  final String formulaDescription;

  const NutritionGoalTargets({
    required this.dailyCalories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatsGrams,
    required this.targetWaterMl,
    required this.dailyCaloriesBurnTarget,
    required this.isPersonalized,
    required this.formulaDescription,
  });

  /// Default baseline target when user profile is incomplete or unconfigured.
  factory NutritionGoalTargets.defaultBaseline() {
    return const NutritionGoalTargets(
      dailyCalories: 2250,
      proteinGrams: 145,
      carbsGrams: 250,
      fatsGrams: 60,
      targetWaterMl: 2500,
      dailyCaloriesBurnTarget: 350,
      isPersonalized: false,
      formulaDescription:
          'Standard adult baseline (70kg moderate activity reference)',
    );
  }
}

/// Canonical service for all nutritional, energy-balance, and metabolic calculations.
///
/// Strictly adheres to:
/// - Mifflin-St Jeor equation for Basal Metabolic Rate (BMR)
/// - Compendium of Physical Activities for TDEE multipliers
/// - Proportional macronutrient distribution:
///   Protein: 4 kcal/g, Carbohydrates: 4 kcal/g, Fat: 9 kcal/g
/// - Strict $(per100g * portionGrams) / 100.0$ for food portion scaling
class NutritionCalculationService {
  const NutritionCalculationService();

  /// Mifflin-St Jeor BMR calculation.
  ///
  /// Men: BMR = 10 x weight(kg) + 6.25 x height(cm) - 5 x age(y) + 5
  /// Women: BMR = 10 x weight(kg) + 6.25 x height(cm) - 5 x age(y) - 161
  /// Neutral/Other: BMR = 10 x weight(kg) + 6.25 x height(cm) - 5 x age(y) - 78
  static double calculateBmr({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
  }) {
    if (weightKg <= 0 || heightCm <= 0 || age <= 0) {
      return 1650.0; // Sensible physiological fallback
    }

    final base = (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * age);
    switch (gender.toLowerCase()) {
      case 'male':
        return base + 5.0;
      case 'female':
        return base - 161.0;
      default:
        return base - 78.0;
    }
  }

  /// Physical activity level multiplier.
  static double getActivityMultiplier(
    String activityLevel, {
    int weeklyWorkoutDays = 4,
  }) {
    switch (activityLevel.toLowerCase()) {
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

  /// Total Daily Energy Expenditure (TDEE).
  static double calculateTdee({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
    required String activityLevel,
    int weeklyWorkoutDays = 4,
  }) {
    final bmr = calculateBmr(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      gender: gender,
    );
    final mult = getActivityMultiplier(
      activityLevel,
      weeklyWorkoutDays: weeklyWorkoutDays,
    );
    return bmr * mult;
  }

  /// Calculates personalized daily nutrition targets based on profile parameters.
  static NutritionGoalTargets calculateTargetsFromProfile(UserProfile profile) {
    if (!profile.isProfileSetupCompleted && profile.weightKg <= 0) {
      return NutritionGoalTargets.defaultBaseline();
    }

    final tdee = calculateTdee(
      weightKg: profile.weightKg,
      heightCm: profile.heightCm,
      age: profile.age,
      gender: profile.gender,
      activityLevel: profile.activityLevel,
      weeklyWorkoutDays: profile.weeklyWorkoutDays,
    );

    int calories;
    final goal = profile.fitnessGoal.toLowerCase();
    final pace = profile.targetPaceKgPerWeek > 0
        ? profile.targetPaceKgPerWeek
        : 0.5;

    // 1 kg of fat roughly corresponds to 7700 kcal deficit/surplus
    // Pace of 0.5 kg/week = ~550 kcal/day adjustment
    final dailyDelta = (pace * 1100).round();

    if (goal == 'lose_weight' || goal == 'fat_loss') {
      calories = (tdee - dailyDelta).round().clamp(1200, 4500);
    } else if (goal == 'gain_weight' ||
        goal == 'build_muscle' ||
        goal == 'hypertrophy') {
      calories = (tdee + (dailyDelta * 0.7).round()).round().clamp(1800, 5500);
    } else {
      calories = tdee.round().clamp(1500, 4500);
    }

    // Macronutrient distribution based on diet type
    final weightKg = profile.weightKg;
    int proteinGrams;
    int fatsGrams;
    int carbsGrams;

    final diet = profile.dietType.toLowerCase();
    if (diet == 'high_protein') {
      // 2.2g protein per kg of body weight
      proteinGrams = (weightKg * 2.2).round().clamp(80, 260);
      fatsGrams = ((calories * 0.25) / 9.0).round().clamp(35, 120);
      final remainingKcal = calories - (proteinGrams * 4) - (fatsGrams * 9);
      carbsGrams = (remainingKcal / 4.0).round().clamp(40, 500);
    } else if (diet == 'low_carb' || diet == 'keto') {
      // 20% protein, 70% fats, 10% carbs
      proteinGrams = ((calories * 0.22) / 4.0).round().clamp(70, 240);
      fatsGrams = ((calories * 0.68) / 9.0).round().clamp(50, 200);
      final remainingKcal = calories - (proteinGrams * 4) - (fatsGrams * 9);
      carbsGrams = (remainingKcal / 4.0).round().clamp(15, 120);
    } else if (diet == 'vegan' || diet == 'vegetarian') {
      // 1.8g protein per kg, 25% fats, remainder carbs
      proteinGrams = (weightKg * 1.8).round().clamp(60, 220);
      fatsGrams = ((calories * 0.25) / 9.0).round().clamp(35, 110);
      final remainingKcal = calories - (proteinGrams * 4) - (fatsGrams * 9);
      carbsGrams = (remainingKcal / 4.0).round().clamp(60, 550);
    } else {
      // Balanced standard: 2.0g/kg protein, 25% fats, remainder carbs
      proteinGrams = (weightKg * 2.0).round().clamp(70, 240);
      fatsGrams = ((calories * 0.25) / 9.0).round().clamp(40, 120);
      final remainingKcal = calories - (proteinGrams * 4) - (fatsGrams * 9);
      carbsGrams = (remainingKcal / 4.0).round().clamp(50, 500);
    }

    final targetWater = (profile.targetWaterMl > 0)
        ? profile.targetWaterMl
        : (weightKg * 35.0).round().clamp(2000, 4500);

    final burnTarget = (profile.dailyWorkoutMinutes > 0)
        ? (profile.dailyWorkoutMinutes * 7.5).round().clamp(150, 1000)
        : 350;

    return NutritionGoalTargets(
      dailyCalories: calories,
      proteinGrams: proteinGrams,
      carbsGrams: carbsGrams,
      fatsGrams: fatsGrams,
      targetWaterMl: targetWater,
      dailyCaloriesBurnTarget: burnTarget,
      isPersonalized: true,
      formulaDescription: 'Mifflin-St Jeor TDEE ($tdee kcal) with $goal goal',
    );
  }

  /// Checks whether an ingredient or drink name represents pure water or zero-calorie hydration/drinks.
  static bool isWaterOrZeroCalorie(String name) {
    final lower = name.toLowerCase().trim();
    if (lower.isEmpty) return false;

    // Direct matches
    if (lower == 'water' ||
        lower == 'pani' ||
        lower == 'paani' ||
        lower == 'aqua' ||
        lower == 'h2o' ||
        lower == 'plain water' ||
        lower.contains('drinking water') ||
        lower.contains('mineral water') ||
        lower.contains('tap water') ||
        lower.contains('ice water') ||
        lower.contains('boiled water') ||
        lower.contains('warm water') ||
        lower.contains('cold water') ||
        lower.contains('sparkling water') ||
        lower.contains('soda water') ||
        lower.contains('club soda') ||
        lower.contains('diet coke') ||
        lower.contains('coke zero') ||
        lower.contains('diet pepsi') ||
        lower.contains('diet soda') ||
        lower.contains('zero calorie') ||
        lower.contains('zero sugar')) {
      return true;
    }

    final tokens = lower.split(RegExp(r'[\s,_\-\/\(\)]+'));
    return tokens.contains('water') ||
        tokens.contains('pani') ||
        tokens.contains('paani');
  }

  /// Calculates accurate physiological calories using 4-4-9 Atwater factors:
  /// Protein: 4 kcal/g, Carbohydrates: 4 kcal/g, Fats: 9 kcal/g.
  /// Reconciles reported calories against physical macronutrient boundaries.
  static double calculateAccurateCalories({
    required double proteinGrams,
    required double carbsGrams,
    required double fatGrams,
    double? reportedCalories,
    bool isZeroCalorie = false,
  }) {
    if (isZeroCalorie) return 0.0;

    final p = proteinGrams < 0 ? 0.0 : proteinGrams;
    final c = carbsGrams < 0 ? 0.0 : carbsGrams;
    final f = fatGrams < 0 ? 0.0 : fatGrams;

    if (p == 0.0 && c == 0.0 && f == 0.0) {
      return 0.0;
    }

    final atwater = (p * 4.0) + (c * 4.0) + (f * 9.0);
    final theoreticalMin =
        (p * 4.0) + (f * 9.0); // If all carbs were non-digestible fiber

    if (reportedCalories == null || reportedCalories <= 0) {
      return double.parse(atwater.toStringAsFixed(1));
    }

    // Allow minor dietary fiber variation (up to ~15% below theoretical max),
    // but reconcile if physically impossible (e.g. > atwater * 1.15 + 5 or < theoreticalMin * 0.8 - 5)
    if (reportedCalories > (atwater * 1.15 + 5.0) ||
        reportedCalories < (theoreticalMin * 0.8 - 5.0)) {
      return double.parse(atwater.toStringAsFixed(1));
    }

    return double.parse(reportedCalories.toStringAsFixed(1));
  }

  /// Sanitizes per-100g nutritional facts:
  /// - Enforces 0 macros and 0 calories for water and zero-calorie items
  /// - Clamps negative values to 0
  /// - Ensures sum of macros per 100g does not exceed 100g
  /// - Enforces 900 kcal/100g upper bound
  /// - Calculates accurate calories using Atwater formula when missing or aberrant
  static ({
    double protein,
    double carbs,
    double fats,
    double calories,
  }) sanitizePer100gMacros({
    required String name,
    required double proteinPer100g,
    required double carbsPer100g,
    required double fatsPer100g,
    required double caloriesPer100g,
  }) {
    if (isWaterOrZeroCalorie(name)) {
      return (protein: 0.0, carbs: 0.0, fats: 0.0, calories: 0.0);
    }

    double p = proteinPer100g < 0 ? 0.0 : proteinPer100g;
    double c = carbsPer100g < 0 ? 0.0 : carbsPer100g;
    double f = fatsPer100g < 0 ? 0.0 : fatsPer100g;
    double cal = caloriesPer100g < 0 ? 0.0 : caloriesPer100g;

    // Physical constraint: protein + carbs + fat cannot exceed 100g per 100g
    final macroSum = p + c + f;
    if (macroSum > 100.0) {
      final factor = 98.0 / macroSum;
      p = double.parse((p * factor).toStringAsFixed(1));
      c = double.parse((c * factor).toStringAsFixed(1));
      f = double.parse((f * factor).toStringAsFixed(1));
    }

    // Enforce 900 kcal/100g pure fat upper bound
    if (cal > 900.0) {
      cal = 900.0;
    }

    cal = calculateAccurateCalories(
      proteinGrams: p,
      carbsGrams: c,
      fatGrams: f,
      reportedCalories: cal,
    );

    return (
      protein: double.parse(p.toStringAsFixed(1)),
      carbs: double.parse(c.toStringAsFixed(1)),
      fats: double.parse(f.toStringAsFixed(1)),
      calories: double.parse(cal.toStringAsFixed(1)),
    );
  }

  /// Calculates nutritional values for a specified quantity in grams.
  ///
  /// Formula: $(per100g * quantityGrams) / 100.0$
  static double calculateNutrient({
    required double per100g,
    required double quantityGrams,
  }) {
    if (per100g <= 0 || quantityGrams <= 0) return 0.0;
    return (per100g * quantityGrams) / 100.0;
  }

  /// Calculates integer rounded calories for a specified quantity in grams.
  static int calculateCalories({
    required double caloriesPer100g,
    required double quantityGrams,
  }) {
    return calculateNutrient(
      per100g: caloriesPer100g,
      quantityGrams: quantityGrams,
    ).round();
  }

  /// Computes day energy balance.
  ///
  /// [caloriesConsumed]: Sum of all logged meals.
  /// [workoutCaloriesBurned]: Calories from completed verified workouts.
  /// [manualCaloriesBurned]: Separate manual calorie adjustments.
  /// [targetCalories]: Daily goal target calories.
  ///
  /// Returns a map with totalBurned, netCalories, and remainingCalories.
  static Map<String, int> computeEnergyBalance({
    required int caloriesConsumed,
    required int workoutCaloriesBurned,
    required int manualCaloriesBurned,
    required int targetCalories,
  }) {
    final totalBurned = workoutCaloriesBurned + manualCaloriesBurned;
    // Net calories = Intake - Outflow from workouts & manual activities
    final netCalories = caloriesConsumed - totalBurned;
    // Remaining = Target - Intake + Burned
    final remainingCalories = targetCalories - caloriesConsumed + totalBurned;

    return {
      'totalBurned': totalBurned,
      'netCalories': netCalories,
      'remainingCalories': remainingCalories,
    };
  }
}
