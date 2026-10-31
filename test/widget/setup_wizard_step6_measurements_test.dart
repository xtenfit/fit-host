import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/profile/presentation/screens/fitness_setup_wizard_screen.dart';

void main() {
  testWidgets(
    'Step 6 Record Measurements: direct input, decimal support, and steppers',
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

      // Skip steps 1 to 5 to reach Step 6
      for (int i = 0; i < 5; i++) {
        expect(find.text('Skip'), findsOneWidget);
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();
      }

      // Verify Step 6 header and controls
      expect(find.text('Step 6 of 20'), findsOneWidget);
      expect(find.text('Record Measurements'), findsOneWidget);
      expect(find.text('Primary Metrics'), findsOneWidget);
      expect(find.text('Weight'), findsOneWidget);
      expect(find.text('Body Fat'), findsOneWidget);
      expect(find.text('Circumference Tape (cm)'), findsOneWidget);

      // Verify all 8 circumference fields exist
      expect(find.text('Waist'), findsOneWidget);
      expect(find.text('Chest'), findsOneWidget);
      expect(find.text('Hips'), findsOneWidget);
      expect(find.text('Arms / Biceps'), findsOneWidget);
      expect(find.text('Thighs'), findsOneWidget);
      expect(find.text('Calves'), findsOneWidget);
      expect(find.text('Neck'), findsOneWidget);
      expect(find.text('Shoulders'), findsOneWidget);
      expect(find.text('Notes (e.g. morning fasted weigh-in)'), findsOneWidget);
      expect(find.text('Save Measurement'), findsOneWidget);

      // Test direct text input on Waist with decimal value (e.g. 85.5)
      final waistField = find.ancestor(
        of: find.text('Waist'),
        matching: find.byType(TextField),
      );
      expect(waistField, findsOneWidget);
      await tester.enterText(waistField, '85.5');
      await tester.pumpAndSettle();
      expect(find.text('85.5'), findsOneWidget);

      // Test direct text input on Body Fat (e.g. 18.5)
      final bfField = find.ancestor(
        of: find.text('Body Fat'),
        matching: find.byType(TextField),
      );
      expect(bfField, findsOneWidget);
      await tester.enterText(bfField, '18.5');
      await tester.pumpAndSettle();
      expect(find.text('18.5'), findsOneWidget);

      // Test entering Notes
      final notesField = find.ancestor(
        of: find.text('Notes (e.g. morning fasted weigh-in)'),
        matching: find.byType(TextField),
      );
      expect(notesField, findsOneWidget);
      await tester.enterText(notesField, 'Fasted morning weigh-in');
      await tester.pumpAndSettle();
      expect(find.text('Fasted morning weigh-in'), findsOneWidget);

      // Test Unit Toggle to Inches ('in')
      final inToggle = find.text('in');
      expect(inToggle, findsOneWidget);
      await tester.tap(inToggle);
      await tester.pumpAndSettle();

      // Verify unit changed to inches in title and suffix
      expect(find.text('Circumference Tape (in)'), findsOneWidget);
      expect(find.text('in'), findsWidgets);

      // Advance to next step using Save Measurement button
      final saveBtn = find.text('Save Measurement');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();
      expect(find.text('Step 7 of 20'), findsOneWidget);
    },
  );
}
