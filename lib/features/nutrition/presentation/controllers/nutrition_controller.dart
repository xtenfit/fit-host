import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/nutrition_models.dart';

const _uuid = Uuid();

final List<MealItem> defaultPresetMeals = [
  // --- VEGAN ROUTINE PRESETS ---
  MealItem(
    id: 'vegan-1',
    name: 'Tofu Scramble with Spinach & Avocado',
    mealType: 'breakfast',
    dietType: 'vegan',
    calories: 340,
    proteinGrams: 22,
    carbsGrams: 14,
    fatGrams: 21,
    portion: '1 plate (250g)',
    loggedAt: DateTime.now(),
  ),
  MealItem(
    id: 'vegan-2',
    name: 'Chickpea & Quinoa Power Bowl',
    mealType: 'lunch',
    dietType: 'vegan',
    calories: 480,
    proteinGrams: 24,
    carbsGrams: 64,
    fatGrams: 14,
    portion: '1 large bowl (380g)',
    loggedAt: DateTime.now(),
  ),
  MealItem(
    id: 'vegan-3',
    name: 'Red Lentil Dal with Brown Basmati Rice',
    mealType: 'dinner',
    dietType: 'vegan',
    calories: 430,
    proteinGrams: 21,
    carbsGrams: 70,
    fatGrams: 7,
    portion: '1 bowl + 1 cup rice',
    loggedAt: DateTime.now(),
  ),
  MealItem(
    id: 'vegan-4',
    name: 'Pea Protein Shake with Rolled Oats & PB',
    mealType: 'snack',
    dietType: 'vegan',
    calories: 410,
    proteinGrams: 35,
    carbsGrams: 42,
    fatGrams: 12,
    portion: '500ml shaker',
    loggedAt: DateTime.now(),
  ),
  MealItem(
    id: 'vegan-5',
    name: 'Tempeh & Sesame Broccoli Stir-Fry',
    mealType: 'dinner',
    dietType: 'vegan',
    calories: 395,
    proteinGrams: 31,
    carbsGrams: 24,
    fatGrams: 19,
    portion: '1 plate (300g)',
    loggedAt: DateTime.now(),
  ),
  MealItem(
    id: 'vegan-6',
    name: 'Chia Seed & Almond Milk Berry Pudding',
    mealType: 'snack',
    dietType: 'vegan',
    calories: 250,
    proteinGrams: 9,
    carbsGrams: 28,
    fatGrams: 12,
    portion: '1 glass jar (200g)',
    loggedAt: DateTime.now(),
  ),

  // --- NON-VEG ROUTINE PRESETS ---
  MealItem(
    id: 'nonveg-1',
    name: 'Whole Egg & Egg White Scramble with Oats',
    mealType: 'breakfast',
    dietType: 'non_veg',
    calories: 420,
    proteinGrams: 34,
    carbsGrams: 38,
    fatGrams: 14,
    portion: '3 eggs + 50g oats',
    loggedAt: DateTime.now(),
  ),
  MealItem(
    id: 'nonveg-2',
    name: 'Grilled Herb Chicken Breast with Sweet Potato',
    mealType: 'lunch',
    dietType: 'non_veg',
    calories: 490,
    proteinGrams: 52,
    carbsGrams: 45,
    fatGrams: 8,
    portion: '200g chicken + 150g potato',
    loggedAt: DateTime.now(),
  ),
  MealItem(
    id: 'nonveg-3',
    name: 'Wild Atlantic Salmon Fillet with Asparagus',
    mealType: 'dinner',
    dietType: 'non_veg',
    calories: 520,
    proteinGrams: 44,
    carbsGrams: 10,
    fatGrams: 29,
    portion: '220g salmon + greens',
    loggedAt: DateTime.now(),
  ),
  MealItem(
    id: 'nonveg-4',
    name: 'Grass-Fed Lean Beef Bowl with Jasmine Rice',
    mealType: 'dinner',
    dietType: 'non_veg',
    calories: 590,
    proteinGrams: 48,
    carbsGrams: 58,
    fatGrams: 16,
    portion: '180g beef + 1 cup rice',
    loggedAt: DateTime.now(),
  ),
  MealItem(
    id: 'nonveg-5',
    name: 'Cold-Filtered Whey Isolate Shake & Banana',
    mealType: 'snack',
    dietType: 'non_veg',
    calories: 260,
    proteinGrams: 32,
    carbsGrams: 29,
    fatGrams: 2,
    portion: '1 scoop + 1 banana',
    loggedAt: DateTime.now(),
  ),
  MealItem(
    id: 'nonveg-6',
    name: 'Greek Yogurt with Raw Honey & Crushed Walnuts',
    mealType: 'snack',
    dietType: 'non_veg',
    calories: 310,
    proteinGrams: 25,
    carbsGrams: 27,
    fatGrams: 11,
    portion: '250g Greek yogurt',
    loggedAt: DateTime.now(),
  ),
];

