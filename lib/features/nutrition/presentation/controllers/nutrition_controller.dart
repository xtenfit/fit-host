import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/nutrition_models.dart';
import '../../domain/services/nutrition_calculation_service.dart';
import '../../data/repositories/calorie_adjustment_repository.dart';
import '../../../profile/presentation/controllers/user_profile_controller.dart';
import 'package:fit_host/core/data/nutrition_repository.dart';
import 'package:fit_host/core/services/home_widget_service.dart';
import 'package:fit_host/core/services/analytics_service.dart';

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
  DateTime _currentDate = DateTime.now();

  DateTime get currentDate => _currentDate;

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  DailyNutritionState build() {
    _currentDate = DateTime.now();
    // Warm up from Drift nutrition_logs table and calorie_adjustments table
    Future.microtask(() async {
      await loadForDate(_currentDate);
    });

    return const DailyNutritionState(loggedMeals: []);
  }

  /// Loads persisted daily nutrition logs and independent calorie adjustments for a specific date.
  Future<void> loadForDate(DateTime date) async {
    _currentDate = date;
    try {
      final repo = ref.read(nutritionRepositoryProvider);
      final adjRepo = ref.read(calorieAdjustmentRepositoryProvider);

      final saved = await repo.getDailyNutrition(date);
      final adjustments = await adjRepo.getAdjustmentsForDate(date);

      state = state.copyWith(
        loggedMeals: saved.loggedMeals,
        waterGlasses: saved.waterGlasses,
        loggedDrinks: saved.loggedDrinks,
        targetCalories: saved.targetCalories > 0
            ? saved.targetCalories
            : state.targetCalories,
        targetProtein: saved.targetProtein > 0
            ? saved.targetProtein
            : state.targetProtein,
        targetCarbs: saved.targetCarbs > 0
            ? saved.targetCarbs
            : state.targetCarbs,
        targetFat: saved.targetFat > 0 ? saved.targetFat : state.targetFat,
        targetWater: saved.targetWater > 0
            ? saved.targetWater
            : state.targetWater,
        manualAdjustments: adjustments,
      );

      try {
        HomeWidgetService.instance
            .syncData(
              waterGlasses: state.waterGlasses,
              targetWater: state.targetWater,
              calories: state.totalCaloriesGained,
            )
            .ignore();
      } catch (_) {}
    } catch (_) {}
  }

  void _persist(DailyNutritionState s, {DateTime? targetDate}) {
    final date = targetDate ?? _currentDate;
    try {
      ref
          .read(nutritionRepositoryProvider)
          .saveDailyNutrition(date, s)
          .ignore();
    } catch (_) {}
    try {
      HomeWidgetService.instance
          .syncData(
            waterGlasses: s.waterGlasses,
            targetWater: s.targetWater,
            calories: s.totalCaloriesGained,
          )
          .ignore();
    } catch (_) {}
  }

  void setWaterTarget(int target) {
    state = state.copyWith(targetWater: target.clamp(1, 30));
    _persist(state);
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
      isPersonalized: true,
    );
    _persist(state);
  }

  void logMeal(MealItem meal, {DateTime? date}) {
    final logTime = date ?? meal.loggedAt;
    final entry = meal.copyWith(
      id: meal.id.isNotEmpty ? meal.id : _uuid.v4(),
      loggedAt: logTime,
    );

    if (_isSameDay(logTime, _currentDate)) {
      state = state.copyWith(loggedMeals: [...state.loggedMeals, entry]);
      _persist(state, targetDate: logTime);
    } else {
      // Save directly to the meal's specific date record in repository
      ref
          .read(nutritionRepositoryProvider)
          .logMeal(entry, date: logTime)
          .ignore();
    }
    AnalyticsService.instance
        .track(AnalyticsEvents.mealLogged, properties: {'is_custom': false})
        .ignore();
  }

  void removeLoggedMeal(String mealId, {DateTime? date}) {
    final targetDate = date ?? _currentDate;
    state = state.copyWith(
      loggedMeals: state.loggedMeals.where((m) => m.id != mealId).toList(),
    );
    _persist(state, targetDate: targetDate);
  }

  void addCustomMeal(MealItem meal, {DateTime? date}) {
    final logTime = date ?? meal.loggedAt;
    final custom = meal.copyWith(
      id: meal.id.isNotEmpty ? meal.id : _uuid.v4(),
      isCustom: true,
      loggedAt: logTime,
    );
    if (_isSameDay(logTime, _currentDate)) {
      state = state.copyWith(
        customMeals: [...state.customMeals, custom],
        loggedMeals: [...state.loggedMeals, custom],
      );
      _persist(state, targetDate: logTime);
    } else {
      ref
          .read(nutritionRepositoryProvider)
          .logMeal(custom, date: logTime)
          .ignore();
    }
    AnalyticsService.instance
        .track(AnalyticsEvents.mealLogged, properties: {'is_custom': true})
        .ignore();
  }

  void setDietFilter(String filter) {
    state = state.copyWith(dietFilter: filter);
  }

  /// Calculates personalized targets using canonical NutritionCalculationService.
  void setGoalMode(String mode) {
    try {
      final profile = ref.read(userProfileProvider);
      final goalName = mode == 'hypertrophy'
          ? 'build_muscle'
          : mode == 'cutting'
          ? 'lose_weight'
          : 'maintain_weight';
      final modProfile = profile.copyWith(fitnessGoal: goalName);
      final targets = NutritionCalculationService.calculateTargetsFromProfile(
        modProfile,
      );

      state = state.copyWith(
        goalMode: mode,
        targetCalories: targets.dailyCalories,
        targetProtein: targets.proteinGrams,
        targetCarbs: targets.carbsGrams,
        targetFat: targets.fatsGrams,
        isPersonalized: targets.isPersonalized,
      );
      _persist(state);
    } catch (_) {
      // Fallback baseline targets if profile read fails
      state = state.copyWith(
        goalMode: mode,
        targetCalories: mode == 'cutting'
            ? 1950
            : (mode == 'hypertrophy' ? 2650 : 2250),
        isPersonalized: false,
      );
      _persist(state);
    }
  }

  /// Adds a verified, independent manual calorie-burn adjustment.
  Future<void> addCalorieAdjustment(CalorieAdjustment adjustment) async {
    final adjRepo = ref.read(calorieAdjustmentRepositoryProvider);
    await adjRepo.addAdjustment(adjustment);
    if (_isSameDay(adjustment.date, _currentDate)) {
      state = state.copyWith(
        manualAdjustments: [
          ...state.manualAdjustments.where((a) => a.id != adjustment.id),
          adjustment,
        ],
      );
    }
  }

  /// Updates an existing manual calorie-burn adjustment.
  Future<void> updateCalorieAdjustment(CalorieAdjustment adjustment) async {
    final adjRepo = ref.read(calorieAdjustmentRepositoryProvider);
    await adjRepo.updateAdjustment(adjustment);
    if (_isSameDay(adjustment.date, _currentDate)) {
      state = state.copyWith(
        manualAdjustments: state.manualAdjustments
            .map((a) => a.id == adjustment.id ? adjustment : a)
            .toList(),
      );
    }
  }

  /// Soft deletes a manual calorie-burn adjustment.
  Future<void> deleteCalorieAdjustment(String adjustmentId) async {
    final adjRepo = ref.read(calorieAdjustmentRepositoryProvider);
    await adjRepo.deleteAdjustment(adjustmentId);
    state = state.copyWith(
      manualAdjustments: state.manualAdjustments
          .where((a) => a.id != adjustmentId)
          .toList(),
    );
  }

  /// Adds manual burned calories by creating an identifiable CalorieAdjustment record.
  void addBurnedCalories(
    int delta, {
    String title = 'Manual Activity',
    String? note,
  }) {
    if (delta <= 0) return;
    final now = DateTime.now();
    final adjustment = CalorieAdjustment(
      id: _uuid.v4(),
      date: _currentDate,
      caloriesBurned: delta.clamp(1, 5000),
      title: title,
      note: note,
      source: 'manual_adjustment',
      createdAt: now,
      updatedAt: now,
    );
    addCalorieAdjustment(adjustment);
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
      state = state.copyWith(loggedDrinks: updatedDrinks, waterGlasses: target);
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
    logDrink(type: LiquidDrinkType.water, name: 'Water Glass', volumeMl: 250);
  }

  void decrementWater() {
    if (state.loggedDrinks.isNotEmpty) {
      final updatedDrinks = state.loggedDrinks.sublist(1);
      final totalMl = updatedDrinks.fold<int>(0, (sum, d) => sum + d.volumeMl);
      final calculatedGlasses = (totalMl / 250).floor().clamp(
        0,
        state.targetWater,
      );
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
    final calculatedGlasses = (totalMl / 250).floor().clamp(
      0,
      state.targetWater,
    );
    state = state.copyWith(
      loggedDrinks: updatedDrinks,
      waterGlasses: calculatedGlasses,
    );
    _persist(state);
    AnalyticsService.instance
        .track(
          AnalyticsEvents.hydrationLogged,
          properties: {'is_water': type == LiquidDrinkType.water},
        )
        .ignore();
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
      final updatedDrinks = state.loggedDrinks
          .where((d) => d.id != id)
          .toList();
      final totalMl = updatedDrinks.fold<int>(0, (sum, d) => sum + d.volumeMl);
      final calculatedGlasses = (totalMl / 250).floor().clamp(
        0,
        state.targetWater,
      );
      state = state.copyWith(
        loggedDrinks: updatedDrinks,
        waterGlasses: calculatedGlasses,
      );
      _persist(state);
    }
  }

  void resetHydration() {
    state = state.copyWith(waterGlasses: 0, loggedDrinks: []);
    _persist(state);
  }
}

final nutritionProvider =
    NotifierProvider<NutritionNotifier, DailyNutritionState>(
      NutritionNotifier.new,
    );
