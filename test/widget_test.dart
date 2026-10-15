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

    // Verify Brand Title & Offline badge
    expect(find.text('FIT HOST'), findsOneWidget);
    expect(find.text('Offline First'), findsOneWidget);

    // Verify Primary Navigation destinations (Home, Workouts, Progress, Nutrition, Profile)
    expect(find.widgetWithText(NavigationDestination, 'Home'), findsOneWidget);
    expect(find.widgetWithText(NavigationDestination, 'Workouts'), findsOneWidget);
    expect(find.widgetWithText(NavigationDestination, 'Progress'), findsOneWidget);
    expect(find.widgetWithText(NavigationDestination, 'Nutrition'), findsOneWidget);
    expect(find.widgetWithText(NavigationDestination, 'Profile'), findsOneWidget);

    // Verify Start Quick Workout button
    expect(find.text('Start Quick Workout'), findsOneWidget);

    // Navigate to Workouts tab via Navigation Destination
    await tester.tap(find.widgetWithText(NavigationDestination, 'Workouts'));
    await tester.pumpAndSettle();
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Routines & Plans'), findsOneWidget);

    // Navigate to Progress tab
    await tester.tap(find.widgetWithText(NavigationDestination, 'Progress'));
    await tester.pumpAndSettle();
    expect(find.text('Progress & Analytics'), findsOneWidget);

    // Navigate to Nutrition tab
    await tester.tap(find.widgetWithText(NavigationDestination, 'Nutrition'));
    await tester.pumpAndSettle();
    expect(find.text('Nutrition & Fuel'), findsOneWidget);

    // Navigate to Profile tab
    await tester.tap(find.widgetWithText(NavigationDestination, 'Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Profile & Settings'), findsOneWidget);
    expect(find.text('Offline Athlete'), findsOneWidget);

    await inMemoryDb.close();
  });
}
