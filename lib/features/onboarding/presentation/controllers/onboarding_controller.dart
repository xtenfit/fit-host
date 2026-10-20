import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/onboarding_models.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../../data/repositories/onboarding_repository_impl.dart';
import '../../../profile/presentation/controllers/user_profile_controller.dart';
import 'package:fit_host/core/services/startup_gate_service.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepositoryImpl();
});

class OnboardingNotifier extends Notifier<OnboardingState> {
  late final OnboardingRepository _repository;

  @override
  OnboardingState build() {
    _repository = ref.read(onboardingRepositoryProvider);
    _loadInitialDraft();
    return const OnboardingState();
  }

  Future<void> _loadInitialDraft() async {
    final draft = await _repository.loadDraft();
    if (draft != null) {
      state = draft;
    }
  }

  Future<void> _autoSave() async {
    await _repository.saveDraft(state);
  }

  void nextStep() {
    final step = state.currentStep;
    int next = step + 1;
    bool isBranch = false;

    if (step == 6 &&
        (state.goals.contains('maintain') ||
            state.goals.contains('maintain_weight'))) {
      next = 8;
    } else if (step == 8 && !state.isGenderBranch) {
      if (state.gender == 'male' || state.gender == 'female') {
        next = 8;
        isBranch = true;
      } else {
        next = 9;
      }
    } else if (step == 8 && state.isGenderBranch) {
      next = 9;
      isBranch = false;
    } else if (step >= 17) {
      return;
    }

    state = state.copyWith(
      currentStep: next.clamp(1, 17),
      isGenderBranch: isBranch,
    );
    _autoSave();
  }

  void previousStep() {
    final step = state.currentStep;
    if (step <= 1 && !state.isGenderBranch) return;

    int prev = step - 1;
    bool isBranch = false;

    if (step == 8 && state.isGenderBranch) {
      prev = 8;
      isBranch = false;
    } else if (step == 9) {
      if (state.gender == 'male' || state.gender == 'female') {
        prev = 8;
        isBranch = true;
      } else {
        prev = 8;
      }
    } else if (step == 8) {
      if (state.goals.contains('maintain') ||
          state.goals.contains('maintain_weight')) {
        prev = 6;
      } else {
        prev = 7;
      }
    }

    state = state.copyWith(
      currentStep: prev.clamp(1, 17),
      isGenderBranch: isBranch,
    );
    _autoSave();
  }

  void skipStep() {
    nextStep();
  }

  void jumpToStep(int step) {
    state = state.copyWith(
      currentStep: step.clamp(1, 17),
      isGenderBranch: false,
    );
    _autoSave();
  }

  void jumpToGenderBranch() {
    state = state.copyWith(
      currentStep: 8,
      isGenderBranch: true,
    );
    _autoSave();
  }

  void setGender(String? gender) {
    state = state.copyWith(gender: gender);
    _autoSave();
  }

  void toggleFocusArea(String area) {
    final list = List<String>.from(state.focusAreas);
    if (list.contains(area)) {
      if (list.length > 1) list.remove(area);
    } else {
      list.add(area);
    }
    state = state.copyWith(focusAreas: list);
    _autoSave();
  }

  void toggleGoal(String goal) {
    final list = List<String>.from(state.goals);
    if (list.contains(goal)) {
      if (list.length > 1) list.remove(goal);
    } else {
      list.add(goal);
    }
    state = state.copyWith(goals: list);
    _autoSave();
  }

  void toggleMotivation(String motivation) {
    final list = List<String>.from(state.motivations);
    if (list.contains(motivation)) {
      if (list.length > 1) list.remove(motivation);
    } else {
      list.add(motivation);
    }
    state = state.copyWith(motivations: list);
    _autoSave();
  }

  void setExperienceLevel(String level) {
    state = state.copyWith(experienceLevel: level);
    _autoSave();
  }

  void setWorkoutLocation(String location) {
    state = state.copyWith(workoutLocation: location);
    _autoSave();
  }

  void toggleEquipment(String item) {
    final list = List<String>.from(state.equipment);
    if (list.contains(item)) {
      list.remove(item);
    } else {
      list.add(item);
    }
    state = state.copyWith(equipment: list);
    _autoSave();
  }

  void setSessionDuration(int minutes) {
    state = state.copyWith(sessionDurationMinutes: minutes);
    _autoSave();
  }

  void setWorkoutDaysPerWeek(int days) {
    state = state.copyWith(workoutDaysPerWeek: days);
    _autoSave();
  }

  void updatePhysicalProfile({
    int? age,
    double? heightCm,
    double? weightKg,
    double? targetWeightKg,
    bool? useMetricUnits,
  }) {
    state = state.copyWith(
      age: age ?? state.age,
      heightCm: heightCm ?? state.heightCm,
      weightKg: weightKg ?? state.weightKg,
      targetWeightKg: targetWeightKg ?? state.targetWeightKg,
      useMetricUnits: useMetricUnits ?? state.useMetricUnits,
    );
    _autoSave();
  }

