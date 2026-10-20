import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/core/services/supabase_service.dart';
import 'package:fit_host/core/sync/sync_outbox_worker.dart';
import 'package:fit_host/core/data/workout_repository.dart';
import 'package:fit_host/features/workouts/domain/models/workout_models.dart';
import 'package:fit_host/features/profile/presentation/controllers/user_profile_controller.dart';

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

  const ExerciseFilter({
    this.query = '',
    this.category = 'All',
    this.genderFilter,
  });

  ExerciseFilter copyWith({
    String? query,
    String? category,
    String? genderFilter,
  }) {
    return ExerciseFilter(
      query: query ?? this.query,
      category: category ?? this.category,
      genderFilter: genderFilter ?? this.genderFilter,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseFilter &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          category == other.category &&
          genderFilter == other.genderFilter;

  @override
  int get hashCode =>
      query.hashCode ^ category.hashCode ^ (genderFilter?.hashCode ?? 0);
}

class ExerciseFilterNotifier extends Notifier<ExerciseFilter> {
  @override
  ExerciseFilter build() {
    final userGender = ref.watch(userProfileProvider).gender;
    return ExerciseFilter(genderFilter: userGender);
  }

  void updateFilter({String? query, String? category, String? genderFilter}) {
    state = state.copyWith(
      query: query,
      category: category,
      genderFilter: genderFilter,
    );
  }

  void resetToAll() {
    state = state.copyWith(genderFilter: 'All', category: 'All', query: '');
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
    genderFilter: filter.genderFilter,
  );
});

class ActiveWorkoutState {
  final WorkoutEntity? workout;
  final bool isActive;
  final int restTimeRemaining;
  final bool isResting;
  final bool isTimerRunning;

  const ActiveWorkoutState({
    this.workout,
    this.isActive = false,
    this.restTimeRemaining = 0,
    this.isResting = false,
    this.isTimerRunning = false,
  });

  ActiveWorkoutState copyWith({
    WorkoutEntity? Function()? workout,
    bool? isActive,
    int? restTimeRemaining,
    bool? isResting,
    bool? isTimerRunning,
  }) {
    return ActiveWorkoutState(
      workout: workout != null ? workout() : this.workout,
      isActive: isActive ?? this.isActive,
      restTimeRemaining: restTimeRemaining ?? this.restTimeRemaining,
      isResting: isResting ?? this.isResting,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
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
    return const ActiveWorkoutState();
  }

  WorkoutRepository get _repository => ref.read(workoutRepositoryProvider);

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
            sets: [
              WorkoutSetEntity(
                id: _uuid.v4(),
                workoutExerciseId: weId,
                setNumber: 1,
                reps: 10,
                weightKg: 20.0,
                isCompleted: false,
                restSeconds: 60,
              ),
            ],
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
    );

    if (shouldStartTimer) {
      _startDurationTimer();
    }
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.workout != null && state.isActive) {
        final current = state.workout!;
        state = state.copyWith(
          workout: () => current.copyWith(
            durationSeconds: current.durationSeconds + 1,
            updatedAt: DateTime.now(),
          ),
        );
      }
    });
  }

  void startOrResumeTimer() {
    _startDurationTimer();
    state = state.copyWith(isTimerRunning: true);
  }

  void pauseTimer() {
    _durationTimer?.cancel();
    state = state.copyWith(isTimerRunning: false);
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
        ),
      ],
    );

    final updated = current.copyWith(
      exercises: [...current.exercises, newExercise],
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(workout: () => updated);
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
      final updated = current.copyWith(
        exercises: list,
        updatedAt: DateTime.now(),
      );
      state = state.copyWith(workout: () => updated);
    }
  }

  void addSet(int exerciseIndex, {double weightKg = 20, int reps = 10, int rest = 60}) {
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
      isCompleted: false,
    );

    final updatedSets = [...targetEx.sets, newSet];
    final updatedEx = targetEx.copyWith(sets: updatedSets);
    final updatedList = [...current.exercises];
    updatedList[exerciseIndex] = updatedEx;

    state = state.copyWith(
      workout: () => current.copyWith(
        exercises: updatedList,
        updatedAt: DateTime.now(),
      ),
    );
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

    state = state.copyWith(
      workout: () => current.copyWith(
        exercises: updatedList,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void updateSet(
    int exerciseIndex,
    int setIndex, {
    double? weightKg,
    int? reps,
    int? restSeconds,
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
    );

    final updatedSets = [...targetEx.sets];
    updatedSets[setIndex] = updatedSet;
    final updatedEx = targetEx.copyWith(sets: updatedSets);
    final updatedList = [...current.exercises];
    updatedList[exerciseIndex] = updatedEx;

    state = state.copyWith(
      workout: () => current.copyWith(
        exercises: updatedList,
        updatedAt: DateTime.now(),
      ),
    );
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

    state = state.copyWith(
      workout: () => current.copyWith(
        exercises: updatedList,
        updatedAt: DateTime.now(),
      ),
    );

    if (willComplete && s.restSeconds > 0) {
      startRestTimer(s.restSeconds);
    }
  }

  void startRestTimer(int seconds) {
    _restTimer?.cancel();
    state = state.copyWith(
      restTimeRemaining: seconds,
      isResting: true,
    );

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.restTimeRemaining <= 1) {
        timer.cancel();
        state = state.copyWith(
          restTimeRemaining: 0,
          isResting: false,
        );
      } else {
        state = state.copyWith(
          restTimeRemaining: state.restTimeRemaining - 1,
        );
      }
    });
  }

  void skipRestTimer() {
    _restTimer?.cancel();
    state = state.copyWith(
      restTimeRemaining: 0,
      isResting: false,
    );
  }

  void adjustRestTimer(int deltaSeconds) {
    final next = state.restTimeRemaining + deltaSeconds;
    if (next <= 0) {
      skipRestTimer();
    } else {
      state = state.copyWith(restTimeRemaining: next);
    }
  }

  void updateWorkoutTitle(String title) {
    if (state.workout == null) return;
    state = state.copyWith(
      workout: () => state.workout!.copyWith(
        title: title,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void updateWorkoutNote(String note) {
    if (state.workout == null) return;
    state = state.copyWith(
      workout: () => state.workout!.copyWith(
        note: note,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<WorkoutEntity?> finishWorkout() async {
    if (state.workout == null) return null;
    _durationTimer?.cancel();
    _restTimer?.cancel();

    final profile = ref.read(userProfileProvider);
    final weightKg = profile.weightKg > 0 ? profile.weightKg : 70.0;
    final burned = WorkoutEntity.computeCalories(
      category: state.workout!.category ?? state.workout!.title,
      weightKg: weightKg,
      durationSeconds: state.workout!.durationSeconds,
    );

    final finished = state.workout!.copyWith(
      status: 'completed',
      caloriesBurned: burned,
      completedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _repository.saveWorkout(finished);

    state = const ActiveWorkoutState();
    return finished;
  }

  void cancelWorkout() {
    _durationTimer?.cancel();
    _restTimer?.cancel();
    state = const ActiveWorkoutState();
  }
}

final activeWorkoutProvider =
    NotifierProvider<ActiveWorkoutNotifier, ActiveWorkoutState>(
  ActiveWorkoutNotifier.new,
);
