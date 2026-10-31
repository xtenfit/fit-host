import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/features/workouts/data/datasources/default_exercises.dart';
import 'package:fit_host/features/workouts/data/repositories/workout_repository_impl.dart';
import 'package:fit_host/features/workouts/data/routine_service.dart';
import 'package:fit_host/features/workouts/presentation/controllers/workout_providers.dart';
import 'package:drift/native.dart';

void main() {
  group('Routine Exercise Resolution & Preloading Tests', () {
    late AppDatabase database;
    late WorkoutRepositoryImpl workoutRepository;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      workoutRepository = WorkoutRepositoryImpl(database);
      await workoutRepository.seedDefaultExercises();
    });

    tearDown(() async {
      await database.close();
    });

    test(
      'resolveRoutineExercises resolves all 4 exercises for Push Day with zero drops',
      () async {
        final pushExerciseIds = [
          'ex-bench-press',
          'ex-incline-db-press',
          'ex-overhead-press',
          'ex-tricep-pushdown',
        ];

        final resolved = await resolveRoutineExercises(
          workoutRepository,
          pushExerciseIds,
        );

        expect(
          resolved.length,
          equals(4),
          reason: 'All 4 push exercises must be resolved without drops',
        );
        expect(resolved[0].name.toLowerCase(), contains('bench press'));
        expect(resolved[1].name.toLowerCase(), contains('incline'));
        expect(resolved[2].name.toLowerCase(), contains('overhead press'));
        expect(resolved[3].name.toLowerCase(), contains('pushdown'));
      },
    );

    test(
      'resolveRoutineExercises handles unknown slugs gracefully with fallback entity',
      () async {
        final mixedIds = ['ex-bench-press', 'custom-unregistered-stretch'];

        final resolved = await resolveRoutineExercises(
          workoutRepository,
          mixedIds,
        );

        expect(resolved.length, equals(2));
        expect(resolved[0].name.toLowerCase(), contains('bench press'));
        expect(resolved[1].name, isNotEmpty);
        expect(resolved[1].id, equals('custom-unregistered-stretch'));
      },
    );

    test(
      'ActiveWorkoutNotifier.startNewWorkout preloads 3 sets per initial exercise',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Initially null
        expect(container.read(activeWorkoutProvider).workout, isNull);

        final dummyExercises = [
          defaultExercisesList.first, // Bench Press
          defaultExercisesList.last, // Plank
        ];

        final notifier = container.read(activeWorkoutProvider.notifier);
        notifier.startNewWorkout(
          title: 'Push Day Hypertrophy',
          initialExercises: dummyExercises,
        );

        final activeWorkout = container.read(activeWorkoutProvider).workout;
        expect(activeWorkout, isNotNull);
        expect(activeWorkout!.title, equals('Push Day Hypertrophy'));
        expect(activeWorkout.exercises.length, equals(2));

        // Each exercise should have 3 preloaded sets
        for (final ex in activeWorkout.exercises) {
          expect(
            ex.sets.length,
            equals(3),
            reason: 'Each preloaded exercise should have 3 target sets',
          );
          expect(ex.sets[0].setNumber, equals(1));
          expect(ex.sets[1].setNumber, equals(2));
          expect(ex.sets[2].setNumber, equals(3));
          expect(ex.sets[0].targetReps, greaterThan(0));
        }
      },
    );
  });
}