  void setDietPreference(String diet) {
    state = state.copyWith(dietPreference: diet);
    _autoSave();
  }

  void setAllergies(String allergies) {
    state = state.copyWith(allergies: allergies);
    _autoSave();
  }

  void setMealsPerDay(int count) {
    List<OnboardingMealSchedule> schedules;
    if (count == 2) {
      schedules = const [
        OnboardingMealSchedule(name: 'Brunch', time: '10:30 AM'),
        OnboardingMealSchedule(name: 'Dinner', time: '07:00 PM'),
      ];
    } else if (count == 3) {
      schedules = const [
        OnboardingMealSchedule(name: 'Breakfast', time: '08:30 AM'),
        OnboardingMealSchedule(name: 'Lunch', time: '01:00 PM'),
        OnboardingMealSchedule(name: 'Dinner', time: '07:30 PM'),
      ];
    } else if (count == 4) {
      schedules = const [
        OnboardingMealSchedule(name: 'Breakfast', time: '08:00 AM'),
        OnboardingMealSchedule(name: 'Lunch', time: '12:30 PM'),
        OnboardingMealSchedule(name: 'Snack / Pre-workout', time: '04:30 PM'),
        OnboardingMealSchedule(name: 'Dinner', time: '08:00 PM'),
      ];
    } else if (count == 5) {
      schedules = const [
        OnboardingMealSchedule(name: 'Breakfast', time: '07:30 AM'),
        OnboardingMealSchedule(name: 'Mid-Morning Snack', time: '10:30 AM'),
        OnboardingMealSchedule(name: 'Lunch', time: '01:30 PM'),
        OnboardingMealSchedule(name: 'Afternoon Fuel', time: '05:00 PM'),
        OnboardingMealSchedule(name: 'Dinner', time: '08:30 PM'),
      ];
    } else {
      schedules = const [
        OnboardingMealSchedule(name: 'Meal 1 (Breakfast)', time: '07:00 AM'),
        OnboardingMealSchedule(name: 'Meal 2 (Snack)', time: '10:00 AM'),
        OnboardingMealSchedule(name: 'Meal 3 (Lunch)', time: '01:00 PM'),
        OnboardingMealSchedule(name: 'Meal 4 (Pre-Workout)', time: '04:00 PM'),
        OnboardingMealSchedule(name: 'Meal 5 (Post-Workout)', time: '07:00 PM'),
        OnboardingMealSchedule(name: 'Meal 6 (Dinner)', time: '09:30 PM'),
      ];
    }
    state = state.copyWith(mealsPerDay: count, mealSchedules: schedules);
    _autoSave();
  }

  void updateMealScheduleItem(int index, String name, String time) {
    if (index >= 0 && index < state.mealSchedules.length) {
      final list = List<OnboardingMealSchedule>.from(state.mealSchedules);
      list[index] = OnboardingMealSchedule(name: name, time: time);
      state = state.copyWith(mealSchedules: list);
      _autoSave();
    }
  }

  void setDailyWater(int ml) {
    state = state.copyWith(dailyWaterMl: ml);
    _autoSave();
  }

  void setWaterUnit(String unit) {
    state = state.copyWith(waterUnit: unit);
    _autoSave();
  }

  void setDrinkingFrequency(String freq) {
    state = state.copyWith(drinkingFrequency: freq);
    _autoSave();
  }

  void setWaterReminders(bool enable) {
    state = state.copyWith(enableWaterReminders: enable);
    _autoSave();
  }

  void setQuietHours(String start, String end) {
    state = state.copyWith(quietHoursStart: start, quietHoursEnd: end);
    _autoSave();
  }

  void setActivityLevel(String level) {
    state = state.copyWith(activityLevel: level);
    _autoSave();
  }

  void setSleepHours(double hours) {
    state = state.copyWith(sleepHours: hours);
    _autoSave();
  }

  void setWorkoutTimePreference(String timePref) {
    state = state.copyWith(workoutTimePreference: timePref);
    _autoSave();
  }

  void setBeveragePreferences(String prefs) {
    state = state.copyWith(beveragePreferences: prefs);
    _autoSave();
  }

  void toggleGenderSpecificGoal(String goal) {
    final list = List<String>.from(state.genderSpecificGoals);
    if (list.contains(goal)) {
      list.remove(goal);
    } else {
      list.add(goal);
    }
    state = state.copyWith(genderSpecificGoals: list);
    _autoSave();
  }

  void updateBodyComposition({
    double? bodyFatPercentage,
    double? waistCm,
    double? hipCm,
    double? chestCm,
    double? neckCm,
  }) {
    state = state.copyWith(
      bodyFatPercentage: bodyFatPercentage ?? state.bodyFatPercentage,
      waistCm: waistCm ?? state.waistCm,
      hipCm: hipCm ?? state.hipCm,
      chestCm: chestCm ?? state.chestCm,
      neckCm: neckCm ?? state.neckCm,
    );
    _autoSave();
  }

