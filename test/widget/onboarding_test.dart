import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/onboarding/presentation/onboarding_screen.dart';

void main() {
  testWidgets('OnboardingScreen renders Step 1 Welcome, pillars, and navigates through steps',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OnboardingScreen(),
        ),
      ),
    );

    // Verify presence of Value Pillars on Step 1
    expect(find.text('Sync Across Devices'), findsOneWidget);
    expect(find.text('Progressive Overload Tracking'), findsOneWidget);
    expect(find.text('Private by Default'), findsOneWidget);

    // Verify Primary Action
    expect(find.text('Start Personalization →'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);

    // Tap Start Personalization to move to Step 2 (Gender)
    await tester.tap(find.text('Start Personalization →'));
    await tester.pumpAndSettle();

    expect(find.text('Step 2 of 16'), findsOneWidget);
    expect(find.text("What's your gender?"), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    expect(find.text('Prefer not to say'), findsOneWidget);

    // Select Male
    await tester.tap(find.text('Male'));
    await tester.pumpAndSettle();

    // Tap Continue to move to Step 3 (Age)
    await tester.tap(find.text('Continue →'));
    await tester.pumpAndSettle();

    expect(find.text('Step 3 of 16'), findsOneWidget);
    expect(find.text('How old are you?'), findsOneWidget);

    // Tap Back button to return to Step 2
    final backButton = find.byIcon(Icons.arrow_back_rounded);
    expect(backButton, findsOneWidget);
    await tester.tap(backButton);
    await tester.pumpAndSettle();

    expect(find.text('Step 2 of 16'), findsOneWidget);
    expect(find.text("What's your gender?"), findsOneWidget);
  });
}
