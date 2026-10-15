import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/onboarding_models.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../../data/repositories/onboarding_repository_impl.dart';

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
    if (state.currentStep < 12) {
      state = state.copyWith(currentStep: state.currentStep + 1);
      _autoSave();
    }
  }

  void previousStep() {
    if (state.currentStep > 1) {
      state = state.copyWith(currentStep: state.currentStep - 1);
      _autoSave();
    }
  }

  void skipStep() {
    nextStep();
  }

  void jumpToStep(int step) {
    if (step >= 1 && step <= 12) {
      state = state.copyWith(currentStep: step);
      _autoSave();
    }
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

  Future<void> completeOnboarding({required bool isGuest}) async {
    state = state.copyWith(isCompleted: true, isGuest: isGuest);
    await _repository.completeOnboarding(state);
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
