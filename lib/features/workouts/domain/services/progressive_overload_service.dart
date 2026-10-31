import 'dart:math';
import '../models/workout_models.dart';
import '../repositories/workout_repository.dart';
import '../repositories/routine_repository.dart';

class ProgressiveOverloadService {
  final WorkoutRepository workoutRepository;
  final RoutineRepository routineRepository;

  ProgressiveOverloadService({
    required this.workoutRepository,
    required this.routineRepository,
  });

  /// Evaluates consecutive completed workouts for a given exercise and determines
  /// if a Double Progression overload recommendation (load increase, rep increase, or deload)
  /// is warranted.
  Future<ProgressionRecommendationEntity?> evaluateExerciseProgression({
    required String exerciseId,
    required String exerciseName,
    List<WorkoutEntity>? completedWorkouts,
    ProgressionSettingsEntity? customSettings,
  }) async {
    // 1. Fetch or use custom settings
    final settings =
        customSettings ??
        await routineRepository.getProgressionSettings(exerciseId) ??
        ProgressionSettingsEntity(
          id: 'default_$exerciseId',
          userId: 'guest',
          exerciseId: exerciseId,
        );

    // 2. Fetch completed workouts if not provided
    final allWorkouts =
        completedWorkouts ?? await workoutRepository.getWorkouts();
    final exerciseSessions = _extractExerciseSessions(
      workouts: allWorkouts,
      exerciseId: exerciseId,
    );

    if (exerciseSessions.isEmpty) {
      return null;
    }

    final mostRecentSession = exerciseSessions.first;
    final recentWorkingSets = mostRecentSession.sets
        .where((s) => s.isCompleted && !s.isSkipped && s.isWorkingSet)
        .toList();

    if (recentWorkingSets.isEmpty) {
      return null;
    }

    // Check if movement is a timed hold (e.g. Plank)
    final isTimedHold = recentWorkingSets.any(
      (s) => (s.durationSeconds ?? 0) > 0 && (s.reps <= 1 || s.weightKg == 0),
    );

    if (isTimedHold) {
      return _evaluateTimedHoldProgression(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        sessions: exerciseSessions,
        settings: settings,
      );
    }

    // Standard weighted resistance movement
    return _evaluateDoubleProgression(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      sessions: exerciseSessions,
      settings: settings,
    );
  }

