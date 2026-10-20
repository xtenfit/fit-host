import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/profile/presentation/screens/profile_setup_screen.dart';

void main() {
  testWidgets('ProfileSetupScreen renders steps and navigates between personal info and targets',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ProfileSetupScreen(isInitialSetup: false),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & Step 1 Personal Info
    expect(find.text('Edit Profile & Targets'), findsOneWidget);
    expect(find.text('What should we call you?'), findsOneWidget);
    expect(find.text('Gender'), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);

    // Tap Continue to Step 2 (Body Stats)
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Your Body Stats'), findsOneWidget);
    expect(find.text('Age (Years)'), findsOneWidget);
    expect(find.text('Height (cm)'), findsOneWidget);
    expect(find.text('Current Weight (kg)'), findsOneWidget);

    // Tap Continue to Step 3 (Goal)
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('What is your primary goal?'), findsOneWidget);
    expect(find.text('Lose Weight (Fat Loss)'), findsOneWidget);
    expect(find.text('Gain Weight (Muscle Hypertrophy)'), findsOneWidget);
    expect(find.text('Maintain Weight & Vitality'), findsOneWidget);

    // Select Lose Weight
    await tester.tap(find.text('Lose Weight (Fat Loss)'));
    await tester.pumpAndSettle();

    // Tap Continue to Step 4 (Diet)
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Choose your diet type'), findsOneWidget);
    expect(find.text('Balanced Nutrition'), findsOneWidget);
    expect(find.text('High Protein'), findsOneWidget);
    expect(find.text('Low Carb / Keto'), findsOneWidget);

    // Tap Continue to Step 5 (Nutrition Targets)
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Nutrition & Calorie Targets'), findsOneWidget);
    expect(find.text('✨ Suggested Balanced'), findsOneWidget);
    expect(find.text('⚙️ Custom Targets'), findsOneWidget);
    expect(find.text('SCIENTIFIC RECOMMENDATION'), findsOneWidget);

    // Switch to Custom Targets
    await tester.tap(find.text('⚙️ Custom Targets'));
    await tester.pumpAndSettle();

    expect(find.text('Customize Your Daily Targets'), findsOneWidget);
    expect(find.text('Daily Calories (kcal)'), findsOneWidget);

    // Tap Continue to Step 6 (Workout Targets)
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Workout & Activity Target'), findsOneWidget);
    expect(find.text('Weekly Workout Days'), findsOneWidget);
    expect(find.text('Target Session Duration'), findsOneWidget);
    expect(find.text('Custom Fitness Target (Optional)'), findsOneWidget);

    // Verify activate button
    expect(find.text('Activate Plan & Save'), findsOneWidget);
  });
}
