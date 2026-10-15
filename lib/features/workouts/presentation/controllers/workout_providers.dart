import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/features/workouts/data/repositories/workout_repository_impl.dart';
import 'package:fit_host/features/workouts/domain/models/workout_models.dart';
import 'package:fit_host/features/workouts/domain/repositories/workout_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return WorkoutRepositoryImpl(db);
});

final workoutsStreamProvider = StreamProvider<List<WorkoutEntity>>((ref) {
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.watchWorkouts();
});

class ExerciseFilter {
  final String query;
  final String category;

  const ExerciseFilter({this.query = '', this.category = 'All'});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseFilter &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          category == other.category;

  @override
  int get hashCode => query.hashCode ^ category.hashCode;
}

class ExerciseFilterNotifier extends Notifier<ExerciseFilter> {
  @override
  ExerciseFilter build() => const ExerciseFilter();

  void updateFilter({String? query, String? category}) {
    state = ExerciseFilter(
      query: query ?? state.query,
      category: category ?? state.category,
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
  return repo.getExercises(query: filter.query, category: filter.category);
});

class ActiveWorkoutState {
  final WorkoutEntity? workout;
  final bool isActive;
  final int restTimeRemaining;
  final bool isResting;

  const ActiveWorkoutState({
    this.workout,
    this.isActive = false,
    this.restTimeRemaining = 0,
    this.isResting = false,
  });

  ActiveWorkoutState copyWith({
    WorkoutEntity? Function()? workout,
    bool? isActive,
    int? restTimeRemaining,
    bool? isResting,
  }) {
    return ActiveWorkoutState(
      workout: workout != null ? workout() : this.workout,
      isActive: isActive ?? this.isActive,
      restTimeRemaining: restTimeRemaining ?? this.restTimeRemaining,
      isResting: isResting ?? this.isResting,
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

    state = ActiveWorkoutState(
      workout: newWorkout,
      isActive: true,
      restTimeRemaining: 0,
      isResting: false,
    );

    _startDurationTimer();
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

    final finished = state.workout!.copyWith(
      status: 'completed',
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
