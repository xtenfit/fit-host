class WorkoutSetEntity {
  final String id;
  final String workoutExerciseId;
  final int setNumber;
  final int reps;
  final double weightKg;
  final bool isCompleted;
  final int restSeconds;
  final String type; // 'normal', 'warmup', 'drop', 'failure'
  final int? targetReps;
  final double? targetWeightKg;
  final int? durationSeconds;
  final double? distanceMeters;
  final String? tempo;
  final double? rpe;
  final bool isSkipped;

  const WorkoutSetEntity({
    required this.id,
    required this.workoutExerciseId,
    required this.setNumber,
    required this.reps,
    required this.weightKg,
    this.isCompleted = false,
    this.restSeconds = 60,
    this.type = 'normal',
    this.targetReps,
    this.targetWeightKg,
    this.durationSeconds,
    this.distanceMeters,
    this.tempo,
    this.rpe,
    this.isSkipped = false,
  });

  bool get isWorkingSet =>
      type == 'normal' || type == 'drop' || type == 'failure';
  bool get isWarmup => type == 'warmup';

  double get volumeKg => isCompleted && !isSkipped ? (weightKg * reps) : 0.0;

  WorkoutSetEntity copyWith({
    String? id,
    String? workoutExerciseId,
    int? setNumber,
    int? reps,
    double? weightKg,
    bool? isCompleted,
    int? restSeconds,
    String? type,
    int? targetReps,
    double? targetWeightKg,
    int? durationSeconds,
    double? distanceMeters,
    String? tempo,
    double? rpe,
    bool? isSkipped,
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
      targetReps: targetReps ?? this.targetReps,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      tempo: tempo ?? this.tempo,
      rpe: rpe ?? this.rpe,
      isSkipped: isSkipped ?? this.isSkipped,
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
  final String? supersetId;
  final bool isSkipped;
  final List<WorkoutSetEntity> sets;

  const WorkoutExerciseEntity({
    required this.id,
    required this.workoutId,
    required this.exerciseId,
    required this.exerciseName,
    required this.category,
    required this.orderIndex,
    this.notes,
    this.supersetId,
    this.isSkipped = false,
    this.sets = const [],
  });

  int get completedSetsCount =>
      sets.where((s) => s.isCompleted && !s.isSkipped).length;
  int get workingSetsCount =>
      sets.where((s) => s.isWorkingSet && s.isCompleted && !s.isSkipped).length;
  double get totalVolumeKg => sets.fold(0.0, (sum, s) => sum + s.volumeKg);

  WorkoutExerciseEntity copyWith({
    String? id,
    String? workoutId,
    String? exerciseId,
    String? exerciseName,
    String? category,
    int? orderIndex,
    String? notes,
    String? supersetId,
    bool? isSkipped,
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
      supersetId: supersetId ?? this.supersetId,
      isSkipped: isSkipped ?? this.isSkipped,
      sets: sets ?? this.sets,
    );
  }
}

class WorkoutEntity {
  final String id;
  final String? routineId;
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
    this.routineId,
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
    String? routineId,
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
      routineId: routineId ?? this.routineId,
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
    (sum, e) => sum + e.sets.where((s) => s.isCompleted && !s.isSkipped).length,
  );

  double get totalVolumeKg =>
      exercises.fold(0.0, (sum, e) => sum + e.totalVolumeKg);
}

class RoutineSetEntity {
  final String id;
  final String routineExerciseId;
  final int setNumber;
  final String type; // 'normal', 'warmup', 'drop', 'failure'
  final int targetReps;
  final int? targetMinReps;
  final int? targetMaxReps;
  final double? targetWeightKg;
  final int? targetDurationSeconds;
  final double? targetDistanceMeters;
  final double? targetRpe;
  final int restSeconds;
  final String? tempo;

  const RoutineSetEntity({
    required this.id,
    required this.routineExerciseId,
    required this.setNumber,
    String? type,
    String? setType,
    this.targetReps = 10,
    this.targetMinReps,
    this.targetMaxReps,
    this.targetWeightKg = 20.0,
    int? durationSeconds,
    int? targetDurationSeconds,
    double? distanceMeters,
    double? targetDistanceMeters,
    double? rpe,
    double? targetRpe,
    this.restSeconds = 60,
    this.tempo,
  }) : type = setType ?? type ?? 'normal',
       targetDurationSeconds = targetDurationSeconds ?? durationSeconds,
       targetDistanceMeters = targetDistanceMeters ?? distanceMeters,
       targetRpe = targetRpe ?? rpe;

  bool get isWorkingSet =>
      type == 'normal' || type == 'drop' || type == 'failure';
  String get setType => type;
  int? get durationSeconds => targetDurationSeconds;
  double? get distanceMeters => targetDistanceMeters;
  double? get rpe => targetRpe;
  double get weightKg => targetWeightKg ?? 0.0;
  int get reps => targetReps;

  RoutineSetEntity copyWith({
    String? id,
    String? routineExerciseId,
    int? setNumber,
    String? type,
    String? setType,
    int? targetReps,
    int? targetMinReps,
    int? targetMaxReps,
    double? targetWeightKg,
    int? targetDurationSeconds,
    int? durationSeconds,
    double? targetDistanceMeters,
    double? distanceMeters,
    double? targetRpe,
    double? rpe,
    int? restSeconds,
    String? tempo,
  }) {
    return RoutineSetEntity(
      id: id ?? this.id,
      routineExerciseId: routineExerciseId ?? this.routineExerciseId,
      setNumber: setNumber ?? this.setNumber,
      type: setType ?? type ?? this.type,
      targetReps: targetReps ?? this.targetReps,
      targetMinReps: targetMinReps ?? this.targetMinReps,
      targetMaxReps: targetMaxReps ?? this.targetMaxReps,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      targetDurationSeconds:
          targetDurationSeconds ??
          durationSeconds ??
          this.targetDurationSeconds,
      targetDistanceMeters:
          targetDistanceMeters ?? distanceMeters ?? this.targetDistanceMeters,
      targetRpe: targetRpe ?? rpe ?? this.targetRpe,
      restSeconds: restSeconds ?? this.restSeconds,
      tempo: tempo ?? this.tempo,
    );
  }
}

class RoutineExerciseEntity {
  final String id;
  final String routineId;
  final String exerciseId;
  final String exerciseName;
  final String category;
  final int orderIndex;
  final String? notes;
  final String? supersetId;
  final String? targetMuscle;
  final String? equipment;
  final int? restSeconds;
  final List<RoutineSetEntity> sets;

  const RoutineExerciseEntity({
    required this.id,
    required this.routineId,
    required this.exerciseId,
    required this.exerciseName,
    required this.category,
    required this.orderIndex,
    this.notes,
    this.supersetId,
    this.targetMuscle,
    this.equipment,
    this.restSeconds,
    this.sets = const [],
  });

  RoutineExerciseEntity copyWith({
    String? id,
    String? routineId,
    String? exerciseId,
    String? exerciseName,
    String? category,
    int? orderIndex,
    String? notes,
    String? supersetId,
    String? targetMuscle,
    String? equipment,
    int? restSeconds,
    List<RoutineSetEntity>? sets,
  }) {
    return RoutineExerciseEntity(
      id: id ?? this.id,
      routineId: routineId ?? this.routineId,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      category: category ?? this.category,
      orderIndex: orderIndex ?? this.orderIndex,
      notes: notes ?? this.notes,
      supersetId: supersetId ?? this.supersetId,
      targetMuscle: targetMuscle ?? this.targetMuscle,
      equipment: equipment ?? this.equipment,
      restSeconds: restSeconds ?? this.restSeconds,
      sets: sets ?? this.sets,
    );
  }
}

class RoutineEntity {
  final String id;
  final String userId;
  final String title;
  final String category;
  final String? description;
  final int durationMinutes;
  final String difficulty;
  final String? imageAsset;
  final bool isCustom;
  final bool isArchived;
  final List<String> tags;
  final int orderIndex;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<RoutineExerciseEntity> exercises;

  const RoutineEntity({
    required this.id,
    this.userId = 'guest',
    String? title,
    String? name,
    this.category = 'Strength',
    this.description,
    int? durationMinutes,
    int? estimatedDurationMinutes,
    this.difficulty = 'Intermediate',
    this.imageAsset,
    bool? isCustom,
    bool? isTemplate,
    this.isArchived = false,
    this.tags = const [],
    this.orderIndex = 0,
    required this.createdAt,
    required this.updatedAt,
    this.exercises = const [],
  }) : title = title ?? name ?? '',
       durationMinutes = durationMinutes ?? estimatedDurationMinutes ?? 45,
       isCustom = isCustom ?? !(isTemplate ?? false);

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets.length);
  String get name => title;
  int get estimatedMinutes => durationMinutes;
  int get estimatedDurationMinutes => durationMinutes;
  bool get isTemplate => !isCustom;

  RoutineEntity copyWith({
    String? id,
    String? userId,
    String? title,
    String? name,
    String? category,
    String? description,
    int? durationMinutes,
    int? estimatedDurationMinutes,
    String? difficulty,
    String? imageAsset,
    bool? isCustom,
    bool? isTemplate,
    bool? isArchived,
    List<String>? tags,
    int? orderIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<RoutineExerciseEntity>? exercises,
  }) {
    return RoutineEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? name ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      durationMinutes:
          durationMinutes ?? estimatedDurationMinutes ?? this.durationMinutes,
      difficulty: difficulty ?? this.difficulty,
      imageAsset: imageAsset ?? this.imageAsset,
      isCustom: isCustom ?? (isTemplate != null ? !isTemplate : this.isCustom),
      isArchived: isArchived ?? this.isArchived,
      tags: tags ?? this.tags,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      exercises: exercises ?? this.exercises,
    );
  }
}

