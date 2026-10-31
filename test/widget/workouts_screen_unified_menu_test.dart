import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/data/workout_repository.dart'
    show routinesStreamProvider;
import 'package:fit_host/features/workouts/domain/models/workout_models.dart';
import 'package:fit_host/features/workouts/presentation/controllers/workout_providers.dart';
import 'package:fit_host/features/workouts/presentation/screens/workouts_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.now();
  final testRoutines = [
    RoutineEntity(
      id: 'template_push_hypertrophy',
      name: 'Push Day: Chest, Shoulders & Triceps',
      description:
          'Hypertrophy focused push routine targeting pectorals, anterior delts, and triceps.',
      category: 'Strength',
      difficulty: 'intermediate',
      estimatedDurationMinutes: 45,
      isCustom: false,
      tags: const ['push', 'chest', 'shoulders', 'triceps'],
      createdAt: now,
      updatedAt: now,
      exercises: const [
        RoutineExerciseEntity(
          id: 're-1',
          routineId: 'template_push_hypertrophy',
          exerciseId: '9da7a605-e3b6-55ae-a0a0-28f417eb3a8f',
          exerciseName: 'Barbell Incline Bench Press',
          category: 'Chest',
          orderIndex: 0,
          sets: [
            RoutineSetEntity(
              id: 's-1',
              routineExerciseId: 're-1',
              setNumber: 1,
              setType: 'normal',
              targetReps: 10,
              targetWeightKg: 60.0,
            ),
            RoutineSetEntity(
              id: 's-2',
              routineExerciseId: 're-1',
              setNumber: 2,
              setType: 'normal',
              targetReps: 10,
              targetWeightKg: 60.0,
            ),
            RoutineSetEntity(
              id: 's-3',
              routineExerciseId: 're-1',
              setNumber: 3,
              setType: 'normal',
              targetReps: 10,
              targetWeightKg: 60.0,
            ),
          ],
        ),
        RoutineExerciseEntity(
          id: 're-2',
          routineId: 'template_push_hypertrophy',
          exerciseId: 'c589ed7d-b627-58f5-8c93-f58f27050f59',
          exerciseName: 'Dumbbell Incline Bench Press',
          category: 'Chest',
          orderIndex: 1,
          sets: [
            RoutineSetEntity(
              id: 's-4',
              routineExerciseId: 're-2',
              setNumber: 1,
              setType: 'normal',
              targetReps: 10,
              targetWeightKg: 24.0,
            ),
          ],
        ),
        RoutineExerciseEntity(
          id: 're-3',
          routineId: 'template_push_hypertrophy',
          exerciseId: 'bb9a1e5e-39a6-55fd-841f-2fe682cfee58',
          exerciseName: 'Barbell Seated Overhead Press',
          category: 'Shoulders',
          orderIndex: 2,
          sets: [
            RoutineSetEntity(
              id: 's-5',
              routineExerciseId: 're-3',
              setNumber: 1,
              setType: 'normal',
              targetReps: 8,
              targetWeightKg: 40.0,
            ),
          ],
        ),
        RoutineExerciseEntity(
          id: 're-4',
          routineId: 'template_push_hypertrophy',
          exerciseId: 'f568a042-4fdb-5054-9fa2-58826509f7a7',
          exerciseName: 'Cable Tricep Pushdown',
          category: 'Arms',
          orderIndex: 3,
          sets: [
            RoutineSetEntity(
              id: 's-6',
              routineExerciseId: 're-4',
              setNumber: 1,
              setType: 'normal',
              targetReps: 12,
              targetWeightKg: 25.0,
            ),
          ],
        ),
      ],
    ),
    RoutineEntity(
      id: 'custom_legs_shred',
      name: 'Custom Heavy Legs Circuit',
      description: 'Personal leg routine created for strength.',
      category: 'Strength',
      difficulty: 'advanced',
      estimatedDurationMinutes: 50,
      isCustom: true,
      tags: const ['legs', 'quads'],
      createdAt: now,
      updatedAt: now,
      exercises: const [
        RoutineExerciseEntity(
          id: 're-c1',
          routineId: 'custom_legs_shred',
          exerciseId: '8aa9e2bf-374e-53aa-9b7e-97626359b397',
          exerciseName: 'Barbell Full Squat',
          category: 'Legs',
          orderIndex: 0,
          sets: [
            RoutineSetEntity(
              id: 's-c1',
              routineExerciseId: 're-c1',
              setNumber: 1,
              setType: 'normal',
              targetReps: 8,
              targetWeightKg: 100.0,
            ),
          ],
        ),
        RoutineExerciseEntity(
          id: 're-c2',
          routineId: 'custom_legs_shred',
          exerciseId: '8e154f24-2c78-5db0-93fb-e79e6e8e894c',
          exerciseName: 'Deadlift',
          category: 'Back',
          orderIndex: 1,
          sets: [
            RoutineSetEntity(
              id: 's-c2',
              routineExerciseId: 're-c2',
              setNumber: 1,
              setType: 'normal',
              targetReps: 6,
              targetWeightKg: 120.0,
            ),
          ],
        ),
        RoutineExerciseEntity(
          id: 're-c3',
          routineId: 'custom_legs_shred',
          exerciseId: 'a3d64c2e-4b2a-5bf3-9993-9c5950d88506',
          exerciseName: 'Plank',
          category: 'Core',
          orderIndex: 2,
          sets: [
            RoutineSetEntity(
              id: 's-c3',
              routineExerciseId: 're-c3',
              setNumber: 1,
              setType: 'normal',
              targetReps: 1,
              durationSeconds: 60,
            ),
          ],
        ),
      ],
    ),
  ];

  group('WorkoutsScreen Unified Menu Widget Tests', () {
    testWidgets(
      'renders categories, routine filters, and curated routines with exact exercise counts',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              workoutsStreamProvider.overrideWith((ref) => Stream.value([])),
              routinesStreamProvider.overrideWith(
                (ref) => Stream.value(testRoutines),
              ),
            ],
            child: const MaterialApp(home: WorkoutsScreen()),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Switch to 'Routines & Plans' tab
        await tester.tap(find.text('Routines & Plans'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // 1. Verify Quick Action Buttons
        expect(find.text('Create Routine'), findsOneWidget);
        expect(find.text('Manage Routines'), findsOneWidget);

        // 2. Verify Category Carousel
        expect(find.text('Workout Categories'), findsOneWidget);
        expect(find.text('Strength'), findsWidgets);
        expect(find.text('Cardio'), findsWidgets);
        expect(find.text('HIIT'), findsWidgets);

        // 3. Verify Routine Filter Segments
        expect(find.text('All Routines'), findsOneWidget);
        expect(find.text('My Custom'), findsOneWidget);
        expect(find.text('Curated'), findsWidgets);

        // 4. Verify Curated Routine with honest 4 exercises badge
        expect(
          find.text('Push Day: Chest, Shoulders & Triceps'),
          findsOneWidget,
        );
        expect(find.text('4 Exercises'), findsOneWidget);
        expect(find.text('45 min'), findsOneWidget);

        // 5. Verify Custom Routine with honest 3 exercises badge
        expect(find.text('Custom Heavy Legs Circuit'), findsOneWidget);
        expect(find.text('3 Exercises'), findsOneWidget);
        expect(find.text('50 min'), findsOneWidget);

        // 6. Verify Exercise Preview Chips show real names and no 'Unknown Exercise'
        expect(find.text('Barbell Incline Bench Press'), findsOneWidget);
        expect(find.text('Dumbbell Incline Bench Press'), findsOneWidget);
        expect(find.text('Barbell Seated Overhead Press'), findsOneWidget);
        expect(find.text('Cable Tricep Pushdown'), findsOneWidget);
        expect(find.text('Barbell Full Squat'), findsOneWidget);
        expect(find.text('Unknown Exercise'), findsNothing);

        // 7. Verify Start Routine button exists
        expect(find.text('Start Routine'), findsWidgets);

        // 8. Test switching to "My Custom" filter
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
        await tester.pumpAndSettle();

        await tester.tap(find.text('My Custom'));
        await tester.pumpAndSettle();

        // Custom routine should be visible, Curated template should be filtered out
        expect(find.text('Custom Heavy Legs Circuit'), findsOneWidget);
        expect(find.text('Push Day: Chest, Shoulders & Triceps'), findsNothing);

        // 9. Test switching to "Curated" filter
        await tester.tap(find.text('Curated').first);
        await tester.pumpAndSettle();

        // Curated routine should be visible, Custom routine should be filtered out
        expect(
          find.text('Push Day: Chest, Shoulders & Triceps'),
          findsOneWidget,
        );
        expect(find.text('Custom Heavy Legs Circuit'), findsNothing);
      },
    );
  });
}
