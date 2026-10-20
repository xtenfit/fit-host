import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fit_host/core/data/profile_repository.dart';
import '../../../nutrition/presentation/controllers/nutrition_controller.dart';
import '../../../home/presentation/controllers/home_dashboard_controller.dart';

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return ref.watch(profileRepositoryProvider);
});

class UserProfileNotifier extends Notifier<UserProfile> {
  UserProfileRepository? _repository;

  void _ensureRepository() {
    _repository ??= ref.read(userProfileRepositoryProvider);
  }

  @override
  UserProfile build() {

    // Initial default profile
    final initial = UserProfile.calculateSuggestedTargets(
      name: 'Guest Athlete',
      age: 26,
      gender: 'male',
      heightCm: 175.0,
      weightKg: 72.0,
      targetWeightKg: 70.0,
      fitnessGoal: 'maintain_weight',
      dietType: 'balanced',
      weeklyWorkoutDays: 4,
      dailyWorkoutMinutes: 45,
      isCompleted: true,
    );

    // Load saved profile asynchronously from local SQLite / SecureStorage
    _loadFromStorage();

    return initial;
  }

  Future<void> _loadFromStorage() async {
    try {
      _ensureRepository();
      final saved = await _repository!.loadProfile();
      state = saved;
      _propagateToServices(saved);
    } catch (_) {}
  }

  void _propagateToServices(UserProfile profile) {
    try {
      // Sync targets with Nutrition provider
      ref.read(nutritionProvider.notifier).syncWithProfile(
            calories: profile.dailyCaloriesTarget,
            protein: profile.targetProteinGrams,
            carbs: profile.targetCarbsGrams,
            fat: profile.targetFatsGrams,
            waterGlasses: (profile.targetWaterMl / 250).round().clamp(6, 16),
          );

      // Sync active diet routine name with Home Dashboard
      ref
          .read(homeDashboardProvider.notifier)
          .setDietRoutine(profile.dietTypeTitle);
    } catch (_) {}
  }

  Future<void> updateProfile(UserProfile newProfile) async {
    state = newProfile;
    _ensureRepository();
    await _repository!.saveProfile(newProfile);
    _propagateToServices(newProfile);
  }

  Future<void> saveSuggestedPlan({
    required String name,
    required int age,
    required String gender,
    required double heightCm,
    required double weightKg,
    double? targetWeightKg,
    required String fitnessGoal,
    required String dietType,
    int weeklyWorkoutDays = 4,
    int dailyWorkoutMinutes = 45,
    String? customTargetNote,
  }) async {
    final suggested = UserProfile.calculateSuggestedTargets(
      name: name,
      age: age,
      gender: gender,
      heightCm: heightCm,
      weightKg: weightKg,
      targetWeightKg: targetWeightKg,
      fitnessGoal: fitnessGoal,
      dietType: dietType,
      weeklyWorkoutDays: weeklyWorkoutDays,
      dailyWorkoutMinutes: dailyWorkoutMinutes,
      customTargetNote: customTargetNote,
      isCompleted: true,
    );
    await updateProfile(suggested);
  }

  Future<void> saveCustomPlan({
    required String name,
    required int age,
    required String gender,
    required double heightCm,
    required double weightKg,
    double? targetWeightKg,
    required String fitnessGoal,
    required String dietType,
    required int customCalories,
    required int customProtein,
    required int customCarbs,
    required int customFats,
    int weeklyWorkoutDays = 4,
    int dailyWorkoutMinutes = 45,
    String? customTargetNote,
  }) async {
    final updated = state.copyWith(
      name: name.trim().isNotEmpty ? name.trim() : 'Guest Athlete',
      age: age,
      gender: gender,
      heightCm: heightCm,
      weightKg: weightKg,
      targetWeightKg: targetWeightKg,
      fitnessGoal: fitnessGoal,
      dietType: dietType,
      targetMode: 'custom',
      dailyCaloriesTarget: customCalories.clamp(1000, 6000),
      targetProteinGrams: customProtein.clamp(30, 400),
      targetCarbsGrams: customCarbs.clamp(20, 600),
      targetFatsGrams: customFats.clamp(15, 200),
      weeklyWorkoutDays: weeklyWorkoutDays,
      dailyWorkoutMinutes: dailyWorkoutMinutes,
      dailyCaloriesBurnTarget: (dailyWorkoutMinutes * 7.5).round(),
      customTargetNote: customTargetNote,
      isProfileSetupCompleted: true,
      updatedAt: DateTime.now(),
    );
    await updateProfile(updated);
  }

