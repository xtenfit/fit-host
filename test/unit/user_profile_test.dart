import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/profile/domain/models/user_profile.dart';
import 'package:fit_host/features/profile/data/repositories/user_profile_repository.dart';

void main() {
  group('UserProfile Domain & Scientific Calculation Tests', () {
    test('Calculates accurate suggested balanced targets for Weight Loss (Fat Loss)', () {
      final profile = UserProfile.calculateSuggestedTargets(
        name: 'Jordan',
        age: 28,
        gender: 'male',
        heightCm: 180.0,
        weightKg: 85.0,
        targetWeightKg: 78.0,
        fitnessGoal: 'lose_weight',
        dietType: 'high_protein',
        weeklyWorkoutDays: 4,
        dailyWorkoutMinutes: 45,
      );

      // Verify name & stats
      expect(profile.name, 'Jordan');
      expect(profile.age, 28);
      expect(profile.gender, 'male');
      expect(profile.heightCm, 180.0);
      expect(profile.weightKg, 85.0);
      expect(profile.targetWeightKg, 78.0);
      expect(profile.fitnessGoal, 'lose_weight');
      expect(profile.dietType, 'high_protein');
      expect(profile.targetMode, 'suggested');

      // Caloric deficit applied
      expect(profile.dailyCaloriesTarget, inInclusiveRange(1800, 2600));

      // High protein priority for muscle retention during deficit (2.2 * 85 = 187g)
      expect(profile.targetProteinGrams, inInclusiveRange(170, 200));

      // Workout targets
      expect(profile.weeklyWorkoutDays, 4);
      expect(profile.dailyWorkoutMinutes, 45);
      expect(profile.dailyCaloriesBurnTarget, (45 * 7.5).round());
    });

    test('Calculates accurate suggested balanced targets for Muscle Gain (Hypertrophy)', () {
      final profile = UserProfile.calculateSuggestedTargets(
        name: 'Samantha',
        age: 24,
        gender: 'female',
        heightCm: 165.0,
        weightKg: 58.0,
        targetWeightKg: 62.0,
        fitnessGoal: 'gain_weight',
        dietType: 'balanced',
        weeklyWorkoutDays: 5,
        dailyWorkoutMinutes: 60,
      );

      expect(profile.name, 'Samantha');
      expect(profile.gender, 'female');
      expect(profile.fitnessGoal, 'gain_weight');

      // Caloric surplus applied for hypertrophy
      expect(profile.dailyCaloriesTarget, inInclusiveRange(1900, 2700));
      expect(profile.targetProteinGrams, inInclusiveRange(110, 150));
      expect(profile.weeklyWorkoutDays, 5);
      expect(profile.dailyWorkoutMinutes, 60);
      expect(profile.dailyCaloriesBurnTarget, 450);
    });

    test('Calculates accurate suggested balanced targets for Weight Maintenance', () {
      final profile = UserProfile.calculateSuggestedTargets(
        name: 'Alex',
        age: 30,
        gender: 'male',
        heightCm: 175.0,
        weightKg: 72.0,
        fitnessGoal: 'maintain_weight',
        dietType: 'balanced',
        weeklyWorkoutDays: 3,
        dailyWorkoutMinutes: 40,
      );

      expect(profile.name, 'Alex');
      expect(profile.fitnessGoal, 'maintain_weight');
      expect(profile.dailyCaloriesTarget, inInclusiveRange(2000, 2600));
      expect(profile.targetProteinGrams, inInclusiveRange(120, 160));
    });

    test('Supports Low Carb / Keto diet macro restrictions', () {
      final profile = UserProfile.calculateSuggestedTargets(
        name: 'Chris',
        age: 35,
        gender: 'male',
        heightCm: 178.0,
        weightKg: 80.0,
        fitnessGoal: 'lose_weight',
        dietType: 'low_carb',
      );

      expect(profile.dietType, 'low_carb');
      expect(profile.targetCarbsGrams, 50); // Restricted keto ceiling
      expect(profile.targetProteinGrams, inInclusiveRange(150, 180));
      expect(profile.targetFatsGrams, inInclusiveRange(80, 150));
    });

    test('Custom Targets can be serialized to and from JSON without loss', () {
      final original = UserProfile(
        id: 'user_123',
        name: 'Samir',
        age: 29,
        gender: 'male',
        heightCm: 182.0,
        weightKg: 79.5,
        targetWeightKg: 75.0,
        useMetricUnits: true,
        fitnessGoal: 'lose_weight',
        dietType: 'high_protein',
        targetMode: 'custom',
        dailyCaloriesTarget: 2150,
        targetProteinGrams: 180,
        targetCarbsGrams: 195,
        targetFatsGrams: 55,
        targetWaterMl: 3200,
        weeklyWorkoutDays: 5,
        dailyWorkoutMinutes: 50,
        dailyCaloriesBurnTarget: 375,
        customTargetNote: 'Run 5km every Saturday morning',
        isProfileSetupCompleted: true,
        updatedAt: DateTime.now(),
      );

      final jsonStr = original.toJsonString();
      final decoded = UserProfile.fromJsonString(jsonStr);

      expect(decoded.name, original.name);
      expect(decoded.age, original.age);
      expect(decoded.gender, original.gender);
      expect(decoded.heightCm, original.heightCm);
      expect(decoded.weightKg, original.weightKg);
      expect(decoded.targetWeightKg, original.targetWeightKg);
      expect(decoded.targetMode, 'custom');
      expect(decoded.dailyCaloriesTarget, 2150);
      expect(decoded.targetProteinGrams, 180);
      expect(decoded.targetCarbsGrams, 195);
      expect(decoded.targetFatsGrams, 55);
      expect(decoded.customTargetNote, 'Run 5km every Saturday morning');
      expect(decoded.isProfileSetupCompleted, isTrue);
    });

    test('UserProfileRepository saves and loads offline profile memory cache', () async {
      final repo = UserProfileRepositoryImpl();
      final p = UserProfile.calculateSuggestedTargets(
        name: 'Offline Tester',
        age: 27,
        gender: 'female',
        heightCm: 168.0,
        weightKg: 64.0,
        fitnessGoal: 'gain_weight',
        dietType: 'vegan',
      );

      await repo.saveProfile(p);
      final loaded = await repo.loadProfile();

      expect(loaded.name, 'Offline Tester');
      expect(loaded.gender, 'female');
      expect(loaded.dietType, 'vegan');
    });
  });
}
