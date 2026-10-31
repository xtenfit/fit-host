import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/core/services/supabase_service.dart';
import 'package:fit_host/core/sync/sync_outbox_worker.dart';
import 'package:fit_host/core/data/workout_repository.dart';
import 'package:fit_host/features/workouts/domain/models/workout_models.dart';
import 'package:fit_host/features/workouts/domain/services/progressive_overload_service.dart';
import 'package:fit_host/features/profile/presentation/controllers/user_profile_controller.dart';
import 'package:fit_host/core/services/analytics_service.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final status = ref.watch(authProvider).status;
  final db = ref.watch(databaseProvider);
  if (status == AuthStatus.authenticated) {
    final user = ref.watch(authProvider).user;
    if (user != null) {
      SupabaseClient? client;
      try {
        client = Supabase.instance.client;
      } catch (_) {}
      final outbox = ref.watch(syncOutboxWorkerProvider);
      return CloudWorkoutRepository(
        db: db,
        supabase: client,
        outboxWorker: outbox,
        userId: user.id,
      );
    }
  }
  return LocalWorkoutRepository(db);
});

final workoutsStreamProvider = StreamProvider<List<WorkoutEntity>>((ref) {
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.watchWorkouts();
});

class ExerciseFilter {
  final String query;
  final String category;
  final String? genderFilter;
  final String? audienceFilter;
  final String? bodyPart;
  final String? equipment;

  const ExerciseFilter({
    this.query = '',
    this.category = 'All',
    this.genderFilter,
    this.audienceFilter,
    this.bodyPart,
    this.equipment,
  });

  String? get effectiveAudienceFilter => audienceFilter ?? genderFilter;

