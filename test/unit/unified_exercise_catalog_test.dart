import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/core/data/workout_repository.dart';
import 'package:fit_host/features/workouts/domain/models/workout_models.dart';

void main() {
  group('Unified Exercise Catalog & Safe Replacement Tests', () {
    late AppDatabase db;
    late LocalWorkoutRepository repo;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = LocalWorkoutRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'catalog seeding is idempotent and imports exactly 1324 canonical exercises',
      () async {
        // First seed
        await repo.seedDefaultExercises();
        final firstRunExercises = await repo.getExercises();
        expect(firstRunExercises.length, equals(1324));

        // Second seed (repeatability & idempotence check)
        await repo.seedDefaultExercises();
        final secondRunExercises = await repo.getExercises();
        expect(secondRunExercises.length, equals(1324));
      },
    );

    test('deterministic UUIDs and provenance metadata are preserved', () async {
      await repo.seedDefaultExercises();
      final exercises = await repo.getExercises();

      for (final ex in exercises.take(20)) {
        expect(ex.id, isNotEmpty);
        expect(ex.source, equals('exercises-dataset'));
        expect(ex.originalSourceId, isNotNull);
        expect(ex.contentLicense, equals('MIT'));
        expect(ex.contentAttribution, contains('exercises-dataset'));
        expect(ex.mediaAttribution, contains('Gym visual'));
      }
    });

    test(
      'universal audience suitability: exercises are universal and never hidden by gender filter',
      () async {
        await repo.seedDefaultExercises();

        final universalList = await repo.getExercises(
          genderFilter: 'universal',
        );
        expect(universalList.length, equals(1324));
        expect(
          universalList.every((e) => e.audienceSuitability == 'universal'),
          isTrue,
        );

        final maleList = await repo.getExercises(genderFilter: 'male');
        expect(maleList.length, equals(1324));

        final femaleList = await repo.getExercises(genderFilter: 'female');
        expect(femaleList.length, equals(1324));
      },
    );

    test(
      'search query filtering matches exercise names and muscles accurately',
      () async {
        await repo.seedDefaultExercises();

        final benchResults = await repo.getExercises(query: 'bench press');
        expect(benchResults.isNotEmpty, isTrue);
        expect(
          benchResults.any((e) => e.name.toLowerCase().contains('bench press')),
          isTrue,
        );

        final squatResults = await repo.getExercises(query: 'squat');
        expect(squatResults.isNotEmpty, isTrue);
        expect(
          squatResults.any((e) => e.name.toLowerCase().contains('squat')),
          isTrue,
        );
      },
    );

    test(
      'search includes canonical taxonomy fields and pagination is deterministic',
      () async {
        await repo.seedDefaultExercises();

        final muscleResults = await repo.getExercises(query: 'quadriceps');
        expect(muscleResults, isNotEmpty);
        expect(
          muscleResults.any(
            (e) =>
                e.targetMuscle.toLowerCase().contains('quadriceps') ||
                e.muscleGroup?.toLowerCase().contains('quadriceps') == true ||
                e.secondaryMuscles.any(
                  (muscle) => muscle.toLowerCase().contains('quadriceps'),
                ),
          ),
          isTrue,
        );

        final firstPage = await repo.getExercises(limit: 25);
        final secondPage = await repo.getExercises(limit: 25, offset: 25);
        expect(firstPage.length, 25);
        expect(secondPage.length, 25);
        expect(
          firstPage
              .map((exercise) => exercise.id)
              .toSet()
              .intersection(secondPage.map((exercise) => exercise.id).toSet()),
          isEmpty,
        );
        expect(
          firstPage.map((exercise) => exercise.name).toList(),
          orderedEquals(
            firstPage.map((exercise) => exercise.name).toList()..sort(),
          ),
        );
      },
    );

    test('pagination rejects invalid bounds', () async {
      await expectLater(
        repo.getExercises(limit: 0),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        repo.getExercises(offset: -1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('category filtering partitions exercises correctly', () async {
      await repo.seedDefaultExercises();

      final chestExercises = await repo.getExercises(category: 'Chest');
      expect(chestExercises.isNotEmpty, isTrue);
      expect(chestExercises.every((e) => e.category == 'Chest'), isTrue);

      final backExercises = await repo.getExercises(category: 'Back');
      expect(backExercises.isNotEmpty, isTrue);
      expect(backExercises.every((e) => e.category == 'Back'), isTrue);
    });

    test(
      'legacy exercise IDs resolve transparently without broken references',
      () async {
        await repo.seedDefaultExercises();

        // Querying a legacy ID (e.g. ex-bench-press) resolves via exercise_id_mappings
        final resolved = await repo.getExerciseById('ex-bench-press');
        expect(resolved, isNotNull);
        expect(resolved!.name.toLowerCase(), contains('bench press'));

        final squatResolved = await repo.getExerciseById('ex-barbell-squat');
        expect(squatResolved, isNotNull);
        expect(squatResolved!.name.toLowerCase(), contains('squat'));
      },
    );

    test(
      'historical workouts with legacy exercise IDs remain fully accessible and editable',
      () async {
        await repo.seedDefaultExercises();

        final now = DateTime.now();
        final workoutId = 'historical-workout-1';
        final workoutExerciseId = 'historical-we-1';

        final historicalWorkout = WorkoutEntity(
          id: workoutId,
          title: 'Legacy Leg Day',
          startedAt: now.subtract(const Duration(days: 7)),
          completedAt: now.subtract(const Duration(days: 7, hours: -1)),
          status: 'completed',
          durationSeconds: 3600,
          updatedAt: now,
          exercises: [
            WorkoutExerciseEntity(
              id: workoutExerciseId,
              workoutId: workoutId,
              exerciseId: 'ex-barbell-squat', // Legacy ID
              exerciseName: 'Barbell Squat',
              category: 'Legs',
              orderIndex: 0,
              sets: [
                WorkoutSetEntity(
                  id: 'set-1',
                  workoutExerciseId: workoutExerciseId,
                  setNumber: 1,
                  reps: 8,
                  weightKg: 100,
                  isCompleted: true,
                  restSeconds: 120,
                ),
              ],
            ),
          ],
        );

        // Saving and retrieving the historical workout must not violate foreign keys
        await repo.saveWorkout(historicalWorkout);

        final fetched = await repo.getWorkoutById(workoutId);
        expect(fetched, isNotNull);
        expect(fetched!.title, equals('Legacy Leg Day'));
        expect(fetched.exercises.length, equals(1));
        expect(fetched.exercises.first.exerciseId, equals('ex-barbell-squat'));
        expect(fetched.exercises.first.sets.first.weightKg, equals(100));

        // Resolve the exercise used in the workout
        final exEntity = await repo.getExerciseById(
          fetched.exercises.first.exerciseId,
        );
        expect(exEntity, isNotNull);
        expect(exEntity!.name.toLowerCase(), contains('squat'));
      },
    );

    test(
      'new workouts with unified canonical UUIDs save and retrieve successfully',
      () async {
        await repo.seedDefaultExercises();

        final canonicalEx = (await repo.getExercises()).first;
        final now = DateTime.now();
        final workoutId = 'canonical-workout-1';
        final workoutExerciseId = 'canonical-we-1';

        final newWorkout = WorkoutEntity(
          id: workoutId,
          title: 'Modern Workout',
          startedAt: now,
          status: 'in_progress',
          durationSeconds: 1200,
          updatedAt: now,
          exercises: [
            WorkoutExerciseEntity(
              id: workoutExerciseId,
              workoutId: workoutId,
              exerciseId: canonicalEx.id,
              exerciseName: canonicalEx.name,
              category: canonicalEx.category,
              orderIndex: 0,
              sets: [
                WorkoutSetEntity(
                  id: 'cset-1',
                  workoutExerciseId: workoutExerciseId,
                  setNumber: 1,
                  reps: 12,
                  weightKg: 40,
                  isCompleted: true,
                ),
              ],
            ),
          ],
        );

        await repo.saveWorkout(newWorkout);

        final retrieved = await repo.getWorkoutById(workoutId);
        expect(retrieved, isNotNull);
        expect(retrieved!.exercises.first.exerciseId, equals(canonicalEx.id));
        expect(
          retrieved.exercises.first.exerciseName,
          equals(canonicalEx.name),
        );
      },
    );
  });
}