class PersonalRecordEntity {
  final String id;
  final String userId;
  final String exerciseId;
  final String exerciseName;
  final String
  recordType; // 'max_weight', 'estimated_1rm', 'max_volume', 'max_reps', 'max_duration'
  final double value;
  final int? reps;
  final double? weightKg;
  final int? durationSeconds;
  final String? workoutId;
  final String? workoutSetId;
  final DateTime achievedAt;

  const PersonalRecordEntity({
    required this.id,
    this.userId = 'guest',
    required this.exerciseId,
    this.exerciseName = '',
    required this.recordType,
    required this.value,
    this.reps,
    this.weightKg,
    this.durationSeconds,
    this.workoutId,
    this.workoutSetId,
    required this.achievedAt,
  });

  String get formattedRecord {
    switch (recordType) {
      case 'max_weight':
        return '${value.toStringAsFixed(1)} kg';
      case 'estimated_1rm':
        return '${value.toStringAsFixed(1)} kg (1RM)';
      case 'max_volume':
      case 'max_volume_set':
        return '${value.toStringAsFixed(0)} kg (Volume)';
      case 'max_reps':
        return '${value.toInt()} reps';
      case 'max_duration':
        return '${value.toInt()} sec';
      default:
        return value.toString();
    }
  }
}

class ProgressionSettingsEntity {
  final String id;
  final String userId;
  final String? exerciseId; // null = global default
  final String strategy; // 'double_progression'
  final int targetRepsMin;
  final int targetRepsMax;
  final int targetWorkingSets;
  final int successfulSessionsRequired;
  final double weightIncrementKg;
  final String unitSystem; // 'metric', 'imperial'
  final bool autoApply;
  final int deloadAfterMissedSessions;
  final double deloadPercentage;
  final DateTime? updatedAt;

