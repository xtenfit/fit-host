import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/onboarding/domain/models/onboarding_models.dart';
import 'package:fit_host/features/onboarding/data/repositories/onboarding_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Wizard Draft Persistence Tests', () {
    late OnboardingRepositoryImpl repository;

    setUp(() {
      repository = OnboardingRepositoryImpl();
    });

    test('Saves draft in repository and restores identical state', () async {
      const state = OnboardingState(
        currentStep: 12,
        gender: 'female',
        genderSpecificGoals: ['glute_hypertrophy', 'hourglass_shape'],
        workoutDaysPerWeek: 4,
        selectedWeekdays: [0, 2, 4, 5],
        sessionDurationMinutes: 50,
        experienceLevel: 'intermediate',
        focusAreas: ['glutes', 'legs', 'core'],
        goals: ['build_muscle', 'tone_definition'],
      );

      await repository.saveDraft(state);
      final restored = await repository.loadDraft();

      expect(restored, isNotNull);
      expect(restored!.currentStep, equals(12));
      expect(restored.gender, equals('female'));
      expect(restored.genderSpecificGoals, contains('glute_hypertrophy'));
      expect(restored.selectedWeekdays, equals([0, 2, 4, 5]));
      expect(restored.sessionDurationMinutes, equals(50));
      expect(restored.workoutDaysPerWeek, equals(4));
    });

    test('Clears draft successfully', () async {
      const state = OnboardingState(currentStep: 5, gender: 'male');
      await repository.saveDraft(state);

      await repository.clearDraft();
      final loaded = await repository.loadDraft();

      expect(loaded, isNull);
    });

    test('Completes onboarding and flags state as completed', () async {
      const state = OnboardingState(currentStep: 17, isCompleted: false);
      await repository.completeOnboarding(state);

      final isCompleted = await repository.isOnboardingCompleted();
      expect(isCompleted, isTrue);

      final loaded = await repository.loadDraft();
      expect(loaded?.isCompleted, isTrue);
    });
  });
}
