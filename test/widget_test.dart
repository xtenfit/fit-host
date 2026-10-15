import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/features/workouts/data/repositories/workout_repository_impl.dart';
import 'package:fit_host/features/workouts/presentation/controllers/workout_providers.dart';
import 'package:fit_host/main.dart';

void main() {
  testWidgets('Fit Host initial smoke test: renders navigation bar and home dashboard',
      (WidgetTester tester) async {
    final inMemoryDb = AppDatabase(NativeDatabase.memory());
    final inMemoryRepo = WorkoutRepositoryImpl(inMemoryDb);
    await inMemoryRepo.seedDefaultExercises();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(inMemoryDb),
          workoutRepositoryProvider.overrideWithValue(inMemoryRepo),
        ],
        child: const FitHostApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Brand Logo Assets & ensure Offline First badge is removed from AppBar
    expect(find.text('Offline First'), findsNothing);
    expect(find.byType(Image), findsWidgets);

    // Verify Primary Navigation destinations (Home, Workouts, Activity, My Diary, Profile)
    expect(find.text('Home'), findsWidgets);
    expect(find.byIcon(Icons.fitness_center_outlined), findsWidgets);
    expect(find.byIcon(Icons.show_chart_rounded), findsWidgets);
    expect(find.byIcon(Icons.receipt_long_outlined), findsWidgets);
    expect(find.byIcon(Icons.person_outline_rounded), findsWidgets);

    // Verify Today's Workout section
    expect(find.text("Today's Workout"), findsOneWidget);

    // Navigate to Workouts tab via custom dock
    await tester.tap(find.byIcon(Icons.fitness_center_outlined));
    await tester.pumpAndSettle();
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Routines & Plans'), findsOneWidget);

    // Navigate to Activity/Progress tab
    await tester.tap(find.byIcon(Icons.show_chart_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Progress & Analytics'), findsOneWidget);

    // Navigate to Nutrition/Diary tab
    await tester.tap(find.byIcon(Icons.receipt_long_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Nutrition & Fuel'), findsOneWidget);

    // Navigate to Profile tab
    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Profile & Settings'), findsOneWidget);
    expect(find.text('Offline Athlete'), findsOneWidget);

    await inMemoryDb.close();
  });
}
