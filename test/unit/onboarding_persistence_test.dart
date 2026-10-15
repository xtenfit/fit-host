import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/onboarding/domain/models/onboarding_models.dart';
import 'package:fit_host/features/onboarding/data/repositories/onboarding_repository_impl.dart';

void main() {
  group('OnboardingState Domain & Calculation Tests', () {
    test('Calculates BMR and caloric targets safely within realistic bounds', () {
      const stateMale = OnboardingState(
        gender: 'male',
        age: 28,
        heightCm: 180,
        weightKg: 80,
        activityLevel: 'moderately_active',
        goals: ['build_muscle'],
      );

      // Estimated daily calories should be positive and bounded
      expect(stateMale.estimatedDailyCalories, greaterThanOrEqualTo(2000));
      expect(stateMale.estimatedDailyCalories, lessThanOrEqualTo(3800));
      expect(stateMale.recommendedProteinGrams, equals(160)); // 80 * 2.0
      expect(stateMale.recommendedCarbsGrams, greaterThan(150));
      expect(stateMale.recommendedFatsGrams, greaterThan(40));

      const stateFemale = OnboardingState(
        gender: 'female',
        age: 25,
        heightCm: 165,
        weightKg: 60,
        activityLevel: 'lightly_active',
        goals: ['lose_weight'],
      );

      expect(stateFemale.estimatedDailyCalories, greaterThanOrEqualTo(1400));
      expect(stateFemale.recommendedProteinGrams, equals(120)); // 60 * 2.0
    });

    test('Unit conversions between Metric and Imperial are accurate', () {
      const state = OnboardingState(
        heightCm: 182.88, // 6 feet
        weightKg: 70.0,
        targetWeightKg: 65.0,
      );

      expect(state.heightInFeet, closeTo(6.0, 0.05));
      expect(state.weightInLbs, closeTo(154.3, 0.2));
      expect(state.targetWeightInLbs, closeTo(143.3, 0.2));
    });

    test('Recommends appropriate workout split based on available days', () {
      const state3Days = OnboardingState(workoutDaysPerWeek: 3);
      expect(state3Days.recommendedWorkoutPlanName, contains('3-Day'));

      const state4Days = OnboardingState(workoutDaysPerWeek: 4);
      expect(state4Days.recommendedWorkoutPlanName, contains('4-Day'));

      const state5Days = OnboardingState(workoutDaysPerWeek: 5);
      expect(state5Days.recommendedWorkoutPlanName, contains('5-Day'));
    });

    test('Serializes to JSON and recovers identical state', () {
      const original = OnboardingState(
        currentStep: 7,
        gender: 'male',
        focusAreas: ['chest', 'back'],
        goals: ['build_muscle', 'improve_strength'],
        motivations: ['feel_confident'],
        experienceLevel: 'advanced',
        workoutLocation: 'gym',
        equipment: ['dumbbells', 'barbells', 'full_gym'],
        sessionDurationMinutes: 60,
        workoutDaysPerWeek: 5,
        age: 30,
        heightCm: 185.0,
        weightKg: 85.0,
        targetWeightKg: 82.0,
        useMetricUnits: true,
        dietPreference: 'vegan',
        allergies: 'Peanuts',
        mealsPerDay: 4,
        dailyWaterMl: 3200,
        waterUnit: 'ml',
        drinkingFrequency: 'every_1_hour',
        enableWaterReminders: true,
        activityLevel: 'very_active',
        sleepHours: 8.0,
        workoutTimePreference: 'morning',
        beveragePreferences: 'Green tea, Water',
        isCompleted: false,
        isGuest: true,
      );

      final jsonStr = original.toJsonString();
      final restored = OnboardingState.fromJsonString(jsonStr);

      expect(restored.currentStep, equals(7));
      expect(restored.gender, equals('male'));
      expect(restored.focusAreas, equals(['chest', 'back']));
      expect(restored.goals, equals(['build_muscle', 'improve_strength']));
      expect(restored.dietPreference, equals('vegan'));
      expect(restored.allergies, equals('Peanuts'));
      expect(restored.mealsPerDay, equals(4));
      expect(restored.dailyWaterMl, equals(3200));
      expect(restored.enableWaterReminders, isTrue);
      expect(restored.sleepHours, equals(8.0));
    });
  });

  group('OnboardingRepository Persistence Tests', () {
    test('Saves draft and loads draft accurately', () async {
      final repo = OnboardingRepositoryImpl();

      expect(await repo.loadDraft(), isNull);
      expect(await repo.isOnboardingCompleted(), isFalse);

      const draft = OnboardingState(
        currentStep: 4,
        gender: 'female',
        goals: ['lose_weight'],
      );

      await repo.saveDraft(draft);
      final loaded = await repo.loadDraft();
      expect(loaded, isNotNull);
      expect(loaded!.currentStep, equals(4));
      expect(loaded.gender, equals('female'));

      await repo.completeOnboarding(draft);
      expect(await repo.isOnboardingCompleted(), isTrue);

      await repo.clearDraft();
      expect(await repo.loadDraft(), isNull);
    });
  });
}
