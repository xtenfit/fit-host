class DailyStepRecord {
  final String id;
  final String userId;
  final DateTime date;
  final int steps;
  final int targetSteps;
  final double distanceKm;
  final int activeCalories;
  final int activeMinutes;
  final String timezoneOffset;
  final DateTime updatedAt;

  const DailyStepRecord({
    required this.id,
    required this.userId,
    required this.date,
    required this.steps,
    this.targetSteps = 10000,
    this.distanceKm = 0.0,
    this.activeCalories = 0,
    this.activeMinutes = 0,
    this.timezoneOffset = '+00:00',
    required this.updatedAt,
  });

  double get progressPercentage {
    if (targetSteps <= 0) return 0.0;
    return (steps / targetSteps).clamp(0.0, 1.0);
  }

  bool get isGoalReached => steps >= targetSteps;

  DailyStepRecord copyWith({
    String? id,
    String? userId,
    DateTime? date,
    int? steps,
    int? targetSteps,
    double? distanceKm,
    int? activeCalories,
    int? activeMinutes,
    String? timezoneOffset,
    DateTime? updatedAt,
  }) {
    return DailyStepRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      steps: steps ?? this.steps,
      targetSteps: targetSteps ?? this.targetSteps,
      distanceKm: distanceKm ?? this.distanceKm,
      activeCalories: activeCalories ?? this.activeCalories,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      timezoneOffset: timezoneOffset ?? this.timezoneOffset,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
