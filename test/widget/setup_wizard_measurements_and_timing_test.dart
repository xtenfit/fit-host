import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/profile/presentation/screens/fitness_setup_wizard_screen.dart';

void main() {
  testWidgets(
    'Setup Wizard: Individual skipping, 8 tape measurements, workout time, and meal timings',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: FitnessSetupWizardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // -------------------------------------------------------------
      // Test 1: Individual Step Skipping works on step 1 (Gender)
      // -------------------------------------------------------------
      expect(find.text('Step 1 of 20'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Advances to Step 2 of 20 (Age)
      expect(find.text('Step 2 of 20'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Advances to Step 3 of 20 (Height)
      expect(find.text('Step 3 of 20'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Advances to Step 4 of 20 (Weight)
      expect(find.text('Step 4 of 20'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Advances to Step 5 of 20 (Target Weight)
      expect(find.text('Step 5 of 20'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // -------------------------------------------------------------
      // Test 2: Step 6 of 20 (Record Measurements)
      // -------------------------------------------------------------
      expect(find.text('Step 6 of 20'), findsOneWidget);
      expect(find.text('Record Measurements'), findsOneWidget);
      expect(find.text('Primary Metrics'), findsOneWidget);
      expect(find.text('Weight'), findsOneWidget);
      expect(find.text('Body Fat'), findsOneWidget);
      expect(find.text('Circumference Tape (cm)'), findsOneWidget);

      // All 8 circumference labels are present
      expect(find.text('Waist'), findsOneWidget);
      expect(find.text('Chest'), findsOneWidget);
      expect(find.text('Hips'), findsOneWidget);
      expect(find.text('Arms / Biceps'), findsOneWidget);
      expect(find.text('Thighs'), findsOneWidget);
      expect(find.text('Calves'), findsOneWidget);
      expect(find.text('Neck'), findsOneWidget);
      expect(find.text('Shoulders'), findsOneWidget);

      // Notes field
      expect(find.text('Notes (e.g. morning fasted weigh-in)'), findsOneWidget);

      // Save Measurement button is present
      expect(find.text('Save Measurement'), findsOneWidget);

      // Tap Save Measurement to advance past measurements to goals
      await tester.tap(find.text('Save Measurement'));
      await tester.pumpAndSettle();

      // Step 7: Goals (can also be skipped individually)
      expect(find.text('Step 7 of 20'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Step 8: Gender Goals
      expect(find.text('Step 8 of 20'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Step 9: Focus Area
      expect(find.text('Step 9 of 20'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Step 10: Experience
      expect(find.text('Step 10 of 20'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Step 11: Location
      expect(find.text('Step 11 of 20'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Step 12: Equipment
      expect(find.text('Step 12 of 20'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // -------------------------------------------------------------
      // Test 3: Step 13 of 20 (Weekly Schedule & Regular Workout Time)
      // -------------------------------------------------------------
      expect(find.text('Step 13 of 20'), findsOneWidget);
      expect(find.text('Regular Workout Time'), findsOneWidget);
      expect(find.text('Custom Workout Time'), findsOneWidget);
      expect(find.textContaining('Morning'), findsOneWidget);
      expect(find.textContaining('Evening'), findsOneWidget);

      // Tap Evening preset chip
      await tester.tap(find.textContaining('Evening'));
      await tester.pumpAndSettle();
      expect(find.text('5:30 PM'), findsOneWidget);

      // Skip to Duration
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Step 14: Duration
      expect(find.text('Step 14 of 20'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Step 15: Diet Style
      expect(find.text('Step 15 of 20'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // -------------------------------------------------------------
      // Test 4: Step 16 of 20 (Meals & Meal Timing Schedule)
      // -------------------------------------------------------------
      expect(find.text('Step 16 of 20'), findsOneWidget);
      expect(find.text('Daily meal frequency'), findsOneWidget);
      expect(find.text('Meal Timing Schedule'), findsOneWidget);

      // Default 3 meals
      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('Dinner'), findsOneWidget);

      // Select 4 Meals / Day
      await tester.tap(find.text('4 Meals / Day'));
      await tester.pumpAndSettle();

      // Now 4 meals appear in schedule
      expect(find.text('Pre/Post Workout Snack'), findsOneWidget);

      // Select 2 Meals / Day
      await tester.tap(find.text('2 Meals / Day'));
      await tester.pumpAndSettle();

      expect(find.text('Brunch / Meal 1'), findsOneWidget);
      expect(find.text('Dinner / Meal 2'), findsOneWidget);
    },
  );
}
