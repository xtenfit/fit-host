import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/nutrition/domain/models/food_item.dart';
import 'package:fit_host/features/nutrition/presentation/screens/quantity_entry_screen.dart';
import 'package:fit_host/features/nutrition/presentation/controllers/nutrition_controller.dart';

void main() {
  final testFood = FoodItem(
    id: 'test-amul-milk',
    name: 'Amul Toned Milk',
    brand: 'Amul',
    proteinPer100g: 3.2,
    carbsPer100g: 4.8,
    fatsPer100g: 3.0,
    caloriesPer100g: 58.0,
    servingPresets: const [
      ServingPreset(label: '100g', grams: 100),
      ServingPreset(label: '1 glass (200g)', grams: 200),
    ],
  );

  Widget createWidget({WidgetRef? ref}) {
    return ProviderScope(
      child: MaterialApp(
        home: QuantityEntryScreen(food: testFood),
      ),
    );
  }

  testWidgets('QuantityEntryScreen renders initial food data and live macros',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    // Verify Food Name and Brand
    expect(find.text('Amul Toned Milk'), findsOneWidget);
    expect(find.text('Amul'), findsOneWidget);

    // Initial 100g -> 58 kcal, 3.2g protein, 4.8g carbs, 3.0g fats
    expect(find.text('58'), findsOneWidget); // 58 kcal
    expect(find.text('3.2'), findsOneWidget); // 3.2g protein
    expect(find.text('4.8'), findsOneWidget); // 4.8g carbs
    expect(find.text('3.0'), findsOneWidget); // 3.0g fats
  });

  testWidgets('Tapping preset chip updates quantity and recalculates macros live',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    // Tap preset '1 glass (200g)'
    final glassPresetFinder = find.text('1 glass (200g)');
    expect(glassPresetFinder, findsOneWidget);
    await tester.tap(glassPresetFinder);
    await tester.pumpAndSettle();

    // 200g -> 116 kcal, 6.4g protein, 9.6g carbs, 6.0g fats
    expect(find.text('116'), findsOneWidget); // 116 kcal
    expect(find.text('6.4'), findsOneWidget); // 6.4g protein
    expect(find.text('9.6'), findsOneWidget); // 9.6g carbs
    expect(find.text('6.0'), findsOneWidget); // 6.0g fats
  });

  testWidgets('Changing meal type changes selected choice chip state',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    // Select Dinner chip
    final dinnerChip = find.text('Dinner');
    expect(dinnerChip, findsOneWidget);
    await tester.tap(dinnerChip);
    await tester.pumpAndSettle();

    final choiceChipWidget = tester.widget<ChoiceChip>(
      find.ancestor(of: dinnerChip, matching: find.byType(ChoiceChip)),
    );
    expect(choiceChipWidget.selected, isTrue);
  });

  testWidgets('Saving meal logs entry into nutritionProvider state',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: QuantityEntryScreen(food: testFood),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Log to Diary
    final saveButton = find.text('Log to Diary');
    expect(saveButton, findsOneWidget);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Verify logged in nutritionProvider
    final loggedMeals = container.read(nutritionProvider).loggedMeals;
    expect(loggedMeals.any((m) => m.name.contains('Amul Toned Milk')), isTrue);
  });
}
