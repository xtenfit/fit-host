import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/nutrition_models.dart';
import 'package:fit_host/core/data/nutrition_repository.dart';

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

  // --- VEGETARIAN PRESETS ---
  MealItem(
    id: 'veg-1',
    name: 'Paneer & Spinach Bhurji with Multigrain Toast',
    mealType: 'breakfast',
    dietType: 'vegetarian',
    calories: 380,
    proteinGrams: 24,
    carbsGrams: 22,
    fatGrams: 22,
    portion: '150g paneer + 2 slices toast',
    loggedAt: DateTime.now(),
  ),
  MealItem(
    id: 'veg-2',
    name: 'Spiced Greek Yogurt & Grilled Paneer Bowl',
    mealType: 'lunch',
    dietType: 'vegetarian',
    calories: 460,
    proteinGrams: 36,
    carbsGrams: 28,
    fatGrams: 22,
    portion: '1 bowl (350g)',
    loggedAt: DateTime.now(),
  ),
  MealItem(
    id: 'veg-3',
    name: 'Tofu & Edamame Soba Noodle Bowl',
    mealType: 'dinner',
    dietType: 'vegetarian',
    calories: 490,
    proteinGrams: 32,
    carbsGrams: 62,
    fatGrams: 12,
    portion: '1 large bowl (400g)',
    loggedAt: DateTime.now(),
  ),
  MealItem(
    id: 'veg-4',
    name: 'Cottage Cheese Berry Parfait with Chia Seeds',
    mealType: 'snack',
    dietType: 'vegetarian',
    calories: 260,
    proteinGrams: 28,
    carbsGrams: 18,
    fatGrams: 6,
    portion: '200g bowl',
    loggedAt: DateTime.now(),
  ),

  // --- HIGH PROTEIN PRESETS ---
  MealItem(
    id: 'hipro-1',
    name: 'Triple Egg White Omelette with Smoked Salmon',
    mealType: 'breakfast',
    dietType: 'high_protein',
    calories: 340,
    proteinGrams: 42,
    carbsGrams: 4,
    fatGrams: 16,
    portion: '3 egg whites + 1 whole egg + 80g salmon',
    loggedAt: DateTime.now(),
  ),
  MealItem(
    id: 'hipro-2',
    name: 'Double Grilled Chicken Breast with Steamed Broccoli',
    mealType: 'lunch',
    dietType: 'high_protein',
    calories: 480,
    proteinGrams: 64,
    carbsGrams: 12,
    fatGrams: 14,
    portion: '250g breast + 150g broccoli',
    loggedAt: DateTime.now(),
  ),
  MealItem(
    id: 'hipro-3',
    name: 'Seared Yellowfin Tuna Steak with Asparagus',
    mealType: 'dinner',
    dietType: 'high_protein',
    calories: 420,
    proteinGrams: 56,
    carbsGrams: 6,
    fatGrams: 16,
    portion: '220g tuna + greens',
    loggedAt: DateTime.now(),
  ),
  MealItem(
    id: 'hipro-4',
    name: 'Micellar Casein & Peanut Butter Shake',
    mealType: 'snack',
    dietType: 'high_protein',
    calories: 290,
    proteinGrams: 38,
    carbsGrams: 10,
    fatGrams: 10,
    portion: '1 scoop + 1 tbsp peanut butter',
    loggedAt: DateTime.now(),
  ),

  // --- LOW CARB / KETO PRESETS ---
  MealItem(
    id: 'lowcarb-1',
    name: 'Avocado & Cheddar Scrambled Eggs',
    mealType: 'breakfast',
    dietType: 'low_carb',
    calories: 430,
    proteinGrams: 22,
    carbsGrams: 4,
    fatGrams: 36,
    portion: '3 eggs + half avocado + 30g cheese',
    loggedAt: DateTime.now(),
  ),
  MealItem(
    id: 'lowcarb-2',
    name: 'Bacon & Chicken Caesar Bowl with Olive Oil',
    mealType: 'lunch',
    dietType: 'low_carb',
    calories: 520,
    proteinGrams: 46,
    carbsGrams: 5,
    fatGrams: 34,
    portion: '1 salad bowl (320g)',
    loggedAt: DateTime.now(),
  ),
  MealItem(
    id: 'lowcarb-3',
    name: 'Butter-Basted Ribeye Steak with Garlic Mushrooms',
    mealType: 'dinner',
    dietType: 'low_carb',
    calories: 620,
    proteinGrams: 48,
    carbsGrams: 4,
    fatGrams: 44,
    portion: '250g steak + 100g mushrooms',
    loggedAt: DateTime.now(),
  ),
  MealItem(
    id: 'lowcarb-4',
    name: 'Roasted Macadamia Nuts & Dark Chocolate 90%',
    mealType: 'snack',
    dietType: 'low_carb',
    calories: 280,
    proteinGrams: 4,
    carbsGrams: 6,
    fatGrams: 27,
    portion: '40g nuts + 2 squares chocolate',
    loggedAt: DateTime.now(),
  ),

  // --- MEDITERRANEAN PRESETS ---
  MealItem(
    id: 'med-1',
    name: 'Olive Oil Shakshuka with Crumbled Feta',
    mealType: 'breakfast',
    dietType: 'mediterranean',
    calories: 390,
    proteinGrams: 20,
    carbsGrams: 24,
    fatGrams: 22,
    portion: 'Skillet with 2 eggs + 40g feta',
    loggedAt: DateTime.now(),
  ),
  MealItem(
    id: 'med-2',
    name: 'Mediterranean Grilled Sea Bass with Greek Salad',
    mealType: 'lunch',
    dietType: 'mediterranean',
    calories: 470,
    proteinGrams: 44,
    carbsGrams: 14,
    fatGrams: 24,
    portion: '200g sea bass + 150g salad',
    loggedAt: DateTime.now(),
  ),
  MealItem(
    id: 'med-3',
    name: 'Lemon Herb Roasted Chicken with Couscous & Olives',
    mealType: 'dinner',
    dietType: 'mediterranean',
    calories: 540,
    proteinGrams: 46,
    carbsGrams: 42,
    fatGrams: 18,
    portion: '220g chicken + 100g couscous',
    loggedAt: DateTime.now(),
  ),
  MealItem(
    id: 'med-4',
    name: 'Kalamata Olives, Walnuts & Fresh Fig Plate',
    mealType: 'snack',
    dietType: 'mediterranean',
    calories: 230,
    proteinGrams: 6,
    carbsGrams: 16,
    fatGrams: 16,
    portion: '1 snack plate (120g)',
    loggedAt: DateTime.now(),
  ),

  // --- BALANCED PRESETS ---
  MealItem(
    id: 'bal-1',
    name: 'Steel-Cut Oats with Whey, Blueberries & Chia',
    mealType: 'breakfast',
    dietType: 'balanced',
    calories: 420,
    proteinGrams: 32,
    carbsGrams: 54,
    fatGrams: 8,
    portion: '1 warm bowl (300g)',
    loggedAt: DateTime.now(),
  ),
  MealItem(
    id: 'bal-2',
    name: 'Turkey Breast & Brown Rice Bowl with Green Beans',
    mealType: 'lunch',
    dietType: 'balanced',
    calories: 480,
    proteinGrams: 44,
    carbsGrams: 50,
    fatGrams: 10,
    portion: '180g turkey + 1 cup rice',
    loggedAt: DateTime.now(),
  ),
  MealItem(
    id: 'bal-3',
    name: 'Pan-Seared Cod with Roasted Sweet Potatoes & Greens',
    mealType: 'dinner',
    dietType: 'balanced',
    calories: 450,
    proteinGrams: 38,
    carbsGrams: 44,
    fatGrams: 9,
    portion: '200g cod + 150g sweet potato',
    loggedAt: DateTime.now(),
  ),
  MealItem(
    id: 'bal-4',
    name: 'Crisp Apple Slices with Crunchy Almond Butter',
    mealType: 'snack',
    dietType: 'balanced',
    calories: 220,
    proteinGrams: 6,
    carbsGrams: 26,
    fatGrams: 11,
    portion: '1 medium apple + 1 tbsp almond butter',
    loggedAt: DateTime.now(),
  ),
];