  const ProgressionSettingsEntity({
    required this.id,
    this.userId = 'guest',
    this.exerciseId,
    this.strategy = 'double_progression',
    this.targetRepsMin = 8,
    this.targetRepsMax = 12,
    this.targetWorkingSets = 3,
    this.successfulSessionsRequired = 2,
    this.weightIncrementKg = 2.5,
    this.unitSystem = 'metric',
    this.autoApply = false,
    this.deloadAfterMissedSessions = 3,
    this.deloadPercentage = 10.0,
    this.updatedAt,
  });

  ProgressionSettingsEntity copyWith({
    String? id,
    String? userId,
    String? exerciseId,
    String? strategy,
    int? targetRepsMin,
    int? targetRepsMax,
    int? targetWorkingSets,
    int? successfulSessionsRequired,
    double? weightIncrementKg,
    String? unitSystem,
    bool? autoApply,
    int? deloadAfterMissedSessions,
    double? deloadPercentage,
    DateTime? updatedAt,
  }) {
    return ProgressionSettingsEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      exerciseId: exerciseId ?? this.exerciseId,
      strategy: strategy ?? this.strategy,
      targetRepsMin: targetRepsMin ?? this.targetRepsMin,
      targetRepsMax: targetRepsMax ?? this.targetRepsMax,
      targetWorkingSets: targetWorkingSets ?? this.targetWorkingSets,
      successfulSessionsRequired:
          successfulSessionsRequired ?? this.successfulSessionsRequired,
      weightIncrementKg: weightIncrementKg ?? this.weightIncrementKg,
      unitSystem: unitSystem ?? this.unitSystem,
      autoApply: autoApply ?? this.autoApply,
      deloadAfterMissedSessions:
          deloadAfterMissedSessions ?? this.deloadAfterMissedSessions,
      deloadPercentage: deloadPercentage ?? this.deloadPercentage,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ProgressionRecommendationEntity {
  final String exerciseId;
  final String exerciseName;
  final double currentWeightKg;
  final double suggestedWeightKg;
  final int targetRepsMin;
  final int targetRepsMax;
  final String strategy;
  final String rationale;
  final double confidenceScore;
  final String ruleVersion;
  final String status; // 'pending', 'accepted', 'rejected', 'modified'

  const ProgressionRecommendationEntity({
    required this.exerciseId,
    required this.exerciseName,
    required this.currentWeightKg,
    required this.suggestedWeightKg,
    this.targetRepsMin = 8,
    this.targetRepsMax = 12,
    this.strategy = 'double_progression',
    required this.rationale,
    this.confidenceScore = 1.0,
    this.ruleVersion = '1.0.0',
    this.status = 'pending',
  });

  bool get shouldIncreaseLoad => suggestedWeightKg > currentWeightKg;
  bool get isDeload => suggestedWeightKg < currentWeightKg;
  double? get recommendedWeightKg => suggestedWeightKg;
  int? get recommendedReps => targetRepsMax;
  String get reason => rationale;
}

class ExerciseEntity {
  final String id;
  final String? canonicalId;
  final String source;
  final String? originalSourceId;
  final String name;
  final List<String> aliases;
  final String category;
  final String? bodyPart;
  final String targetMuscle;
  final String? muscleGroup;
  final List<String> secondaryMuscles;
  final String instructions;
  final List<String> instructionSteps;
  final String equipment;
  final String exerciseType;
  final String movementType;
  final String difficultyLevel;
  final String audienceSuitability; // 'universal', 'male', 'female'
  final bool isCustom;
  final DateTime createdAt;
  final String? imageAsset;
  final String? anatomyAsset;
  final String? mediaThumbnailUrl;
  final String? mediaAnimationUrl;
  final String? mediaLicense;
  final String? mediaAttribution;
  final String? contentLicense;
  final String? contentAttribution;
  final List<String> languagesAvailable;
  final String? safetyNotes;
  final String publicationStatus; // 'published', 'archived', 'draft'
  final List<String> recommendedFor;

  const ExerciseEntity({
    required this.id,
    this.canonicalId,
    this.source = 'fit-host',
    this.originalSourceId,
    required this.name,
    this.aliases = const [],
    required this.category,
    this.bodyPart,
    required this.targetMuscle,
    this.muscleGroup,
    this.secondaryMuscles = const [],
    required this.instructions,
    this.instructionSteps = const [],
    required this.equipment,
    this.exerciseType = 'strength',
    this.movementType = 'compound',
    this.difficultyLevel = 'intermediate',
    this.audienceSuitability = 'universal',
    this.isCustom = false,
    required this.createdAt,
    this.imageAsset,
    this.anatomyAsset,
    this.mediaThumbnailUrl,
    this.mediaAnimationUrl,
    this.mediaLicense,
    this.mediaAttribution,
    this.contentLicense,
    this.contentAttribution,
    this.languagesAvailable = const ['en'],
    this.safetyNotes,
    this.publicationStatus = 'published',
    this.recommendedFor = const ['all'],
  });

  ExerciseEntity copyWith({
    String? id,
    String? canonicalId,
    String? source,
    String? originalSourceId,
    String? name,
    List<String>? aliases,
    String? category,
    String? bodyPart,
    String? targetMuscle,
    String? muscleGroup,
    List<String>? secondaryMuscles,
    String? instructions,
    List<String>? instructionSteps,
    String? equipment,
    String? exerciseType,
    String? movementType,
    String? difficultyLevel,
    String? audienceSuitability,
    bool? isCustom,
    DateTime? createdAt,
    String? imageAsset,
    String? anatomyAsset,
    String? mediaThumbnailUrl,
    String? mediaAnimationUrl,
    String? mediaLicense,
    String? mediaAttribution,
    String? contentLicense,
    String? contentAttribution,
    List<String>? languagesAvailable,
    String? safetyNotes,
    String? publicationStatus,
    List<String>? recommendedFor,
  }) {
    return ExerciseEntity(
      id: id ?? this.id,
      canonicalId: canonicalId ?? this.canonicalId,
      source: source ?? this.source,
      originalSourceId: originalSourceId ?? this.originalSourceId,
      name: name ?? this.name,
      aliases: aliases ?? this.aliases,
      category: category ?? this.category,
      bodyPart: bodyPart ?? this.bodyPart,
      targetMuscle: targetMuscle ?? this.targetMuscle,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      instructions: instructions ?? this.instructions,
      instructionSteps: instructionSteps ?? this.instructionSteps,
      equipment: equipment ?? this.equipment,
      exerciseType: exerciseType ?? this.exerciseType,
      movementType: movementType ?? this.movementType,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      audienceSuitability: audienceSuitability ?? this.audienceSuitability,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
      imageAsset: imageAsset ?? this.imageAsset,
      anatomyAsset: anatomyAsset ?? this.anatomyAsset,
      mediaThumbnailUrl: mediaThumbnailUrl ?? this.mediaThumbnailUrl,
      mediaAnimationUrl: mediaAnimationUrl ?? this.mediaAnimationUrl,
      mediaLicense: mediaLicense ?? this.mediaLicense,
      mediaAttribution: mediaAttribution ?? this.mediaAttribution,
      contentLicense: contentLicense ?? this.contentLicense,
      contentAttribution: contentAttribution ?? this.contentAttribution,
      languagesAvailable: languagesAvailable ?? this.languagesAvailable,
      safetyNotes: safetyNotes ?? this.safetyNotes,
      publicationStatus: publicationStatus ?? this.publicationStatus,
      recommendedFor: recommendedFor ?? this.recommendedFor,
    );
  }
}
