import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/core/data/workout_repository.dart'
    show routineRepositoryProvider;
import 'package:fit_host/features/workouts/data/repositories/routine_repository_impl.dart';
import 'package:fit_host/features/workouts/data/repositories/workout_repository_impl.dart';
import 'package:fit_host/features/workouts/data/routine_service.dart';
import 'package:fit_host/features/workouts/presentation/controllers/workout_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Workout Routine Preloading & Honest Counts Tests', () {
    late AppDatabase database;
    late WorkoutRepositoryImpl workoutRepository;
    late RoutineRepositoryImpl routineRepository;
    late ProviderContainer container;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      workoutRepository = WorkoutRepositoryImpl(database);
      routineRepository = RoutineRepositoryImpl(database, userId: 'test_user');

      await workoutRepository.seedDefaultExercises();
      await routineRepository.seedTemplateRoutines();

      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
          workoutRepositoryProvider.overrideWithValue(workoutRepository),
          routineRepositoryProvider.overrideWithValue(routineRepository),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await database.close();
    });

    test(
      'resolveRoutineExercises resolves all exercises without losing any',
      () async {
        final pushRoutineExercises = [
          'ex-bench-press',
          'ex-incline-db-press',
          'ex-overhead-press',
          'ex-tricep-pushdown',
        ];

        final resolved = await resolveRoutineExercises(
          workoutRepository,
          pushRoutineExercises,
        );

        // Verify all 4 are resolved
        expect(resolved.length, equals(4));

        // Verify names are human-readable and accurate
        final names = resolved.map((e) => e.name).toList();
        expect(names.any((n) => n.toLowerCase().contains('bench')), isTrue);
        expect(names.any((n) => n.toLowerCase().contains('incline')), isTrue);
        expect(names.any((n) => n.toLowerCase().contains('overhead')), isTrue);
        expect(
          names.any(
            (n) =>
                n.toLowerCase().contains('pushdown') ||
                n.toLowerCase().contains('tricep'),
          ),
          isTrue,
        );
      },
    );

    test(
      'startFromRoutine preloads all exercises with 3 target sets into ActiveWorkoutNotifier',
      () async {
        final routines = await routineRepository.getRoutines();
        final pushRoutine = routines.firstWhere(
          (r) => r.id == 'template_push_hypertrophy',
        );

        expect(pushRoutine.exercises.length, equals(4));

        // Start workout from routine
        container
            .read(activeWorkoutProvider.notifier)
            .startFromRoutine(pushRoutine);

        final state = container.read(activeWorkoutProvider);
        expect(state.isActive, isTrue);
        expect(state.workout, isNotNull);
        expect(state.workout!.title, equals(pushRoutine.name));
        expect(state.workout!.routineId, equals(pushRoutine.id));

        // Verify all 4 exercises are loaded in active workout
        expect(state.workout!.exercises.length, equals(4));

        // Verify each exercise has preloaded target sets (never empty)
        for (final exercise in state.workout!.exercises) {
          expect(exercise.sets.length >= 3, isTrue);
          for (final s in exercise.sets) {
            expect(s.reps > 0, isTrue);
            expect(s.weightKg > 0, isTrue);
          }
        }
      },
    );

    test(
      'startNewWorkout with initialExercises preloads 3 sets per exercise',
      () async {
        final resolved = await resolveRoutineExercises(workoutRepository, [
          'ex-bench-press',
          'ex-squat',
        ]);

        container
            .read(activeWorkoutProvider.notifier)
            .startNewWorkout(
              title: 'Custom Push Session',
              initialExercises: resolved,
            );

        final state = container.read(activeWorkoutProvider);
        expect(state.isActive, isTrue);
        expect(state.workout, isNotNull);
        expect(state.workout!.exercises.length, equals(2));
        for (final exercise in state.workout!.exercises) {
          expect(exercise.sets.length, equals(3));
        }
      },
    );
  });
}