class NutritionNotifier extends Notifier<DailyNutritionState> {
  @override
  DailyNutritionState build() {
    // Warm up from Drift nutrition_logs table
    Future.microtask(() async {
      try {
        final repo = ref.read(nutritionRepositoryProvider);
        final saved = await repo.getDailyNutrition(DateTime.now());
        if (saved.loggedMeals.isNotEmpty || saved.waterGlasses > 0 || saved.loggedDrinks.isNotEmpty) {
          state = state.copyWith(
            loggedMeals: saved.loggedMeals,
            waterGlasses: saved.waterGlasses,
            loggedDrinks: saved.loggedDrinks,
            targetCalories: saved.targetCalories,
            targetProtein: saved.targetProtein,
            targetCarbs: saved.targetCarbs,
            targetFat: saved.targetFat,
          );
        }
      } catch (_) {}
    });

    return const DailyNutritionState(
      loggedMeals: [],
    );
  }

  void _persist(DailyNutritionState s) {
    try {
      ref.read(nutritionRepositoryProvider).saveDailyNutrition(DateTime.now(), s).ignore();
    } catch (_) {}
  }

  void syncWithProfile({
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    int? waterGlasses,
  }) {
    state = state.copyWith(
      targetCalories: calories,
      targetProtein: protein,
      targetCarbs: carbs,
      targetFat: fat,
      targetWater: waterGlasses ?? state.targetWater,
    );
    _persist(state);
  }

