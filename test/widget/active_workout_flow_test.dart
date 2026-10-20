import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/features/workouts/data/repositories/workout_repository_impl.dart';
import 'package:fit_host/features/workouts/presentation/controllers/workout_providers.dart';
import 'package:fit_host/features/workouts/presentation/screens/active_workout_screen.dart';

void main() {
  testWidgets('Active workout workflow: add exercises, complete sets, trigger rest timer and finish',
      (WidgetTester tester) async {
    final inMemoryDb = AppDatabase(NativeDatabase.memory());
    final inMemoryRepo = WorkoutRepositoryImpl(inMemoryDb);
    await inMemoryRepo.seedDefaultExercises();

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(inMemoryDb),
        workoutRepositoryProvider.overrideWithValue(inMemoryRepo),
      ],
    );

    // Start a workout via the notifier
    final allExercises = await inMemoryRepo.getExercises();
    final benchPress = allExercises.firstWhere(
      (e) => e.name == 'Bench Press (Barbell)' || e.name == 'Barbell Bench Press',
    );

    container.read(activeWorkoutProvider.notifier).startNewWorkout(
          title: 'Morning Strength',
          initialExercises: [benchPress],
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ActiveWorkoutScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify workout title and exercise present
    expect(find.text('Morning Strength'), findsOneWidget);
    expect(find.text(benchPress.name), findsOneWidget);

    // Verify initial set row (Set 1)
    expect(find.text('SET'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    // Tap complete on the set
    final completeSetButton = find.byIcon(Icons.radio_button_unchecked_rounded);
    expect(completeSetButton, findsOneWidget);
    await tester.tap(completeSetButton);
    await tester.pumpAndSettle();

    // Verify set is marked completed and rest timer banner appears
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.textContaining('Rest Timer:'), findsOneWidget);

    // Finish workout
    final finishButton = find.text('Finish');
    expect(finishButton, findsOneWidget);
    await tester.tap(finishButton);
    await tester.pumpAndSettle();

    // Verify workout saved to SQLite database
    final savedWorkouts = await inMemoryRepo.getWorkouts();
    expect(savedWorkouts.length, equals(1));
    expect(savedWorkouts.first.title, equals('Morning Strength'));
    expect(savedWorkouts.first.status, equals('completed'));
    expect(savedWorkouts.first.completedSets, equals(1));

    container.dispose();
    await inMemoryDb.close();
  });
}