  ExerciseFilter copyWith({
    String? query,
    String? category,
    String? genderFilter,
    String? audienceFilter,
    String? bodyPart,
    String? equipment,
  }) {
    final newAudience =
        audienceFilter ??
        genderFilter ??
        this.audienceFilter ??
        this.genderFilter;
    return ExerciseFilter(
      query: query ?? this.query,
      category: category ?? this.category,
      genderFilter: newAudience,
      audienceFilter: newAudience,
      bodyPart: bodyPart ?? this.bodyPart,
      equipment: equipment ?? this.equipment,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseFilter &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          category == other.category &&
          effectiveAudienceFilter == other.effectiveAudienceFilter &&
          bodyPart == other.bodyPart &&
          equipment == other.equipment;

  @override
  int get hashCode =>
      query.hashCode ^
      category.hashCode ^
      (effectiveAudienceFilter?.hashCode ?? 0) ^
      (bodyPart?.hashCode ?? 0) ^
      (equipment?.hashCode ?? 0);
}

class ExerciseFilterNotifier extends Notifier<ExerciseFilter> {
  @override
  ExerciseFilter build() {
    final userGender = ref.watch(userProfileProvider).gender;
    return ExerciseFilter(genderFilter: userGender, audienceFilter: userGender);
  }

  void updateFilter({
    String? query,
    String? category,
    String? genderFilter,
    String? audienceFilter,
    String? bodyPart,
    String? equipment,
  }) {
    state = state.copyWith(
      query: query,
      category: category,
      genderFilter: genderFilter,
      audienceFilter: audienceFilter,
      bodyPart: bodyPart,
      equipment: equipment,
    );
  }

  void resetToAll() {
    state = const ExerciseFilter(
      genderFilter: 'All',
      audienceFilter: 'All',
      category: 'All',
      bodyPart: 'All',
      equipment: 'All',
      query: '',
    );
  }
}

final exercisesFilterProvider =
    NotifierProvider<ExerciseFilterNotifier, ExerciseFilter>(
      ExerciseFilterNotifier.new,
    );

final exercisesListProvider = FutureProvider<List<ExerciseEntity>>((ref) async {
  final repo = ref.watch(workoutRepositoryProvider);
  final filter = ref.watch(exercisesFilterProvider);
  return repo.getExercises(
    query: filter.query,
    category: filter.category,
    genderFilter: filter.effectiveAudienceFilter,
    bodyPart: filter.bodyPart,
    equipment: filter.equipment,
  );
});

final exerciseByIdProvider = FutureProvider.family<ExerciseEntity?, String>((
  ref,
  id,
) async {
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.getExerciseById(id);
});

final progressiveOverloadServiceProvider = Provider<ProgressiveOverloadService>(
  (ref) {
    final workoutRepo = ref.watch(workoutRepositoryProvider);
    final routineRepo = ref.watch(routineRepositoryProvider);
    return ProgressiveOverloadService(
      workoutRepository: workoutRepo,
      routineRepository: routineRepo,
    );
  },
);

final previousExercisePerformanceProvider =
    FutureProvider.family<WorkoutExerciseEntity?, String>((
      ref,
      exerciseId,
    ) async {
      final repo = ref.watch(workoutRepositoryProvider);
      final workouts = await repo.getWorkouts();
      final completed = workouts.where((w) => w.status == 'completed').toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

      for (final w in completed) {
        for (final ex in w.exercises) {
          if (ex.exerciseId == exerciseId &&
              !ex.isSkipped &&
              ex.sets.any((s) => s.isCompleted)) {
            return ex;
          }
        }
      }
      return null;
    });

final exerciseProgressionProvider =
    FutureProvider.family<
      ProgressionRecommendationEntity?,
      ({String exerciseId, String exerciseName})
    >((ref, arg) async {
      final service = ref.watch(progressiveOverloadServiceProvider);
      return service.evaluateExerciseProgression(
        exerciseId: arg.exerciseId,
        exerciseName: arg.exerciseName,
      );
    });

class ActiveWorkoutState {
  final WorkoutEntity? workout;
  final bool isActive;
  final int restTimeRemaining;
  final bool isResting;
  final bool isTimerRunning;
  final DateTime? startedAt;
  final Duration pausedDuration;
  final DateTime? lastPausedAt;
  final DateTime? targetRestEndTime;
  final WorkoutEntity? recoveredWorkout;
  final List<PersonalRecordEntity> lastCompletedSetPRs;

  const ActiveWorkoutState({
    this.workout,
    this.isActive = false,
    this.restTimeRemaining = 0,
    this.isResting = false,
    this.isTimerRunning = false,
    this.startedAt,
    this.pausedDuration = Duration.zero,
    this.lastPausedAt,
    this.targetRestEndTime,
    this.recoveredWorkout,
    this.lastCompletedSetPRs = const [],
  });

  int get elapsedSeconds {
    if (workout == null || !isActive) return 0;
    final start = startedAt ?? workout!.startedAt;
    if (!isTimerRunning && lastPausedAt != null) {
      final diff = lastPausedAt!.difference(start) - pausedDuration;
      return max(0, diff.inSeconds);
    }
    final diff = DateTime.now().difference(start) - pausedDuration;
    return max(0, diff.inSeconds);
  }

  String get formattedElapsedTime {
    final total = elapsedSeconds;
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final seconds = total % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  ActiveWorkoutState copyWith({
    WorkoutEntity? Function()? workout,
    bool? isActive,
    int? restTimeRemaining,
    bool? isResting,
    bool? isTimerRunning,
    DateTime? Function()? startedAt,
    Duration? pausedDuration,
    DateTime? Function()? lastPausedAt,
    DateTime? Function()? targetRestEndTime,
    WorkoutEntity? Function()? recoveredWorkout,
    List<PersonalRecordEntity>? lastCompletedSetPRs,
  }) {
    return ActiveWorkoutState(
      workout: workout != null ? workout() : this.workout,
      isActive: isActive ?? this.isActive,
      restTimeRemaining: restTimeRemaining ?? this.restTimeRemaining,
      isResting: isResting ?? this.isResting,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      startedAt: startedAt != null ? startedAt() : this.startedAt,
      pausedDuration: pausedDuration ?? this.pausedDuration,
      lastPausedAt: lastPausedAt != null ? lastPausedAt() : this.lastPausedAt,
      targetRestEndTime: targetRestEndTime != null
          ? targetRestEndTime()
          : this.targetRestEndTime,
      recoveredWorkout: recoveredWorkout != null
          ? recoveredWorkout()
          : this.recoveredWorkout,
      lastCompletedSetPRs: lastCompletedSetPRs ?? this.lastCompletedSetPRs,
    );
  }
}

class ActiveWorkoutNotifier extends Notifier<ActiveWorkoutState> {
  Timer? _durationTimer;
  Timer? _restTimer;
  final _uuid = const Uuid();

  @override
  ActiveWorkoutState build() {
    ref.onDispose(() {
      _durationTimer?.cancel();
      _restTimer?.cancel();
    });
    // Check for uncompleted workouts on launch to offer recovery
    Future.microtask(() => _checkForRecoverableWorkout());
    return const ActiveWorkoutState();
  }

  WorkoutRepository get _repository => ref.read(workoutRepositoryProvider);

  Future<void> _checkForRecoverableWorkout() async {
    try {
      final workouts = await _repository.getWorkouts();
      final inProgress =
          workouts.where((w) => w.status == 'in_progress').toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      if (inProgress.isNotEmpty && state.workout == null) {
        state = state.copyWith(recoveredWorkout: () => inProgress.first);
      }
    } catch (_) {}
  }

  void resumeRecoveredWorkout() {
    if (state.recoveredWorkout == null) return;
    final w = state.recoveredWorkout!;
    _durationTimer?.cancel();
    _restTimer?.cancel();

    final now = DateTime.now();
    state = ActiveWorkoutState(
      workout: w,
      isActive: true,
      isTimerRunning: true,
      startedAt: w.startedAt,
      pausedDuration: Duration(
        seconds: max(
          0,
          now.difference(w.startedAt).inSeconds - w.durationSeconds,
        ),
      ),
      recoveredWorkout: null,
    );
    _startDurationTimer();
  }

  void discardRecoveredWorkout() {
    if (state.recoveredWorkout == null) return;
    final id = state.recoveredWorkout!.id;
    state = state.copyWith(recoveredWorkout: () => null);
    _repository.deleteWorkout(id).ignore();
  }

  void startNewWorkout({
    String title = 'Quick Workout',
    List<ExerciseEntity>? initialExercises,
  }) {
    _durationTimer?.cancel();
    _restTimer?.cancel();

    final workoutId = _uuid.v4();
    final now = DateTime.now();

    final exercises = <WorkoutExerciseEntity>[];
    if (initialExercises != null) {
      for (var i = 0; i < initialExercises.length; i++) {
        final ex = initialExercises[i];
        final weId = _uuid.v4();
        exercises.add(
          WorkoutExerciseEntity(
            id: weId,
            workoutId: workoutId,
            exerciseId: ex.id,
            exerciseName: ex.name,
            category: ex.category,
            orderIndex: i,
            sets: List.generate(
              3,
              (setIdx) => WorkoutSetEntity(
                id: _uuid.v4(),
                workoutExerciseId: weId,
                setNumber: setIdx + 1,
                reps: 10,
                weightKg: 20.0,
                isCompleted: false,
                restSeconds: 60,
                targetReps: 10,
                targetWeightKg: 20.0,
              ),
            ),
          ),
        );
      }
    }

    final newWorkout = WorkoutEntity(
      id: workoutId,
      title: title,
      startedAt: now,
      status: 'in_progress',
      durationSeconds: 0,
      updatedAt: now,
      exercises: exercises,
    );

    final shouldStartTimer = exercises.isNotEmpty;

    state = ActiveWorkoutState(
      workout: newWorkout,
      isActive: true,
      restTimeRemaining: 0,
      isResting: false,
      isTimerRunning: shouldStartTimer,
      startedAt: now,
      pausedDuration: Duration.zero,
    );

    _persistIncrementalState();
    AnalyticsService.instance
        .track(
          AnalyticsEvents.workoutCreated,
          properties: {
            'source': 'quick_workout',
            'initial_exercise_count': exercises.length,
          },
        )
        .ignore();

    if (shouldStartTimer) {
      _startDurationTimer();
    }
  }

  void startFromRoutine(RoutineEntity routine) {
    _durationTimer?.cancel();
    _restTimer?.cancel();

    final workoutId = _uuid.v4();
    final now = DateTime.now();

    final exercises = <WorkoutExerciseEntity>[];
    for (var i = 0; i < routine.exercises.length; i++) {
      final re = routine.exercises[i];
      final weId = _uuid.v4();
      final sets = re.sets.map((rs) {
        return WorkoutSetEntity(
          id: _uuid.v4(),
          workoutExerciseId: weId,
          setNumber: rs.setNumber,
          reps: rs.targetReps,
          weightKg: rs.weightKg,
          restSeconds: rs.restSeconds,
          type: rs.type,
          targetReps: rs.targetReps,
          targetWeightKg: rs.targetWeightKg,
          durationSeconds: rs.durationSeconds,
          distanceMeters: rs.distanceMeters,
          tempo: rs.tempo,
          rpe: rs.rpe,
          isCompleted: false,
        );
      }).toList();

      exercises.add(
        WorkoutExerciseEntity(
          id: weId,
          workoutId: workoutId,
          exerciseId: re.exerciseId,
          exerciseName: re.exerciseName,
          category: re.category,
          orderIndex: i,
          notes: re.notes,
          supersetId: re.supersetId,
          sets: sets.isNotEmpty
              ? sets
              : List.generate(
                  3,
                  (setIdx) => WorkoutSetEntity(
                    id: _uuid.v4(),
                    workoutExerciseId: weId,
                    setNumber: setIdx + 1,
                    reps: 10,
                    weightKg: 20.0,
                    restSeconds: re.restSeconds ?? 60,
                    isCompleted: false,
                  ),
                ),
        ),
      );
    }

    final newWorkout = WorkoutEntity(
      id: workoutId,
      routineId: routine.id,
      title: routine.name,
      category: routine.category,
      startedAt: now,
      status: 'in_progress',
      durationSeconds: 0,
      updatedAt: now,
      exercises: exercises,
    );

    state = ActiveWorkoutState(
      workout: newWorkout,
      isActive: true,
      restTimeRemaining: 0,
      isResting: false,
      isTimerRunning: true,
      startedAt: now,
      pausedDuration: Duration.zero,
    );

    _persistIncrementalState();
    AnalyticsService.instance
        .track(
          AnalyticsEvents.workoutCreated,
          properties: {
            'source': 'routine',
            'initial_exercise_count': exercises.length,
          },
        )
        .ignore();
    _startDurationTimer();
  }

  void _persistIncrementalState() {
    if (state.workout != null && state.isActive) {
      final elapsed = state.elapsedSeconds;
      final updated = state.workout!.copyWith(
        durationSeconds: elapsed,
        updatedAt: DateTime.now(),
      );
      state = state.copyWith(workout: () => updated);
      _repository.saveWorkout(updated).ignore();
    }
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.workout != null && state.isActive && state.isTimerRunning) {
        state = state.copyWith(
          workout: () => state.workout!.copyWith(
            durationSeconds: state.elapsedSeconds,
            updatedAt: DateTime.now(),
          ),
        );
      }
    });
  }

