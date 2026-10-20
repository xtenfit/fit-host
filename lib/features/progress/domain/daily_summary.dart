import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../workouts/presentation/controllers/workout_providers.dart';
import '../../nutrition/presentation/controllers/nutrition_controller.dart';
import '../../steps/presentation/controllers/step_controller.dart';

class DailySummary {
  final DateTime date;
  final int stepCount;
  final double distanceKm;
  final int activeCaloriesBurned;
  final int waterGlasses;
  final int completedWorkouts;
  final int totalWorkoutMinutes;
  final double totalVolumeKg;

  const DailySummary({
    required this.date,
    this.stepCount = 0,
    this.distanceKm = 0.0,
    this.activeCaloriesBurned = 0,
    this.waterGlasses = 0,
    this.completedWorkouts = 0,
    this.totalWorkoutMinutes = 0,
    this.totalVolumeKg = 0.0,
  });

  DailySummary copyWith({
    DateTime? date,
    int? stepCount,
    double? distanceKm,
    int? activeCaloriesBurned,
    int? waterGlasses,
    int? completedWorkouts,
    int? totalWorkoutMinutes,
    double? totalVolumeKg,
  }) {
    return DailySummary(
      date: date ?? this.date,
      stepCount: stepCount ?? this.stepCount,
      distanceKm: distanceKm ?? this.distanceKm,
      activeCaloriesBurned: activeCaloriesBurned ?? this.activeCaloriesBurned,
      waterGlasses: waterGlasses ?? this.waterGlasses,
      completedWorkouts: completedWorkouts ?? this.completedWorkouts,
      totalWorkoutMinutes: totalWorkoutMinutes ?? this.totalWorkoutMinutes,
      totalVolumeKg: totalVolumeKg ?? this.totalVolumeKg,
    );
  }
}

final dailySummaryProvider = Provider<DailySummary>((ref) {
  final today = DateTime.now();
  final workouts = ref.watch(workoutsStreamProvider).value ?? [];
  final nutrition = ref.watch(nutritionProvider);
  final steps = ref.watch(stepControllerProvider);

  final todayWorkouts = workouts.where((w) {
    return w.startedAt.year == today.year &&
        w.startedAt.month == today.month &&
        w.startedAt.day == today.day &&
        w.status == 'completed';
  }).toList();

  final totalMinutes = todayWorkouts.fold(
      0, (sum, w) => sum + (w.durationSeconds ~/ 60));
  final totalVolume = todayWorkouts.fold(
      0.0, (sum, w) => sum + w.totalVolumeKg);

  return DailySummary(
    date: DateTime(today.year, today.month, today.day),
    stepCount: steps.todaySteps,
    distanceKm: steps.distanceKm,
    activeCaloriesBurned: steps.calories + (todayWorkouts.length * 150),
    waterGlasses: nutrition.waterGlasses,
    completedWorkouts: todayWorkouts.length,
    totalWorkoutMinutes: totalMinutes,
    totalVolumeKg: totalVolume,
  );
});