  void setTargetTimeline({double? targetWeightKg, int? targetWeeks}) {
    state = state.copyWith(
      targetWeightKg: targetWeightKg ?? state.targetWeightKg,
      targetWeeks: targetWeeks ?? state.targetWeeks,
    );
    _autoSave();
  }

  void toggleWorkoutLocation(String location) {
    final list = List<String>.from(state.workoutLocations);
    if (list.contains(location)) {
      if (list.length > 1) list.remove(location);
    } else {
      list.add(location);
    }
    state = state.copyWith(
      workoutLocations: list,
      workoutLocation: list.isNotEmpty ? list.first : 'gym',
    );
    _autoSave();
  }

  void toggleWeekday(int dayIndex) {
    final list = List<int>.from(state.selectedWeekdays);
    if (list.contains(dayIndex)) {
      if (list.length > 1) list.remove(dayIndex);
    } else {
      list.add(dayIndex);
      list.sort();
    }
    state = state.copyWith(
      selectedWeekdays: list,
      workoutDaysPerWeek: list.length,
      usesEveryDay: list.length == 7,
    );
    _autoSave();
  }

  void setDaysPerWeekSlider(int days) {
    final clamped = days.clamp(1, 7);
    final autoSelected = List<int>.generate(clamped, (i) => i);
    state = state.copyWith(
      workoutDaysPerWeek: clamped,
      selectedWeekdays: autoSelected,
      usesEveryDay: clamped == 7,
    );
    _autoSave();
  }

  void setEveryDaySchedule(bool everyDay) {
    if (everyDay) {
      state = state.copyWith(
        workoutDaysPerWeek: 7,
        selectedWeekdays: const [0, 1, 2, 3, 4, 5, 6],
        usesEveryDay: true,
      );
    } else {
      state = state.copyWith(
        workoutDaysPerWeek: 4,
        selectedWeekdays: const [0, 1, 2, 3],
        usesEveryDay: false,
      );
    }
    _autoSave();
  }

  void setWeeklySchedule({int? days, List<int>? weekdays, bool? usesEveryDay}) {
    state = state.copyWith(
      workoutDaysPerWeek: days ?? state.workoutDaysPerWeek,
      selectedWeekdays: weekdays ?? state.selectedWeekdays,
      usesEveryDay: usesEveryDay ?? state.usesEveryDay,
    );
    _autoSave();
  }

  void setLifestyle({
    String? activityLevel,
    double? sleepHours,
    int? workHours,
    String? stressLevel,
  }) {
    state = state.copyWith(
      activityLevel: activityLevel ?? state.activityLevel,
      sleepHours: sleepHours ?? state.sleepHours,
      workHours: workHours ?? state.workHours,
      stressLevel: stressLevel ?? state.stressLevel,
    );
    _autoSave();
  }

  void setHydrationTarget({
    int? dailyWaterMl,
    int? reminderFrequencyHours,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) {
    state = state.copyWith(
      dailyWaterMl: dailyWaterMl ?? state.dailyWaterMl,
      reminderFrequencyHours:
          reminderFrequencyHours ?? state.reminderFrequencyHours,
      quietHoursStart: quietHoursStart ?? state.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? state.quietHoursEnd,
    );
    _autoSave();
  }

  Future<void> completeOnboarding({required bool isGuest}) async {
    state = state.copyWith(isCompleted: true, isGuest: isGuest);
    await _repository.completeOnboarding(state);

    // Synchronize into UserProfile
    String goal = 'maintain_weight';
    if (state.goals.contains('lose_weight')) {
      goal = 'lose_weight';
    } else if (state.goals.contains('build_muscle')) {
      goal = 'gain_weight';
    } else if (state.goals.contains('recomp')) {
      goal = 'maintain_weight';
    }

    String diet = 'balanced';
    if (state.dietPreference == 'vegan') {
      diet = 'vegan';
    } else if (state.dietPreference == 'vegetarian') {
      diet = 'vegetarian';
    } else if (state.dietPreference == 'high_protein') {
      diet = 'high_protein';
    }

    try {
      await ref.read(userProfileProvider.notifier).saveSuggestedPlan(
            name: isGuest ? 'Guest Athlete' : 'Athlete',
            age: state.age,
            gender: state.gender ?? 'male',
            heightCm: state.heightCm,
            weightKg: state.weightKg,
            targetWeightKg: state.targetWeightKg,
            fitnessGoal: goal,
            dietType: diet,
            weeklyWorkoutDays: state.workoutDaysPerWeek,
            dailyWorkoutMinutes: state.sessionDurationMinutes,
          );
    } catch (_) {}

    // Persist startup gate flags in FlutterSecureStorage
    try {
      final gate = ref.read(startupGateServiceProvider);
      await gate.setFirstLaunchCompleted(true);
      if (isGuest) {
        await gate.setAuthDecisionMade(true);
      }
    } catch (_) {}
  }

  Future<void> reset() async {
    state = const OnboardingState();
    await _repository.clearDraft();
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
  OnboardingNotifier.new,
);
