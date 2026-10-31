import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/core/data/workout_repository.dart'
    show routineRepositoryProvider;
import 'package:fit_host/features/workouts/data/repositories/routine_repository_impl.dart';
import 'package:fit_host/features/workouts/data/repositories/workout_repository_impl.dart';
import 'package:fit_host/features/workouts/presentation/controllers/workout_providers.dart';
import 'package:fit_host/features/workouts/presentation/screens/all_routines_screen.dart';
import 'package:fit_host/features/workouts/presentation/screens/routine_builder_screen.dart';

void main() {
  group('Routines and RoutineBuilder Widget Tests', () {
    late AppDatabase inMemoryDb;
    late WorkoutRepositoryImpl inMemoryWorkoutRepo;
    late RoutineRepositoryImpl inMemoryRoutineRepo;
    late ProviderContainer container;

    setUp(() async {
      inMemoryDb = AppDatabase(NativeDatabase.memory());
      inMemoryWorkoutRepo = WorkoutRepositoryImpl(inMemoryDb);
      inMemoryRoutineRepo = RoutineRepositoryImpl(
        inMemoryDb,
        userId: 'test_user',
      );

      await inMemoryWorkoutRepo.seedDefaultExercises();
      await inMemoryRoutineRepo.seedTemplateRoutines();

      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(inMemoryDb),
          workoutRepositoryProvider.overrideWithValue(inMemoryWorkoutRepo),
          routineRepositoryProvider.overrideWithValue(inMemoryRoutineRepo),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await inMemoryDb.close();
    });

    testWidgets(
      'AllRoutinesScreen displays templates, switches tabs, and shows action triggers',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: AllRoutinesScreen()),
          ),
        );

        // Wait for stream data to populate
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify header and tab buttons
        expect(find.text('Workout Routines & Plans'), findsOneWidget);
        expect(find.text('All'), findsWidgets);
        expect(find.text('Templates'), findsOneWidget);
        expect(find.text('Custom'), findsOneWidget);

        // Verify seeded canonical templates appear in Templates list
        expect(
          find.text('Push Day: Chest, Shoulders & Triceps'),
          findsOneWidget,
        );
        expect(
          find.text('Pull Day: Back, Rear Delts & Biceps'),
          findsOneWidget,
        );

        // Switch tab to "Custom"
        await tester.tap(find.text('Custom'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify empty state for custom routines
        expect(find.text('No custom routines yet'), findsOneWidget);

        // Verify Floating Action Button to create a routine exists
        expect(find.byType(FloatingActionButton), findsOneWidget);
      },
    );

    testWidgets(
      'RoutineBuilderScreen enforces exercise validation and saves edited routine',
      (WidgetTester tester) async {
        // 1. Verify validation on empty routine
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: RoutineBuilderScreen()),
          ),
        );

        await tester.pumpAndSettle();

        final titleField = find.byType(TextFormField).first;
        await tester.enterText(titleField, 'Empty Test Routine');
        await tester.pumpAndSettle();

        // Attempt save with 0 exercises
        final saveButton = find.text('Save');
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        // Verify snackbar validation
        expect(
          find.text('Please add at least one exercise to your routine.'),
          findsOneWidget,
        );

        // 2. Open RoutineBuilder with existing template to edit and persist
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: RoutineBuilderScreen(
                key: ValueKey('edit_builder'),
                routineId: 'template_push_hypertrophy',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify loaded template AppBar title is 'Edit Routine'
        expect(find.text('Edit Routine'), findsOneWidget);

        // Edit title
        final editTitleField = find.byType(TextFormField).first;
        await tester.enterText(editTitleField, 'Push Day Customized');
        await tester.pumpAndSettle();

        // Tap Save
        final saveBtn = find.text('Save');
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        // Verify saved in repository
        final routines = await inMemoryRoutineRepo.getRoutines();
        expect(routines.any((r) => r.name == 'Push Day Customized'), isTrue);
      },
    );
  });
}
