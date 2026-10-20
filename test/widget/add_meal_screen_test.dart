import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/nutrition/data/repositories/food_repository_impl.dart';
import 'package:fit_host/features/nutrition/domain/models/food_item.dart';
import 'package:fit_host/features/nutrition/domain/repositories/food_repository.dart';
import 'package:fit_host/features/nutrition/presentation/screens/add_meal_screen.dart';

class MockFoodRepository implements FoodRepository {
  @override
  Future<List<FoodItem>> getRecentFoods({int limit = 8}) async => [];

  @override
  Future<FoodItem?> getFoodByBarcode(String barcode) async => null;

  @override
  Future<List<FoodItem>> searchFoods(String query, {int limit = 30}) async => [];

  @override
  Future<void> saveFood(FoodItem food) async {}
}

void main() {
  testWidgets('AddMealScreen renders three main entry options and recent foods header',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          foodRepositoryProvider.overrideWithValue(MockFoodRepository()),
        ],
        child: const MaterialApp(
          home: AddMealScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title and Subtitle
    expect(find.text('Add Meal'), findsOneWidget);
    expect(find.text('How would you like to log?'), findsOneWidget);

    // Verify Option 1: Scan Barcode
    expect(find.text('Scan Barcode'), findsOneWidget);
    expect(find.text('Instant nutritional facts lookup from packaged goods'), findsOneWidget);

    // Verify Option 2: Snap Meal (Gemini AI)
    expect(find.text('Snap Meal'), findsOneWidget);
    expect(find.text('AI photo breakdown into ingredients and macros'), findsOneWidget);
    expect(find.text('Gemini AI'), findsOneWidget);

    // Verify Option 3: Type / Search
    expect(find.text('Type / Search'), findsOneWidget);
    expect(find.text('Search database of 120+ staples or create custom items'), findsOneWidget);
  });
}