class NutritionNotifier extends Notifier<DailyNutritionState> {
  @override
  DailyNutritionState build() {
    // Seed with initial realistic meal history for the current day
    return DailyNutritionState(
      loggedMeals: [
        defaultPresetMeals[0].copyWith(id: _uuid.v4()), // Tofu scramble or egg scramble
        defaultPresetMeals[7].copyWith(id: _uuid.v4()), // Grilled chicken
      ],
    );
  }

  void logMeal(MealItem meal) {
    final entry = meal.copyWith(
      id: _uuid.v4(),
      loggedAt: DateTime.now(),
    );
    state = state.copyWith(
      loggedMeals: [...state.loggedMeals, entry],
    );
  }

  void removeLoggedMeal(String mealId) {
    state = state.copyWith(
      loggedMeals: state.loggedMeals.where((m) => m.id != mealId).toList(),
    );
  }

  void addCustomMeal(MealItem meal) {
    final custom = meal.copyWith(
      id: _uuid.v4(),
      isCustom: true,
      loggedAt: DateTime.now(),
    );
    state = state.copyWith(
      customMeals: [...state.customMeals, custom],
      loggedMeals: [...state.loggedMeals, custom],
    );
  }

  void setDietFilter(String filter) {
    state = state.copyWith(dietFilter: filter);
  }

  void setGoalMode(String mode) {
    switch (mode) {
      case 'hypertrophy':
        state = state.copyWith(
          goalMode: 'hypertrophy',
          targetCalories: 2650,
          targetProtein: 185,
          targetCarbs: 290,
          targetFat: 68,
        );
        break;
      case 'cutting':
        state = state.copyWith(
          goalMode: 'cutting',
          targetCalories: 1950,
          targetProtein: 190,
          targetCarbs: 165,
          targetFat: 50,
        );
        break;
      case 'recomp':
        state = state.copyWith(
          goalMode: 'recomp',
          targetCalories: 2300,
          targetProtein: 165,
          targetCarbs: 235,
          targetFat: 60,
        );
        break;
    }
  }

  void addBurnedCalories(int delta) {
    state = state.copyWith(
      manualCaloriesBurned: (state.manualCaloriesBurned + delta).clamp(0, 5000),
    );
  }

  void setWater(int count) {
    state = state.copyWith(
      waterGlasses: count.clamp(0, state.targetWater),
    );
  }

  void incrementWater() {
    if (state.waterGlasses < state.targetWater) {
      state = state.copyWith(waterGlasses: state.waterGlasses + 1);
    }
  }

  void decrementWater() {
    if (state.waterGlasses > 0) {
      state = state.copyWith(waterGlasses: state.waterGlasses - 1);
    }
  }
}

final nutritionProvider =
    NotifierProvider<NutritionNotifier, DailyNutritionState>(
  NutritionNotifier.new,
);
