import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/features/workouts/data/routine_service.dart';
import 'package:fit_host/features/workouts/domain/models/workout_models.dart';
import 'package:fit_host/features/workouts/presentation/controllers/workout_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Workout Routine Preloading & Exercise Count Validation', () {
    late AppDatabase database;
    late ProviderContainer container;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(database)],
      );
    });

    tearDown(() async {
      container.dispose();
      await database.close();
    });

    test(
      'resolveRoutineExercises resolves all Push Day Hypertrophy exercises',
      () async {
        final pushExerciseIds = [
          'ex-bench-press',
          'ex-incline-db-press',
          'ex-overhead-press',
          'ex-tricep-pushdown',
        ];

        final resolved = await resolveRoutineExercises(null, pushExerciseIds);

        expect(
          resolved.length,
          equals(4),
          reason: 'All 4 exercises in Push Day must be resolved',
        );
        for (final ex in resolved) {
          expect(ex.name, isNot(equals('Unknown Exercise')));
          expect(ex.name, isNotEmpty);
        }
        expect(resolved[0].name.toLowerCase(), contains('bench'));
        expect(resolved[1].name.toLowerCase(), contains('incline'));
        expect(resolved[2].name.toLowerCase(), contains('press'));
        expect(resolved[3].name.toLowerCase(), contains('pushdown'));
      },
    );

    test('resolveRoutineExercises resolves all Pull Day exercises', () async {
      final pullExerciseIds = [
        'ex-deadlift',
        'ex-pullup',
        'ex-barbell-row',
        'ex-bicep-curl',
      ];

      final resolved = await resolveRoutineExercises(null, pullExerciseIds);

      expect(resolved.length, equals(4));
      for (final ex in resolved) {
        expect(ex.name, isNot(equals('Unknown Exercise')));
        expect(ex.name, isNotEmpty);
      }
    });

    test(
      'ActiveWorkoutNotifier preloads 3 sets per exercise when starting from routine',
      () {
        final notifier = container.read(activeWorkoutProvider.notifier);

        final testRoutine = RoutineEntity(
          id: 'test-push-day',
          userId: 'test-user',
          name: 'Push Day Hypertrophy',
          description: 'Target chest, front delts, and triceps',
          category: 'Strength',
          estimatedDurationMinutes: 45,
          isTemplate: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          exercises: [
            RoutineExerciseEntity(
              id: 're-1',
              routineId: 'test-push-day',
              exerciseId: 'ex-bench-press',
              exerciseName: 'Barbell Bench Press',
              category: 'Strength',
              orderIndex: 0,
              sets: [],
            ),
            RoutineExerciseEntity(
              id: 're-2',
              routineId: 'test-push-day',
              exerciseId: 'ex-incline-db-press',
              exerciseName: 'Incline Dumbbell Press',
              category: 'Strength',
              orderIndex: 1,
              sets: [],
            ),
            RoutineExerciseEntity(
              id: 're-3',
              routineId: 'test-push-day',
              exerciseId: 'ex-overhead-press',
              exerciseName: 'Barbell Overhead Press',
              category: 'Strength',
              orderIndex: 2,
              sets: [],
            ),
            RoutineExerciseEntity(
              id: 're-4',
              routineId: 'test-push-day',
              exerciseId: 'ex-tricep-pushdown',
              exerciseName: 'Tricep Cable Pushdown',
              category: 'Strength',
              orderIndex: 3,
              sets: [],
            ),
          ],
        );

        notifier.startFromRoutine(testRoutine);

        final state = container.read(activeWorkoutProvider);
        expect(state.isActive, isTrue);
        expect(state.workout, isNotNull);
        expect(
          state.workout!.exercises.length,
          equals(4),
          reason: 'All 4 routine exercises must be preloaded in active session',
        );

        for (final ex in state.workout!.exercises) {
          expect(
            ex.sets.length,
            equals(3),
            reason:
                '${ex.exerciseName} must have 3 default structured sets preloaded',
          );
          for (var i = 0; i < ex.sets.length; i++) {
            final s = ex.sets[i];
            expect(s.setNumber, equals(i + 1));
            expect(s.isCompleted, isFalse);
            expect(s.reps, equals(10));
            expect(s.weightKg, equals(20.0));
          }
        }
      },
    );

    test(
      'startNewWorkout with initialExercises preloads 3 sets per exercise',
      () {
        final notifier = container.read(activeWorkoutProvider.notifier);

        final initial = <ExerciseEntity>[
          ExerciseEntity(
            id: 'ex-squat',
            name: 'Barbell Back Squat',
            category: 'Strength',
            targetMuscle: 'quadriceps',
            secondaryMuscles: const ['hamstrings', 'calves'],
            equipment: 'barbell',
            instructions: 'Squat with good depth',
            createdAt: DateTime.now(),
          ),
          ExerciseEntity(
            id: 'ex-bench',
            name: 'Flat Bench Press',
            category: 'Strength',
            targetMuscle: 'chest',
            secondaryMuscles: const ['triceps'],
            equipment: 'barbell',
            instructions: 'Press barbell from chest',
            createdAt: DateTime.now(),
          ),
        ];

        notifier.startNewWorkout(
          title: 'Custom Session',
          initialExercises: initial,
        );

        final state = container.read(activeWorkoutProvider);
        expect(state.isActive, isTrue);
        expect(state.workout!.exercises.length, equals(2));
        for (final ex in state.workout!.exercises) {
          expect(
            ex.sets.length,
            equals(3),
            reason: 'Each initial exercise must have 3 default sets',
          );
        }
      },
    );
  });
}