  void startOrResumeTimer() {
    if (state.lastPausedAt != null) {
      final pausedDiff = DateTime.now().difference(state.lastPausedAt!);
      state = state.copyWith(
        pausedDuration: state.pausedDuration + pausedDiff,
        isTimerRunning: true,
        lastPausedAt: () => null,
      );
    } else {
      state = state.copyWith(isTimerRunning: true);
    }
    _startDurationTimer();
  }

  void pauseTimer() {
    _durationTimer?.cancel();
    state = state.copyWith(
      isTimerRunning: false,
      lastPausedAt: () => DateTime.now(),
    );
    _persistIncrementalState();
  }

  void toggleTimer() {
    if (state.isTimerRunning) {
      pauseTimer();
    } else {
      startOrResumeTimer();
    }
  }

  void addExercise(ExerciseEntity exercise) {
    if (state.workout == null) return;
    final current = state.workout!;
    final weId = _uuid.v4();
    final newExercise = WorkoutExerciseEntity(
      id: weId,
      workoutId: current.id,
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      category: exercise.category,
      orderIndex: current.exercises.length,
      sets: [
        WorkoutSetEntity(
          id: _uuid.v4(),
          workoutExerciseId: weId,
          setNumber: 1,
          reps: 10,
          weightKg: 20.0,
          isCompleted: false,
          restSeconds: 60,
          targetReps: 10,
          targetWeightKg: 20.0,
        ),
      ],
    );

    final updated = current.copyWith(
      exercises: [...current.exercises, newExercise],
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(workout: () => updated);
    _persistIncrementalState();

    if (!state.isTimerRunning) {
      startOrResumeTimer();
    }
  }

  void removeExercise(int index) {
    if (state.workout == null) return;
    final current = state.workout!;
    final list = [...current.exercises];
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      final reindexed = list
          .asMap()
          .entries
          .map((e) => e.value.copyWith(orderIndex: e.key))
          .toList();
      final updated = current.copyWith(
        exercises: reindexed,
        updatedAt: DateTime.now(),
      );
      state = state.copyWith(workout: () => updated);
      _persistIncrementalState();
    }
  }

