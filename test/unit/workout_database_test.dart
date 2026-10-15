import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/features/workouts/data/repositories/workout_repository_impl.dart';
import 'package:fit_host/features/workouts/domain/models/workout_models.dart';

void main() {
  group('Drift SQLite Workout Persistence & Offline Lifecycle', () {
    late AppDatabase database;
    late WorkoutRepositoryImpl repository;

    setUp(() async {
      // Create a fresh in-memory SQLite database instance
      database = AppDatabase(NativeDatabase.memory());
      repository = WorkoutRepositoryImpl(database);
      await repository.seedDefaultExercises();
    });

    tearDown(() async {
      await database.close();
    });

    test('Seeds default exercise library offline', () async {
      final exercises = await repository.getExercises();
      expect(exercises, isNotEmpty);
      expect(exercises.length, greaterThanOrEqualTo(10));
      expect(exercises.any((e) => e.name == 'Barbell Bench Press'), isTrue);
      expect(exercises.any((e) => e.name == 'Barbell Back Squat'), isTrue);
      expect(exercises.any((e) => e.name == 'Conventional Deadlift'), isTrue);
    });

    test('Filters exercises by category and search query', () async {
      final chestExercises = await repository.getExercises(category: 'Chest');
      expect(chestExercises.every((e) => e.category == 'Chest'), isTrue);

      final searchResults = await repository.getExercises(query: 'bench');
      expect(searchResults.any((e) => e.name.contains('Bench')), isTrue);
    });

    test('Creates workout with exercises & sets, persists to SQLite and verifies data integrity',
        () async {
      final now = DateTime.now().toUtc();
      final workoutId = 'test-workout-101';
      final weId = 'test-we-101';
      final setId = 'test-set-101';

      final workout = WorkoutEntity(
        id: workoutId,
        title: 'Chest & Arms Hypertrophy',
        note: 'Felt strong on bench press today.',
        startedAt: now,
        completedAt: now.add(const Duration(minutes: 45)),
        status: 'completed',
        durationSeconds: 2700,
        syncStatus: 'pending',
        updatedAt: now,
        exercises: [
          WorkoutExerciseEntity(
            id: weId,
            workoutId: workoutId,
            exerciseId: 'ex-bench-press',
            exerciseName: 'Barbell Bench Press',
            category: 'Chest',
            orderIndex: 0,
            sets: [
              WorkoutSetEntity(
                id: setId,
                workoutExerciseId: weId,
                setNumber: 1,
                reps: 10,
                weightKg: 80.0,
                isCompleted: true,
                restSeconds: 90,
                type: 'normal',
              ),
              WorkoutSetEntity(
                id: 'test-set-102',
                workoutExerciseId: weId,
                setNumber: 2,
                reps: 8,
                weightKg: 85.0,
                isCompleted: true,
                restSeconds: 90,
                type: 'normal',
              ),
            ],
          ),
        ],
      );

      // Save to SQLite
      await repository.saveWorkout(workout);

      // Fetch by ID
      final retrieved = await repository.getWorkoutById(workoutId);
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals(workoutId));
      expect(retrieved.title, equals('Chest & Arms Hypertrophy'));
      expect(retrieved.status, equals('completed'));
      expect(retrieved.durationSeconds, equals(2700));
      expect(retrieved.exercises.length, equals(1));
      expect(retrieved.exercises.first.exerciseName, equals('Barbell Bench Press'));
      expect(retrieved.exercises.first.sets.length, equals(2));
      expect(retrieved.exercises.first.sets.first.weightKg, equals(80.0));
      expect(retrieved.exercises.first.sets.first.reps, equals(10));
      expect(retrieved.exercises.first.sets.first.isCompleted, isTrue);

      // Verify computed domain helpers
      expect(retrieved.totalSets, equals(2));
      expect(retrieved.completedSets, equals(2));
      // Total volume = 80*10 + 85*8 = 800 + 680 = 1480
      expect(retrieved.totalVolumeKg, equals(1480.0));

      // Verify queued for cloud synchronization
      final syncItems = await database.select(database.syncQueue).get();
      expect(syncItems.any((item) => item.entityId == workoutId), isTrue);
    });

    test('Deletes workout with cascading foreign keys', () async {
      final now = DateTime.now().toUtc();
      final workoutId = 'test-workout-delete';
      final weId = 'test-we-delete';

      final workout = WorkoutEntity(
        id: workoutId,
        title: 'Temporary Session',
        startedAt: now,
        status: 'in_progress',
        durationSeconds: 120,
        syncStatus: 'pending',
        updatedAt: now,
        exercises: [
          WorkoutExerciseEntity(
            id: weId,
            workoutId: workoutId,
            exerciseId: 'ex-bench-press',
            exerciseName: 'Barbell Bench Press',
            category: 'Chest',
            orderIndex: 0,
            sets: [
              WorkoutSetEntity(
                id: 'set-del-1',
                workoutExerciseId: weId,
                setNumber: 1,
                reps: 5,
                weightKg: 60.0,
              ),
            ],
          ),
        ],
      );

      await repository.saveWorkout(workout);
      expect(await repository.getWorkoutById(workoutId), isNotNull);

      // Delete workout
      await repository.deleteWorkout(workoutId);

      // Verify workout and children removed
      expect(await repository.getWorkoutById(workoutId), isNull);
      final remainingSets = await (database.select(database.workoutSets)
            ..where((s) => s.workoutExerciseId.equals(weId)))
          .get();
      expect(remainingSets, isEmpty);
    });
  });
}