  void logMeal(MealItem meal) {
    final entry = meal.copyWith(
      id: _uuid.v4(),
      loggedAt: DateTime.now(),
    );
    state = state.copyWith(
      loggedMeals: [...state.loggedMeals, entry],
    );
    _persist(state);
  }

  void removeLoggedMeal(String mealId) {
    state = state.copyWith(
      loggedMeals: state.loggedMeals.where((m) => m.id != mealId).toList(),
    );
    _persist(state);
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
    _persist(state);
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
    if (count == state.waterGlasses) {
      decrementWater();
      return;
    }
    final target = count.clamp(0, state.targetWater);
    if (target < state.waterGlasses) {
      final diff = state.waterGlasses - target;
      var updatedDrinks = List<LiquidDrinkEntry>.from(state.loggedDrinks);
      for (var i = 0; i < diff && updatedDrinks.isNotEmpty; i++) {
        updatedDrinks.removeAt(0);
      }
      state = state.copyWith(
        loggedDrinks: updatedDrinks,
        waterGlasses: target,
      );
    } else {
      final diff = target - state.waterGlasses;
      final now = DateTime.now();
      final newEntries = List.generate(
        diff,
        (i) => LiquidDrinkEntry(
          id: _uuid.v4(),
          type: LiquidDrinkType.water,
          name: 'Water Glass',
          volumeMl: 250,
          loggedAt: now,
        ),
      );
      state = state.copyWith(
        loggedDrinks: [...newEntries, ...state.loggedDrinks],
        waterGlasses: target,
      );
    }
    _persist(state);
  }

  void incrementWater() {
    logDrink(
      type: LiquidDrinkType.water,
      name: 'Water Glass',
      volumeMl: 250,
    );
  }

  void decrementWater() {
    if (state.loggedDrinks.isNotEmpty) {
      final updatedDrinks = state.loggedDrinks.sublist(1);
      final totalMl = updatedDrinks.fold<int>(0, (sum, d) => sum + d.volumeMl);
      final calculatedGlasses = (totalMl / 250).floor().clamp(0, state.targetWater);
      state = state.copyWith(
        loggedDrinks: updatedDrinks,
        waterGlasses: calculatedGlasses,
      );
      _persist(state);
    } else if (state.waterGlasses > 0) {
      state = state.copyWith(waterGlasses: state.waterGlasses - 1);
      _persist(state);
    }
  }

  void logDrink({
    required LiquidDrinkType type,
    required String name,
    required int volumeMl,
    String? note,
  }) {
    final drink = LiquidDrinkEntry(
      id: _uuid.v4(),
      type: type,
      name: name,
      volumeMl: volumeMl,
      loggedAt: DateTime.now(),
      note: note,
    );
    final updatedDrinks = [drink, ...state.loggedDrinks];
    final totalMl = updatedDrinks.fold<int>(0, (sum, d) => sum + d.volumeMl);
    final calculatedGlasses = (totalMl / 250).floor().clamp(0, state.targetWater);
    state = state.copyWith(
      loggedDrinks: updatedDrinks,
      waterGlasses: calculatedGlasses,
    );
    _persist(state);
  }

  void removeDrink(String id) {
    final entry = state.loggedDrinks.firstWhere(
      (d) => d.id == id,
      orElse: () => LiquidDrinkEntry(
        id: '',
        type: LiquidDrinkType.water,
        name: '',
        volumeMl: 0,
        loggedAt: DateTime.now(),
      ),
    );
    if (entry.id.isNotEmpty) {
      final updatedDrinks = state.loggedDrinks.where((d) => d.id != id).toList();
      final totalMl = updatedDrinks.fold<int>(0, (sum, d) => sum + d.volumeMl);
      final calculatedGlasses = (totalMl / 250).floor().clamp(0, state.targetWater);
      state = state.copyWith(
        loggedDrinks: updatedDrinks,
        waterGlasses: calculatedGlasses,
      );
      _persist(state);
    }
  }

  void resetHydration() {
    state = state.copyWith(
      waterGlasses: 0,
      loggedDrinks: [],
    );
    _persist(state);
  }
}


final nutritionProvider =
    NotifierProvider<NutritionNotifier, DailyNutritionState>(
  NutritionNotifier.new,
);
