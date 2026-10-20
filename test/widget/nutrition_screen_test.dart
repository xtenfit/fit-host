import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/nutrition/presentation/nutrition_screen.dart';

void main() {
  testWidgets('NutritionScreen renders macro targets, hydration tracker, and recovery tips',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: NutritionScreen(),
        ),
      ),
    );

    // Verify Title
    expect(find.text('Nutrition & Fuel'), findsOneWidget);

    // Verify Offline banner
    expect(
      find.text('Track daily nutrition, calories, and macros effortlessly with smart targets.'),
      findsOneWidget,
    );

    // Verify Macro Indicators
    expect(find.text('Daily Energy Target'), findsOneWidget);
    expect(find.text('Calories'), findsOneWidget);
    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('Carbs'), findsOneWidget);
    expect(find.text('Fats'), findsOneWidget);

    // Verify Hydration Tracker
    expect(find.text('Hydration Tracker'), findsOneWidget);
    expect(find.text('0 / 10 Glasses'), findsOneWidget);

    // Scroll and Tap Add Glass
    await tester.ensureVisible(find.text('Add Glass'));
    await tester.tap(find.text('Add Glass'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 10 Glasses'), findsOneWidget);

    // Scroll and Tap Minus
    await tester.ensureVisible(find.text('Minus'));
    await tester.tap(find.text('Minus'));
    await tester.pumpAndSettle();
    expect(find.text('0 / 10 Glasses'), findsOneWidget);

    // Scroll to and Verify Whole Foods Card
    await tester.ensureVisible(find.text('Whole Foods & Protein Synthesis').first);
    expect(find.text('Whole Foods & Protein Synthesis'), findsWidgets);

    // Scroll to and Verify Rest & Recovery Card
    await tester.ensureVisible(find.text('Rest & Recovery Window'));
    expect(find.text('Rest & Recovery Window'), findsOneWidget);
    expect(find.text('7-9 hrs target'), findsOneWidget);
  });
}
