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
