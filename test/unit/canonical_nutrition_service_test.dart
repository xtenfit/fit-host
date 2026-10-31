import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/nutrition/domain/services/nutrition_calculation_service.dart';
import 'package:fit_host/features/profile/domain/models/user_profile.dart';

void main() {
  group('Canonical Nutrition Calculation Service Tests', () {
    test(
      'Mifflin-St Jeor formula calculates exact BMR for males, females, and neutral',
      () {
        // Male: 10 * 75 + 6.25 * 180 - 5 * 25 + 5 = 750 + 1125 - 125 + 5 = 1755
        final maleBmr = NutritionCalculationService.calculateBmr(
          weightKg: 75.0,
          heightCm: 180.0,
          age: 25,
          gender: 'male',
        );
        expect(maleBmr, equals(1755.0));

        // Female: 10 * 60 + 6.25 * 165 - 5 * 30 - 161 = 600 + 1031.25 - 150 - 161 = 1320.25
        final femaleBmr = NutritionCalculationService.calculateBmr(
          weightKg: 60.0,
          heightCm: 165.0,
          age: 30,
          gender: 'female',
        );
        expect(femaleBmr, equals(1320.25));

        // Invalid inputs fallback safely
        final invalidBmr = NutritionCalculationService.calculateBmr(
          weightKg: -5.0,
          heightCm: 0.0,
          age: 0,
          gender: 'male',
        );
        expect(invalidBmr, equals(1650.0));
      },
    );

    test('Activity multipliers follow physiological standards', () {
      expect(
        NutritionCalculationService.getActivityMultiplier('sedentary'),
        equals(1.2),
      );
      expect(
        NutritionCalculationService.getActivityMultiplier('light'),
        equals(1.375),
      );
      expect(
        NutritionCalculationService.getActivityMultiplier('moderate'),
        equals(1.55),
      );
      expect(
        NutritionCalculationService.getActivityMultiplier('very_active'),
        equals(1.725),
      );
      expect(
        NutritionCalculationService.getActivityMultiplier('athlete'),
        equals(1.9),
      );
    });

    test('TDEE correctly scales BMR with activity multiplier', () {
      final tdee = NutritionCalculationService.calculateTdee(
        weightKg: 80.0,
        heightCm: 180.0,
        age: 28,
        gender: 'male',
        activityLevel: 'moderate', // 1.55
      );
      // BMR: 10*80 + 6.25*180 - 5*28 + 5 = 800 + 1125 - 140 + 5 = 1790
      // TDEE: 1790 * 1.55 = 2774.5
      expect(tdee, closeTo(2774.5, 0.1));
    });

    test(
      'calculateTargetsFromProfile handles incomplete profile with labeled defaults',
      () {
        final incompleteProfile = UserProfile(
          id: 'guest',
          weightKg: 0.0,
          heightCm: 0.0,
          age: 0,
          isProfileSetupCompleted: false,
          updatedAt: DateTime.now(),
        );

        final targets = NutritionCalculationService.calculateTargetsFromProfile(
          incompleteProfile,
        );
        expect(targets.isPersonalized, isFalse);
        expect(targets.dailyCalories, equals(2250));
        expect(targets.proteinGrams, equals(145));
        expect(targets.carbsGrams, equals(250));
        expect(targets.fatsGrams, equals(60));
      },
    );

    test(
      'calculateTargetsFromProfile calculates personalized targets with deficit for weight loss',
      () {
        final lossProfile = UserProfile(
          id: 'user_1',
          weightKg: 80.0,
          heightCm: 180.0,
          age: 28,
          gender: 'male',
          fitnessGoal: 'lose_weight',
          activityLevel: 'moderate',
          dietType: 'high_protein',
          targetPaceKgPerWeek: 0.5,
          isProfileSetupCompleted: true,
          updatedAt: DateTime.now(),
        );

        final targets = NutritionCalculationService.calculateTargetsFromProfile(
          lossProfile,
        );
        expect(targets.isPersonalized, isTrue);
        // TDEE ~2775. Deficit 0.5 * 1100 = 550. Calories ~ 2225
        expect(targets.dailyCalories, closeTo(2225, 50));
        // High protein: ~80 * 2.2 = 176g protein
        expect(targets.proteinGrams, closeTo(176, 10));
        expect(targets.fatsGrams, greaterThan(35));
        expect(targets.carbsGrams, greaterThan(40));
      },
    );

    test(
      'Energy balance accurately tracks net and remaining calories with manual adjustments',
      () {
        final balance = NutritionCalculationService.computeEnergyBalance(
          caloriesConsumed: 2100,
          workoutCaloriesBurned: 450,
          manualCaloriesBurned: 200, // separate manual adjustment
          targetCalories: 2500,
        );

        // totalBurned = 450 + 200 = 650
        expect(balance['totalBurned'], equals(650));
        // netCalories = 2100 - 650 = 1450
        expect(balance['netCalories'], equals(1450));
        // remainingCalories = 2500 - 2100 + 650 = 1050
        expect(balance['remainingCalories'], equals(1050));
      },
    );

    test('Strict portion scaling formula: (per100g * grams) / 100.0', () {
      expect(
        NutritionCalculationService.calculateNutrient(
          per100g: 24.0,
          quantityGrams: 150.0,
        ),
        equals(36.0),
      );
      expect(
        NutritionCalculationService.calculateCalories(
          caloriesPer100g: 165.0,
          quantityGrams: 200.0,
        ),
        equals(330),
      );
      expect(
        NutritionCalculationService.calculateNutrient(
          per100g: 0.0,
          quantityGrams: 150.0,
        ),
        equals(0.0),
      );
      expect(
        NutritionCalculationService.calculateNutrient(
          per100g: 24.0,
          quantityGrams: 0.0,
        ),
        equals(0.0),
      );
    });
  });
}
