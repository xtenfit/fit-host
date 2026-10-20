import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/profile/presentation/screens/fitness_setup_wizard_screen.dart';
import 'package:fit_host/features/profile/presentation/widgets/setup/anatomy_pointer_diagram.dart';
import 'package:fit_host/features/profile/presentation/widgets/setup/goal_selection_card.dart';
import 'package:fit_host/features/profile/presentation/widgets/setup/interactive_ruler_slider.dart';

void main() {
  testWidgets('FitnessSetupWizardScreen renders 20-step setup wizard and navigates through steps',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: FitnessSetupWizardScreen(),
        ),
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
    // Step 6 of 20: Body Composition
    // -------------------------------------------------------------
    expect(find.text('Step 6 of 20'), findsOneWidget);
    expect(find.text('Body Composition'), findsOneWidget);
    expect(find.text('Estimated Body Fat'), findsOneWidget);

    // Tap NEXT to advance to Step 7 (Goals)
    await tester.tap(find.text('NEXT'));
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
  });
}
