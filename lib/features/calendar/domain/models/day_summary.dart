import 'package:flutter/foundation.dart';

@immutable
class DaySummary {
  final DateTime date;
  final int steps;
  final double distanceKm;
  final int workoutCount;
  final int workoutDurationMin;
  final int caloriesBurned;
  final int caloriesIn;
  final double proteinG;
  final double carbsG;
  final double fatsG;
  final int waterMl;
  final bool hasReminder;
  final int completedReminders;
  final int missedReminders;

  const DaySummary({
    required this.date,
    this.steps = 0,
    this.distanceKm = 0.0,
    this.workoutCount = 0,
    this.workoutDurationMin = 0,
    this.caloriesBurned = 0,
    this.caloriesIn = 0,
    this.proteinG = 0.0,
    this.carbsG = 0.0,
    this.fatsG = 0.0,
    this.waterMl = 0,
    this.hasReminder = false,
    this.completedReminders = 0,
    this.missedReminders = 0,
  });

  // Badges & Rings Helpers
  bool get hasWorkout => workoutCount > 0;
  bool get hasMealLogged => caloriesIn > 0;
  bool get hasWaterLogged => waterMl > 0;
  bool isStepsGoalMet([int goal = 10000]) => steps >= goal;
  int get netCalories => caloriesIn - caloriesBurned;
  bool get isActiveDay => hasWorkout || isStepsGoalMet() || hasMealLogged;

  int get waterGlasses => (waterMl / 250).round();

  String get formattedDistance {
    final meters = (distanceKm * 1000).round();
    if (meters < 1000) {
      return '$meters m';
    }
    return '${distanceKm.toStringAsFixed(2)} km';
  }

  DaySummary copyWith({
    DateTime? date,
    int? steps,
    double? distanceKm,
    int? workoutCount,
    int? workoutDurationMin,
    int? caloriesBurned,
    int? caloriesIn,
    double? proteinG,
    double? carbsG,
    double? fatsG,
    int? waterMl,
    bool? hasReminder,
    int? completedReminders,
    int? missedReminders,
  }) {
    return DaySummary(
      date: date ?? this.date,
      steps: steps ?? this.steps,
      distanceKm: distanceKm ?? this.distanceKm,
      workoutCount: workoutCount ?? this.workoutCount,
      workoutDurationMin: workoutDurationMin ?? this.workoutDurationMin,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      caloriesIn: caloriesIn ?? this.caloriesIn,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatsG: fatsG ?? this.fatsG,
      waterMl: waterMl ?? this.waterMl,
      hasReminder: hasReminder ?? this.hasReminder,
      completedReminders: completedReminders ?? this.completedReminders,
      missedReminders: missedReminders ?? this.missedReminders,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'steps': steps,
        'distanceKm': distanceKm,
        'workoutCount': workoutCount,
        'workoutDurationMin': workoutDurationMin,
        'caloriesBurned': caloriesBurned,
        'caloriesIn': caloriesIn,
        'proteinG': proteinG,
        'carbsG': carbsG,
        'fatsG': fatsG,
        'waterMl': waterMl,
        'hasReminder': hasReminder,
        'completedReminders': completedReminders,
        'missedReminders': missedReminders,
      };

  factory DaySummary.fromJson(Map<String, dynamic> json) {
    return DaySummary(
      date: DateTime.parse(json['date'] as String),
      steps: json['steps'] as int? ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      workoutCount: json['workoutCount'] as int? ?? 0,
      workoutDurationMin: json['workoutDurationMin'] as int? ?? 0,
      caloriesBurned: json['caloriesBurned'] as int? ?? 0,
      caloriesIn: json['caloriesIn'] as int? ?? 0,
      proteinG: (json['proteinG'] as num?)?.toDouble() ?? 0.0,
      carbsG: (json['carbsG'] as num?)?.toDouble() ?? 0.0,
      fatsG: (json['fatsG'] as num?)?.toDouble() ?? 0.0,
      waterMl: json['waterMl'] as int? ?? 0,
      hasReminder: json['hasReminder'] as bool? ?? false,
      completedReminders: json['completedReminders'] as int? ?? 0,
      missedReminders: json['missedReminders'] as int? ?? 0,
    );
  }

  factory DaySummary.fromRpc(Map<String, dynamic> json) {
    return DaySummary(
      date: DateTime.parse(json['summary_date'] as String),
      steps: json['steps'] as int? ?? 0,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      workoutCount: json['workout_count'] as int? ?? 0,
      workoutDurationMin: json['workout_duration_min'] as int? ?? 0,
      caloriesBurned: json['calories_burned'] as int? ?? 0,
      caloriesIn: json['calories_in'] as int? ?? 0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0.0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0.0,
      fatsG: (json['fats_g'] as num?)?.toDouble() ?? 0.0,
      waterMl: json['water_ml'] as int? ?? 0,
      hasReminder: json['has_reminder'] as bool? ?? false,
      completedReminders: json['completed_reminders'] as int? ?? 0,
      missedReminders: json['missed_reminders'] as int? ?? 0,
    );
  }
}

/// Aggregated totals across any custom date range
@immutable
class RangeAggregation {
  final DateTime startDate;
  final DateTime endDate;
  final List<DaySummary> dailySummaries;

  const RangeAggregation({
    required this.startDate,
    required this.endDate,
    required this.dailySummaries,
  });

  int get dayCount => dailySummaries.length;

  int get totalCaloriesIn =>
      dailySummaries.fold(0, (sum, d) => sum + d.caloriesIn);

  int get avgCaloriesIn =>
      dayCount > 0 ? (totalCaloriesIn / dayCount).round() : 0;

  int get totalCaloriesBurned =>
      dailySummaries.fold(0, (sum, d) => sum + d.caloriesBurned);

  int get netCalories => totalCaloriesIn - totalCaloriesBurned;

  double get totalProteinG =>
      dailySummaries.fold(0.0, (sum, d) => sum + d.proteinG);

  double get avgProteinG =>
      dayCount > 0 ? (totalProteinG / dayCount) : 0.0;

  double get totalCarbsG =>
      dailySummaries.fold(0.0, (sum, d) => sum + d.carbsG);

  double get avgCarbsG =>
      dayCount > 0 ? (totalCarbsG / dayCount) : 0.0;

  double get totalFatsG =>
      dailySummaries.fold(0.0, (sum, d) => sum + d.fatsG);

  double get avgFatsG =>
      dayCount > 0 ? (totalFatsG / dayCount) : 0.0;

  int get totalWaterMl =>
      dailySummaries.fold(0, (sum, d) => sum + d.waterMl);

  int get totalWorkoutsCompleted =>
      dailySummaries.fold(0, (sum, d) => sum + d.workoutCount);

  int get totalSteps =>
      dailySummaries.fold(0, (sum, d) => sum + d.steps);

  double get totalDistanceKm =>
      dailySummaries.fold(0.0, (sum, d) => sum + d.distanceKm);

  String get formattedTotalDistance {
    final meters = (totalDistanceKm * 1000).round();
    if (meters < 1000) {
      return '$meters m';
    }
    return '${totalDistanceKm.toStringAsFixed(2)} km';
  }

  /// Calculates the longest consecutive streak of active days within this range
  int get longestStreak {
    if (dailySummaries.isEmpty) return 0;
    int maxStreak = 0;
    int currentStreak = 0;

    for (final day in dailySummaries) {
      if (day.isActiveDay) {
        currentStreak++;
        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
        }
      } else {
        currentStreak = 0;
      }
    }
    return maxStreak;
  }
}