  void reorderExercises(int oldIndex, int newIndex) {
    if (state.workout == null) return;
    final current = state.workout!;
    final list = [...current.exercises];
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    final reindexed = list
        .asMap()
        .entries
        .map((e) => e.value.copyWith(orderIndex: e.key))
        .toList();
    final updated = current.copyWith(
      exercises: reindexed,
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(workout: () => updated);
    _persistIncrementalState();
  }

  void addSet(
    int exerciseIndex, {
    double weightKg = 20,
    int reps = 10,
    int rest = 60,
    String setType = 'normal',
  }) {
    if (state.workout == null) return;
    final current = state.workout!;
    if (exerciseIndex < 0 || exerciseIndex >= current.exercises.length) return;

    final targetEx = current.exercises[exerciseIndex];
    final lastSet = targetEx.sets.isNotEmpty ? targetEx.sets.last : null;
    final newSet = WorkoutSetEntity(
      id: _uuid.v4(),
      workoutExerciseId: targetEx.id,
      setNumber: targetEx.sets.length + 1,
      reps: lastSet?.reps ?? reps,
      weightKg: lastSet?.weightKg ?? weightKg,
      restSeconds: lastSet?.restSeconds ?? rest,
      type: setType,
      targetReps: lastSet?.targetReps ?? reps,
      targetWeightKg: lastSet?.targetWeightKg ?? weightKg,
      isCompleted: false,
    );

    final updatedSets = [...targetEx.sets, newSet];
    final updatedEx = targetEx.copyWith(sets: updatedSets);
    final updatedList = [...current.exercises];
    updatedList[exerciseIndex] = updatedEx;

    final updated = current.copyWith(
      exercises: updatedList,
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(workout: () => updated);
    _persistIncrementalState();
  }

  void removeSet(int exerciseIndex, int setIndex) {
    if (state.workout == null) return;
    final current = state.workout!;
    if (exerciseIndex < 0 || exerciseIndex >= current.exercises.length) return;

    final targetEx = current.exercises[exerciseIndex];
    if (setIndex < 0 || setIndex >= targetEx.sets.length) return;

    final updatedSets = [...targetEx.sets]..removeAt(setIndex);
    for (var i = 0; i < updatedSets.length; i++) {
      updatedSets[i] = updatedSets[i].copyWith(setNumber: i + 1);
    }

    final updatedEx = targetEx.copyWith(sets: updatedSets);
    final updatedList = [...current.exercises];
    updatedList[exerciseIndex] = updatedEx;

    final updated = current.copyWith(
      exercises: updatedList,
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(workout: () => updated);
    _persistIncrementalState();
  }

  void updateSet(
    int exerciseIndex,
    int setIndex, {
    double? weightKg,
    int? reps,
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
    if (state.workout == null) return;
    final current = state.workout!;
    if (exerciseIndex < 0 || exerciseIndex >= current.exercises.length) return;

    final targetEx = current.exercises[exerciseIndex];
    if (setIndex < 0 || setIndex >= targetEx.sets.length) return;

    final s = targetEx.sets[setIndex];
    final updatedSet = s.copyWith(
      weightKg: weightKg,
      reps: reps,
      restSeconds: restSeconds,
      type: type,
      targetReps: targetReps,
      targetWeightKg: targetWeightKg,
      durationSeconds: durationSeconds,
      distanceMeters: distanceMeters,
      tempo: tempo,
      rpe: rpe,
      isSkipped: isSkipped,
    );

    final updatedSets = [...targetEx.sets];
    updatedSets[setIndex] = updatedSet;
    final updatedEx = targetEx.copyWith(sets: updatedSets);
    final updatedList = [...current.exercises];
    updatedList[exerciseIndex] = updatedEx;

    final updated = current.copyWith(
      exercises: updatedList,
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(workout: () => updated);
    _persistIncrementalState();
  }

  void toggleSetCompleted(int exerciseIndex, int setIndex) {
    if (state.workout == null) return;
    final current = state.workout!;
    if (exerciseIndex < 0 || exerciseIndex >= current.exercises.length) return;

    final targetEx = current.exercises[exerciseIndex];
    if (setIndex < 0 || setIndex >= targetEx.sets.length) return;

    final s = targetEx.sets[setIndex];
    final willComplete = !s.isCompleted;
    final updatedSet = s.copyWith(isCompleted: willComplete);

    final updatedSets = [...targetEx.sets];
    updatedSets[setIndex] = updatedSet;
    final updatedEx = targetEx.copyWith(sets: updatedSets);
    final updatedList = [...current.exercises];
    updatedList[exerciseIndex] = updatedEx;

    final updated = current.copyWith(
      exercises: updatedList,
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(workout: () => updated);
    _persistIncrementalState();

    if (willComplete && s.restSeconds > 0) {
      startRestTimer(s.restSeconds);
    }
  }

  void startRestTimer(int seconds) {
    _restTimer?.cancel();
    final target = DateTime.now().add(Duration(seconds: seconds));
    state = state.copyWith(
      restTimeRemaining: seconds,
      isResting: true,
      targetRestEndTime: () => target,
    );

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.targetRestEndTime == null) {
        timer.cancel();
        return;
      }
      final remaining = state.targetRestEndTime!
          .difference(DateTime.now())
          .inSeconds;
      if (remaining <= 0) {
        timer.cancel();
        state = state.copyWith(
          restTimeRemaining: 0,
          isResting: false,
          targetRestEndTime: () => null,
        );
      } else {
        state = state.copyWith(restTimeRemaining: remaining);
      }
    });
  }

  void skipRestTimer() {
    _restTimer?.cancel();
    state = state.copyWith(
      restTimeRemaining: 0,
      isResting: false,
      targetRestEndTime: () => null,
    );
  }

  void adjustRestTimer(int deltaSeconds) {
    if (state.targetRestEndTime == null) return;
    final newTarget = state.targetRestEndTime!.add(
      Duration(seconds: deltaSeconds),
    );
    final remaining = newTarget.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      skipRestTimer();
    } else {
      state = state.copyWith(
        targetRestEndTime: () => newTarget,
        restTimeRemaining: remaining,
      );
    }
  }

  void updateWorkoutTitle(String title) {
    if (state.workout == null) return;
    final updated = state.workout!.copyWith(
      title: title,
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(workout: () => updated);
    _persistIncrementalState();
  }

  void updateWorkoutNote(String note) {
    if (state.workout == null) return;
    final updated = state.workout!.copyWith(
      note: note,
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(workout: () => updated);
    _persistIncrementalState();
  }

  Future<WorkoutEntity?> finishWorkout() async {
    if (state.workout == null) return null;
    _durationTimer?.cancel();
    _restTimer?.cancel();

    final profile = ref.read(userProfileProvider);
    final weightKg = profile.weightKg > 0 ? profile.weightKg : 70.0;
    final elapsed = state.elapsedSeconds;
    final burned = WorkoutEntity.computeCalories(
      category: state.workout!.category ?? state.workout!.title,
      weightKg: weightKg,
      durationSeconds: elapsed,
    );

    final finished = state.workout!.copyWith(
      status: 'completed',
      durationSeconds: elapsed,
      caloriesBurned: burned,
      completedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _repository.saveWorkout(finished);

    // Live Personal Records evaluation
    try {
      final overloadService = ref.read(progressiveOverloadServiceProvider);
      await overloadService.checkAndRecordPRs(workout: finished);
    } catch (_) {}

    AnalyticsService.instance
        .track(
          AnalyticsEvents.workoutCompleted,
          properties: {
            'duration_seconds': elapsed,
            'exercise_count': finished.exercises.length,
          },
        )
        .ignore();
    state = const ActiveWorkoutState();
    return finished;
  }

  void cancelWorkout() {
    _durationTimer?.cancel();
    _restTimer?.cancel();
    if (state.workout != null) {
      _repository.deleteWorkout(state.workout!.id).ignore();
    }
    state = const ActiveWorkoutState();
  }
}

final activeWorkoutProvider =
    NotifierProvider<ActiveWorkoutNotifier, ActiveWorkoutState>(
      ActiveWorkoutNotifier.new,
    );