  /// Evaluates double progression:
  /// - Dimension 1: Work up to targetRepsMax on all targetWorkingSets.
  /// - Dimension 2: Once achieved for successfulSessionsRequired consecutive sessions, increase load by weightIncrementKg.
  /// - Deload: If failing to hit targetRepsMin for deloadAfterMissedSessions consecutive sessions, deload by deloadPercentage.
  ProgressionRecommendationEntity? _evaluateDoubleProgression({
    required String exerciseId,
    required String exerciseName,
    required List<WorkoutExerciseEntity> sessions,
    required ProgressionSettingsEntity settings,
  }) {
    final mostRecentSession = sessions.first;
    final recentWorkingSets = mostRecentSession.sets
        .where((s) => s.isCompleted && !s.isSkipped && s.isWorkingSet)
        .toList();

    if (recentWorkingSets.isEmpty) return null;

    final currentWeightKg = recentWorkingSets.first.weightKg;

    // Check for Load Increase (Overload Trigger)
    int consecutiveSuccessSessions = 0;
    for (final session in sessions) {
      final workingSets = session.sets
          .where((s) => s.isCompleted && !s.isSkipped && s.isWorkingSet)
          .toList();

      if (workingSets.isEmpty) break;

      // Must be at the current weight (within 0.25kg tolerance)
      final sessionWeight = workingSets.first.weightKg;
      if ((sessionWeight - currentWeightKg).abs() > 0.25) {
        break;
      }

      // Must have at least targetWorkingSets
      if (workingSets.length < settings.targetWorkingSets) {
        break;
      }

      // All evaluated working sets up to targetWorkingSets must hit targetRepsMax
      final evaluatedSets = workingSets
          .take(settings.targetWorkingSets)
          .toList();
      final allHitMax = evaluatedSets.every(
        (s) => s.reps >= settings.targetRepsMax,
      );

      if (allHitMax) {
        consecutiveSuccessSessions++;
      } else {
        break;
      }
    }

    if (consecutiveSuccessSessions >= settings.successfulSessionsRequired) {
      final suggestedWeightKg = currentWeightKg + settings.weightIncrementKg;
      return ProgressionRecommendationEntity(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        currentWeightKg: currentWeightKg,
        suggestedWeightKg: suggestedWeightKg,
        targetRepsMin: settings.targetRepsMin,
        targetRepsMax: settings.targetRepsMax,
        strategy: 'double_progression_increase',
        rationale:
            'You completed $consecutiveSuccessSessions consecutive sessions hitting your top target of ${settings.targetRepsMax} reps across ${settings.targetWorkingSets} working sets at ${currentWeightKg.toStringAsFixed(1)}kg. Progress load by +${settings.weightIncrementKg.toStringAsFixed(1)}kg to ${suggestedWeightKg.toStringAsFixed(1)}kg and reset to ${settings.targetRepsMin} reps.',
        confidenceScore: 0.95,
        status: 'pending',
      );
    }

    // Check for Deload Trigger (Missed Min Reps)
    int consecutiveMissedSessions = 0;
    for (final session in sessions) {
      final workingSets = session.sets
          .where((s) => s.isCompleted && !s.isSkipped && s.isWorkingSet)
          .toList();

      if (workingSets.isEmpty) break;

      final sessionWeight = workingSets.first.weightKg;
      if ((sessionWeight - currentWeightKg).abs() > 0.25) {
        break;
      }

      // Check if any working set missed targetRepsMin
      final missedMin = workingSets.any((s) => s.reps < settings.targetRepsMin);
      if (missedMin) {
        consecutiveMissedSessions++;
      } else {
        break;
      }
    }

    if (consecutiveMissedSessions >= settings.deloadAfterMissedSessions) {
      final reduction = currentWeightKg * (settings.deloadPercentage / 100.0);
      final rawSuggested = currentWeightKg - reduction;
      // Round to nearest 0.5kg
      final suggestedWeightKg = (rawSuggested * 2).round() / 2.0;

      return ProgressionRecommendationEntity(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        currentWeightKg: currentWeightKg,
        suggestedWeightKg: max(0.0, suggestedWeightKg),
        targetRepsMin: settings.targetRepsMin,
        targetRepsMax: settings.targetRepsMax,
        strategy: 'deload',
        rationale:
            'You missed the baseline threshold of ${settings.targetRepsMin} reps for $consecutiveMissedSessions consecutive sessions at ${currentWeightKg.toStringAsFixed(1)}kg. A strategic deload of ${settings.deloadPercentage.toStringAsFixed(0)}% to ${suggestedWeightKg.toStringAsFixed(1)}kg is recommended to clear neuromuscular fatigue.',
        confidenceScore: 0.90,
        status: 'pending',
      );
    }

    // Maintain Weight, Push Reps within Bracket
    final avgReps =
        recentWorkingSets.map((s) => s.reps).reduce((a, b) => a + b) /
        recentWorkingSets.length;
    final nextTargetRep = min(settings.targetRepsMax, avgReps.floor() + 1);

    return ProgressionRecommendationEntity(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      currentWeightKg: currentWeightKg,
      suggestedWeightKg: currentWeightKg,
      targetRepsMin: settings.targetRepsMin,
      targetRepsMax: settings.targetRepsMax,
      strategy: 'rep_progression',
      rationale:
          'Maintain ${currentWeightKg.toStringAsFixed(1)}kg. Your recent average was ${avgReps.toStringAsFixed(1)} reps. Target $nextTargetRep reps across all working sets next session to build volume.',
      confidenceScore: 0.85,
      status: 'pending',
    );
  }

  /// Evaluates progression for timed isometric holds (e.g. Plank).
  ProgressionRecommendationEntity _evaluateTimedHoldProgression({
    required String exerciseId,
    required String exerciseName,
    required List<WorkoutExerciseEntity> sessions,
    required ProgressionSettingsEntity settings,
  }) {
    final mostRecent = sessions.first;
    final workingSets = mostRecent.sets
        .where((s) => s.isCompleted && !s.isSkipped && s.isWorkingSet)
        .toList();

    final maxDuration = workingSets
        .map((s) => s.durationSeconds ?? 0)
        .fold<int>(0, (prev, elem) => max(prev, elem));

    final suggestedDuration = maxDuration >= 60
        ? maxDuration + 10
        : maxDuration + 5;

    return ProgressionRecommendationEntity(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      currentWeightKg: 0.0,
      suggestedWeightKg: 0.0,
      targetRepsMin: 1,
      targetRepsMax: 1,
      strategy: 'duration_progression',
      rationale:
          'Timed isometric hold completed at ${maxDuration}s. Next session, increase duration to ${suggestedDuration}s (+${suggestedDuration - maxDuration}s) with strict abdominal bracing.',
      confidenceScore: 0.90,
      status: 'pending',
    );
  }

