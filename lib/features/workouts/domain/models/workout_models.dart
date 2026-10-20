class WorkoutSetEntity {
  final String id;
  final String workoutExerciseId;
  final int setNumber;
  final int reps;
  final double weightKg;
  final bool isCompleted;
  final int restSeconds;
  final String type; // 'normal', 'warmup', 'drop', 'failure'

  const WorkoutSetEntity({
    required this.id,
    required this.workoutExerciseId,
    required this.setNumber,
    required this.reps,
    required this.weightKg,
    this.isCompleted = false,
    this.restSeconds = 60,
    this.type = 'normal',
  });

  WorkoutSetEntity copyWith({
    String? id,
    String? workoutExerciseId,
    int? setNumber,
    int? reps,
    double? weightKg,
    bool? isCompleted,
    int? restSeconds,
    String? type,
  }) {
    return WorkoutSetEntity(
      id: id ?? this.id,
      workoutExerciseId: workoutExerciseId ?? this.workoutExerciseId,
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      isCompleted: isCompleted ?? this.isCompleted,
      restSeconds: restSeconds ?? this.restSeconds,
      type: type ?? this.type,
    );
  }
}

class WorkoutExerciseEntity {
  final String id;
  final String workoutId;
  final String exerciseId;
  final String exerciseName;
  final String category;
  final int orderIndex;
  final String? notes;
  final List<WorkoutSetEntity> sets;

  const WorkoutExerciseEntity({
    required this.id,
    required this.workoutId,
    required this.exerciseId,
    required this.exerciseName,
    required this.category,
    required this.orderIndex,
    this.notes,
    this.sets = const [],
  });

  WorkoutExerciseEntity copyWith({
    String? id,
    String? workoutId,
    String? exerciseId,
    String? exerciseName,
    String? category,
    int? orderIndex,
    String? notes,
    List<WorkoutSetEntity>? sets,
  }) {
    return WorkoutExerciseEntity(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      category: category ?? this.category,
      orderIndex: orderIndex ?? this.orderIndex,
      notes: notes ?? this.notes,
      sets: sets ?? this.sets,
    );
  }
}

class WorkoutEntity {
  final String id;
  final String title;
  final String? note;
  final String? category;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String status; // 'in_progress', 'completed', 'cancelled'
  final int durationSeconds;
  final int? caloriesBurned;
  final String syncStatus; // 'pending', 'synced', 'failed'
  final DateTime updatedAt;
  final List<WorkoutExerciseEntity> exercises;

  const WorkoutEntity({
    required this.id,
    required this.title,
    this.note,
    this.category,
    required this.startedAt,
    this.completedAt,
    this.status = 'in_progress',
    this.durationSeconds = 0,
    this.caloriesBurned,
    this.syncStatus = 'pending',
    required this.updatedAt,
    this.exercises = const [],
  });

  WorkoutEntity copyWith({
    String? id,
    String? title,
    String? note,
    String? category,
    DateTime? startedAt,
    DateTime? completedAt,
    String? status,
    int? durationSeconds,
    int? caloriesBurned,
    String? syncStatus,
    DateTime? updatedAt,
    List<WorkoutExerciseEntity>? exercises,
  }) {
    return WorkoutEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      category: category ?? this.category,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
      exercises: exercises ?? this.exercises,
    );
  }

  /// Calculates burned calories using MET formula: MET × weight_kg × (duration_sec / 3600)
  /// MET map: strength=6.0, cardio=8.0, yoga=3.0, default=5.0
  static int computeCalories({
    String? category,
    required double weightKg,
    required int durationSeconds,
  }) {
    final clean = (category ?? '').toLowerCase();
    final double met;
    if (clean.contains('strength')) {
      met = 6.0;
    } else if (clean.contains('cardio')) {
      met = 8.0;
    } else if (clean.contains('yoga')) {
      met = 3.0;
    } else {
      met = 5.0;
    }
    return (met * weightKg * (durationSeconds / 3600.0)).round();
  }

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets.length);

  int get completedSets => exercises.fold(
        0,
        (sum, e) => sum + e.sets.where((s) => s.isCompleted).length,
      );

  double get totalVolumeKg => exercises.fold(
        0.0,
        (sum, e) =>
            sum +
            e.sets
                .where((s) => s.isCompleted)
                .fold(0.0, (sSum, s) => sSum + (s.weightKg * s.reps)),
      );
}

class ExerciseEntity {
  final String id;
  final String name;
  final String category;
  final String targetMuscle;
  final String instructions;
  final String equipment;
  final bool isCustom;
  final DateTime createdAt;
  final String? imageAsset;
  final String? anatomyAsset;
  final List<String> recommendedFor;

  const ExerciseEntity({
    required this.id,
    required this.name,
    required this.category,
    required this.targetMuscle,
    required this.instructions,
    required this.equipment,
    this.isCustom = false,
    required this.createdAt,
    this.imageAsset,
    this.anatomyAsset,
    this.recommendedFor = const ['all'],
  });
}
