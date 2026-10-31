import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/profile/presentation/screens/fitness_setup_wizard_screen.dart';
import 'package:fit_host/features/profile/presentation/widgets/setup/anatomy_pointer_diagram.dart';
import 'package:fit_host/features/profile/presentation/widgets/setup/goal_selection_card.dart';
import 'package:fit_host/features/profile/presentation/widgets/setup/interactive_ruler_slider.dart';

void main() {
  testWidgets(
    'FitnessSetupWizardScreen renders 20-step setup wizard and navigates through steps',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
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
      // Step 1 of 20: Gender Selection
      // -------------------------------------------------------------
      expect(find.text('Step 1 of 20'), findsOneWidget);
      expect(find.text("What's your gender?"), findsOneWidget);
      expect(find.text('NEXT'), findsOneWidget);
      expect(find.text('Male'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);

      // Verify Set Name chip & bottom sheet flow
      expect(find.text('Set Name'), findsOneWidget);
      await tester.tap(find.text('Set Name'));
      await tester.pumpAndSettle();

      // Verify Set Athlete Name sheet opens with direct name TextField
      expect(find.text('Set Athlete Name'), findsOneWidget);
      expect(find.text('SAVE NAME'), findsOneWidget);
      final nameField = find.byType(TextField);
      expect(nameField, findsOneWidget);
      await tester.enterText(nameField, 'Alex Hunter');
      await tester.pumpAndSettle();

      // Save Name and verify sheet closes cleanly and updates the chip
      await tester.tap(find.text('SAVE NAME'));
      await tester.pumpAndSettle();
      expect(find.text('Set Athlete Name'), findsNothing);
      expect(find.text('Alex Hunter'), findsOneWidget);

      // Tap NEXT to advance to Step 2 (Age)
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      // -------------------------------------------------------------
      // Step 2 of 20: Age
      // -------------------------------------------------------------
      expect(find.text('Step 2 of 20'), findsOneWidget);
      expect(find.text('How old are you?'), findsOneWidget);
      expect(find.byType(InteractiveRulerSlider), findsOneWidget);

      // Tap NEXT to advance to Step 3 (Height)
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      // -------------------------------------------------------------
      // Step 3 of 20: Height
      // -------------------------------------------------------------
      expect(find.text('Step 3 of 20'), findsOneWidget);
      expect(find.text('How tall are you?'), findsOneWidget);
      expect(find.text('cm'), findsOneWidget);

      // Toggle unit to cm
      await tester.tap(find.text('cm'));
      await tester.pumpAndSettle();

      // Tap NEXT to advance to Step 4 (Weight)
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      // -------------------------------------------------------------
      // Step 4 of 20: Current Weight
      // -------------------------------------------------------------
      expect(find.text('Step 4 of 20'), findsOneWidget);
      expect(find.text('Current weight?'), findsOneWidget);
      expect(find.text('Calculated BMI'), findsOneWidget);

      // Tap NEXT to advance to Step 5 (Target Weight)
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      // -------------------------------------------------------------
      // Step 5 of 20: Target Weight & Pace
      // -------------------------------------------------------------
      expect(find.text('Step 5 of 20'), findsOneWidget);
      expect(find.text('Target weight & pace'), findsOneWidget);
      expect(find.text('Weekly Desired Pace'), findsOneWidget);

      // Tap NEXT to advance to Step 6 (Body Composition)
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      // -------------------------------------------------------------
      // Step 6 of 20: Record Measurements & 8 Circumference Inputs
      // -------------------------------------------------------------
      expect(find.text('Step 6 of 20'), findsOneWidget);
      expect(find.text('Record Measurements'), findsOneWidget);
      expect(find.text('Circumference Tape (cm)'), findsOneWidget);
      expect(find.text('Waist'), findsOneWidget);
      expect(find.text('Chest'), findsOneWidget);
      expect(find.text('Hips'), findsOneWidget);
      expect(find.text('Arms / Biceps'), findsOneWidget);
      expect(find.text('Thighs'), findsOneWidget);
      expect(find.text('Calves'), findsOneWidget);
      expect(find.text('Neck'), findsOneWidget);
      expect(find.text('Shoulders'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      // Verify Primary Metrics, notes, and Save Measurement action button
      expect(find.text('Primary Metrics'), findsOneWidget);
      expect(find.text('Weight'), findsOneWidget);
      expect(find.text('Body Fat'), findsOneWidget);
      expect(find.text('Notes (e.g. morning fasted weigh-in)'), findsOneWidget);
      expect(find.text('Save Measurement'), findsOneWidget);

      // Tap Save Measurement to advance to Step 7 (Goals)
      await tester.tap(find.text('Save Measurement'));
      await tester.pumpAndSettle();

      // -------------------------------------------------------------
      // Step 7 of 20: Primary Fitness Goals
      // -------------------------------------------------------------
      expect(find.text('Step 7 of 20'), findsOneWidget);
      expect(find.text("What's your primary goal?"), findsOneWidget);
      expect(find.byType(GoalSelectionCard), findsNWidgets(3));
      expect(find.text('Lose Weight'), findsOneWidget);
      expect(find.text('Build Muscle'), findsOneWidget);
      expect(find.text('Keep Fit'), findsOneWidget);

      // Tap NEXT to advance to Step 8 (Gender Aesthetic Goals)
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      // -------------------------------------------------------------
      // Step 8 of 20: Gender Aesthetic Specialization
      // -------------------------------------------------------------
      expect(find.text('Step 8 of 20'), findsOneWidget);
      expect(find.text('Male aesthetic focus'), findsOneWidget);

      // Tap NEXT to advance to Step 9 (Anatomy Focus Area)
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      // -------------------------------------------------------------
      // Step 9 of 20: Focus Target Muscle Areas
      // -------------------------------------------------------------
      expect(find.text('Step 9 of 20'), findsOneWidget);
      expect(find.text('Please choose your focus area'), findsOneWidget);
      expect(find.byType(AnatomyPointerDiagram), findsOneWidget);
    },
  );
}