  Future<void> toggleTargetMode(String mode) async {
    if (mode == 'suggested') {
      final recalculated = UserProfile.calculateSuggestedTargets(
        name: state.name,
        age: state.age,
        gender: state.gender,
        heightCm: state.heightCm,
        weightKg: state.weightKg,
        targetWeightKg: state.targetWeightKg,
        fitnessGoal: state.fitnessGoal,
        dietType: state.dietType,
        weeklyWorkoutDays: state.weeklyWorkoutDays,
        dailyWorkoutMinutes: state.dailyWorkoutMinutes,
        customTargetNote: state.customTargetNote,
      );
      await updateProfile(recalculated);
    } else {
      await updateProfile(state.copyWith(targetMode: 'custom'));
    }
  }

  Future<void> setCustomTargets({
    int? calories,
    int? protein,
    int? carbs,
    int? fats,
    int? weeklyDays,
    int? workoutMinutes,
    String? customNote,
  }) async {
    final updated = state.copyWith(
      targetMode: 'custom',
      dailyCaloriesTarget: calories ?? state.dailyCaloriesTarget,
      targetProteinGrams: protein ?? state.targetProteinGrams,
      targetCarbsGrams: carbs ?? state.targetCarbsGrams,
      targetFatsGrams: fats ?? state.targetFatsGrams,
      weeklyWorkoutDays: weeklyDays ?? state.weeklyWorkoutDays,
      dailyWorkoutMinutes: workoutMinutes ?? state.dailyWorkoutMinutes,
      dailyCaloriesBurnTarget: ((workoutMinutes ?? state.dailyWorkoutMinutes) * 7.5).round(),
      customTargetNote: customNote ?? state.customTargetNote,
      updatedAt: DateTime.now(),
    );
    await updateProfile(updated);
  }

  Future<void> recalculateSuggestedTargets() async {
    final recalculated = UserProfile.calculateSuggestedTargets(
      name: state.name,
      age: state.age,
      gender: state.gender,
      heightCm: state.heightCm,
      weightKg: state.weightKg,
      targetWeightKg: state.targetWeightKg,
      useMetricUnits: state.useMetricUnits,
      fitnessGoal: state.fitnessGoal,
      dietType: state.dietType,
      weeklyWorkoutDays: state.weeklyWorkoutDays,
      dailyWorkoutMinutes: state.dailyWorkoutMinutes,
      customTargetNote: state.customTargetNote,
      activityLevel: state.activityLevel,
      experienceLevel: state.experienceLevel,
      bodyFatPercentage: state.bodyFatPercentage,
      restingHeartRate: state.restingHeartRate,
      targetPaceKgPerWeek: state.targetPaceKgPerWeek,
      fastingProtocol: state.fastingProtocol,
      dailyStepsGoal: state.dailyStepsGoal,
      targetSleepHours: state.targetSleepHours,
      isCompleted: true,
    );
    await updateProfile(recalculated);
  }

  Future<void> resetToCleanDefault() async {
    final defaultClean = UserProfile.defaultGuest();
    await updateProfile(defaultClean);
  }

  Future<void> updateStepGoal(int stepsGoal) async {
    final updated = state.copyWith(
      dailyStepsGoal: stepsGoal,
      updatedAt: DateTime.now(),
    );
    await updateProfile(updated);
  }

  Future<void> toggleMetricUnits() async {
    final updated = state.copyWith(
      useMetricUnits: !state.useMetricUnits,
      updatedAt: DateTime.now(),
    );
    await updateProfile(updated);
  }
}

final userProfileProvider =
    NotifierProvider<UserProfileNotifier, UserProfile>(UserProfileNotifier.new);
