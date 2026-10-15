import '../models/onboarding_models.dart';

abstract class OnboardingRepository {
  Future<void> saveDraft(OnboardingState state);
  Future<OnboardingState?> loadDraft();
  Future<void> clearDraft();
  Future<void> completeOnboarding(OnboardingState state);
  Future<bool> isOnboardingCompleted();
}