  /// Evaluates if any set in a completed workout establishes a new Personal Record.
  /// Supported PR types:
  /// - 'max_weight': Heaviest weight successfully lifted.
  /// - 'estimated_1rm': Highest calculated 1 Rep Max via Epley formula.
  /// - 'max_volume_set': Highest single set volume (reps * weight).
  Future<List<PersonalRecordEntity>> checkAndRecordPRs({
    required WorkoutEntity workout,
  }) async {
    final newPRs = <PersonalRecordEntity>[];
    final now = workout.completedAt ?? workout.startedAt;

    for (final ex in workout.exercises) {
      if (ex.isSkipped) continue;

      final workingSets = ex.sets
          .where((s) => s.isCompleted && !s.isSkipped && s.reps > 0)
          .toList();

      if (workingSets.isEmpty) continue;

      // 1. Max Weight PR
      final maxWeightSet = workingSets.reduce(
        (a, b) => a.weightKg >= b.weightKg ? a : b,
      );
      if (maxWeightSet.weightKg > 0) {
        final existingMaxWeight = await routineRepository.getPersonalRecord(
          ex.exerciseId,
          'max_weight',
        );
        if (existingMaxWeight == null ||
            maxWeightSet.weightKg > existingMaxWeight.value) {
          final pr = PersonalRecordEntity(
            id: 'pr_weight_${ex.exerciseId}_${now.millisecondsSinceEpoch}',
            userId: workout.id,
            exerciseId: ex.exerciseId,
            recordType: 'max_weight',
            value: maxWeightSet.weightKg,
            weightKg: maxWeightSet.weightKg,
            reps: maxWeightSet.reps,
            workoutId: workout.id,
            workoutSetId: maxWeightSet.id,
            achievedAt: now,
          );
          await routineRepository.savePersonalRecord(pr);
          newPRs.add(pr);
        }
      }

      // 2. Estimated 1RM PR (Epley formula: weight * (1 + reps / 30.0))
      // Only applicable for 1 to 12 reps
      for (final s in workingSets) {
        if (s.weightKg > 0 && s.reps >= 1 && s.reps <= 12) {
          final epley1Rm = calculateEstimated1Rm(s.weightKg, s.reps);
          final existing1Rm = await routineRepository.getPersonalRecord(
            ex.exerciseId,
            'estimated_1rm',
          );
          if (existing1Rm == null || epley1Rm > existing1Rm.value) {
            final pr = PersonalRecordEntity(
              id: 'pr_1rm_${ex.exerciseId}_${now.millisecondsSinceEpoch}',
              userId: workout.id,
              exerciseId: ex.exerciseId,
              recordType: 'estimated_1rm',
              value: (epley1Rm * 10).round() / 10.0,
              weightKg: s.weightKg,
              reps: s.reps,
              workoutId: workout.id,
              workoutSetId: s.id,
              achievedAt: now,
            );
            await routineRepository.savePersonalRecord(pr);
            newPRs.add(pr);
          }
        }
      }

      // 3. Max Volume Set PR (reps * weightKg)
      final maxVolumeSet = workingSets.reduce(
        (a, b) => a.volumeKg >= b.volumeKg ? a : b,
      );
      if (maxVolumeSet.volumeKg > 0) {
        final existingMaxVolume = await routineRepository.getPersonalRecord(
          ex.exerciseId,
          'max_volume_set',
        );
        if (existingMaxVolume == null ||
            maxVolumeSet.volumeKg > existingMaxVolume.value) {
          final pr = PersonalRecordEntity(
            id: 'pr_vol_${ex.exerciseId}_${now.millisecondsSinceEpoch}',
            userId: workout.id,
            exerciseId: ex.exerciseId,
            recordType: 'max_volume_set',
            value: (maxVolumeSet.volumeKg * 10).round() / 10.0,
            weightKg: maxVolumeSet.weightKg,
            reps: maxVolumeSet.reps,
            workoutId: workout.id,
            workoutSetId: maxVolumeSet.id,
            achievedAt: now,
          );
          await routineRepository.savePersonalRecord(pr);
          newPRs.add(pr);
        }
      }
    }

    return newPRs;
  }

  /// Calculates estimated 1RM using the validated Epley formula:
  /// 1RM = Weight * (1 + Reps / 30)
  static double calculateEstimated1Rm(double weightKg, int reps) {
    if (reps <= 1) return weightKg;
    return weightKg * (1.0 + (reps / 30.0));
  }

  /// Extracts chronological sessions of a specific exercise across workouts.
  List<WorkoutExerciseEntity> _extractExerciseSessions({
    required List<WorkoutEntity> workouts,
    required String exerciseId,
  }) {
    final completed = workouts.where((w) => w.status == 'completed').toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

    final sessions = <WorkoutExerciseEntity>[];
    for (final w in completed) {
      for (final ex in w.exercises) {
        if (ex.exerciseId == exerciseId && !ex.isSkipped) {
          sessions.add(ex);
          break; // Take primary instance in this workout
        }
      }
    }
    return sessions;
  }
}
