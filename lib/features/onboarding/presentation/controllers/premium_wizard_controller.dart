import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/onboarding_models.dart';
import '../../domain/repositories/onboarding_repository.dart';
import 'onboarding_controller.dart';
import '../../../profile/presentation/controllers/user_profile_controller.dart';
import '../../../../core/services/startup_gate_service.dart';

class PremiumWizardState {
  final int currentStep; // 1..16, 17=Account Decision
  final OnboardingState draft; // in-progress profile
  final bool isSaving;
  final bool lastStepSaved;

  const PremiumWizardState({
    this.currentStep = 1,
    this.draft = const OnboardingState(),
    this.isSaving = false,
    this.lastStepSaved = false,
  });

  PremiumWizardState copyWith({
    int? currentStep,
    OnboardingState? draft,
    bool? isSaving,
    bool? lastStepSaved,
  }) {
    return PremiumWizardState(
      currentStep: currentStep ?? this.currentStep,
      draft: draft ?? this.draft,
      isSaving: isSaving ?? this.isSaving,
      lastStepSaved: lastStepSaved ?? this.lastStepSaved,
    );
  }
}

class PremiumWizardController extends AsyncNotifier<PremiumWizardState> {
  late final OnboardingRepository _repository;

  @override
  Future<PremiumWizardState> build() async {
    _repository = ref.watch(onboardingRepositoryProvider);
    final savedDraft = await _repository.loadDraft();
    if (savedDraft != null) {
      return PremiumWizardState(
        currentStep: savedDraft.currentStep.clamp(1, 17),
        draft: savedDraft,
        lastStepSaved: true,
      );
    }
    return const PremiumWizardState();
  }

  Future<void> goToStep(int n) async {
    final cur = state.value ?? const PremiumWizardState();
    final updatedDraft = cur.draft.copyWith(
      currentStep: n.clamp(1, 17),
      isGenderBranch: false,
    );
    state = AsyncData(cur.copyWith(
      currentStep: n.clamp(1, 17),
      draft: updatedDraft,
      isSaving: false,
      lastStepSaved: true,
    ));
    await _repository.saveDraft(updatedDraft);
  }

  Future<void> nextStep() async {
    final cur = state.value ?? const PremiumWizardState();
    final step = cur.currentStep;
    final draft = cur.draft;

    int next = step + 1;
    bool isBranch = false;

    // Step 6 (Main Goal) -> if Maintain, skip step 7 (timeline)
    if (step == 6) {
      if (draft.goals.contains('maintain') || draft.goals.contains('maintain_weight')) {
        next = 8;
      }
    } else if (step == 8 && !draft.isGenderBranch) {
      // Step 8 (Focus Areas) -> check gender branching
      if (draft.gender == 'male' || draft.gender == 'female') {
        next = 8;
        isBranch = true;
      } else {
        next = 9;
      }
    } else if (step == 8 && draft.isGenderBranch) {
      next = 9;
      isBranch = false;
    } else if (step >= 17) {
      return;
    }

    final updatedDraft = draft.copyWith(
      currentStep: next.clamp(1, 17),
      isGenderBranch: isBranch,
    );

    state = AsyncData(cur.copyWith(
      currentStep: next.clamp(1, 17),
      draft: updatedDraft,
      lastStepSaved: true,
    ));

    await _repository.saveDraft(updatedDraft);
  }

  Future<void> prevStep() async {
    final cur = state.value ?? const PremiumWizardState();
    final step = cur.currentStep;
    final draft = cur.draft;

    if (step <= 1 && !draft.isGenderBranch) return;

    int prev = step - 1;
    bool isBranch = false;

    if (step == 8 && draft.isGenderBranch) {
      prev = 8;
      isBranch = false;
    } else if (step == 9) {
      if (draft.gender == 'male' || draft.gender == 'female') {
        prev = 8;
        isBranch = true;
      } else {
        prev = 8;
      }
    } else if (step == 8) {
      if (draft.goals.contains('maintain') || draft.goals.contains('maintain_weight')) {
        prev = 6;
      } else {
        prev = 7;
      }
    }

    final updatedDraft = draft.copyWith(
      currentStep: prev.clamp(1, 17),
      isGenderBranch: isBranch,
    );

    state = AsyncData(cur.copyWith(
      currentStep: prev.clamp(1, 17),
      draft: updatedDraft,
      lastStepSaved: true,
    ));

    await _repository.saveDraft(updatedDraft);
  }

  Future<void> updateDraft(OnboardingState Function(OnboardingState) mutate) async {
    final cur = state.value ?? const PremiumWizardState();
    final updated = mutate(cur.draft);
    state = AsyncData(cur.copyWith(
      draft: updated,
      currentStep: updated.currentStep,
      isSaving: false,
    ));
    await _repository.saveDraft(updated);
  }

  Future<void> saveCurrentStep() async {
    final cur = state.value;
    if (cur != null) {
      await _repository.saveDraft(cur.draft);
      state = AsyncData(cur.copyWith(lastStepSaved: true));
    }
  }

  Future<void> complete({bool isGuest = true}) async {
    final cur = state.value ?? const PremiumWizardState();
    final finalDraft = cur.draft.copyWith(
      isCompleted: true,
      isGuest: isGuest,
      currentStep: 17,
    );

    state = AsyncData(cur.copyWith(
      draft: finalDraft,
      isSaving: true,
    ));

    await _repository.completeOnboarding(finalDraft);

    // Synchronize to UserProfile
    String goal = 'maintain_weight';
    if (finalDraft.goals.contains('lose_weight')) {
      goal = 'lose_weight';
    } else if (finalDraft.goals.contains('build_muscle')) {
      goal = 'gain_weight';
    } else if (finalDraft.goals.contains('recomp')) {
      goal = 'maintain_weight';
    }

    String diet = 'balanced';
    if (finalDraft.dietPreference == 'vegan') {
      diet = 'vegan';
    } else if (finalDraft.dietPreference == 'vegetarian') {
      diet = 'vegetarian';
    } else if (finalDraft.dietPreference == 'high_protein') {
      diet = 'high_protein';
    }

    try {
      await ref.read(userProfileProvider.notifier).saveSuggestedPlan(
            name: isGuest ? 'Guest Athlete' : 'Athlete',
            age: finalDraft.age,
            gender: finalDraft.gender ?? 'male',
            heightCm: finalDraft.heightCm,
            weightKg: finalDraft.weightKg,
            targetWeightKg: finalDraft.targetWeightKg,
            fitnessGoal: goal,
            dietType: diet,
            weeklyWorkoutDays: finalDraft.workoutDaysPerWeek,
            dailyWorkoutMinutes: finalDraft.sessionDurationMinutes,
          );
    } catch (_) {}

    try {
      final gate = ref.read(startupGateServiceProvider);
      await gate.setFirstLaunchCompleted(true);
      if (isGuest) {
        await gate.setAuthDecisionMade(true);
      }
    } catch (_) {}

    state = AsyncData(cur.copyWith(
      draft: finalDraft,
      isSaving: false,
      lastStepSaved: true,
    ));
  }
}

final premiumWizardControllerProvider =
    AsyncNotifierProvider<PremiumWizardController, PremiumWizardState>(
  PremiumWizardController.new,
);
