export 'food_item.dart';
export 'meal_entry.dart';
export 'photo_meal_draft.dart';

class MealItem {
  final String id;
  final String name;
  final String mealType; // 'breakfast', 'lunch', 'dinner', 'snack'
  final String dietType; // 'vegan', 'non_veg'
  final int calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final String portion;
  final bool isCustom;
  final DateTime loggedAt;

  const MealItem({
    required this.id,
    required this.name,
    required this.mealType,
    required this.dietType,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    this.portion = '1 serving',
    this.isCustom = false,
    required this.loggedAt,
  });

  MealItem copyWith({
    String? id,
    String? name,
    String? mealType,
    String? dietType,
    int? calories,
    double? proteinGrams,
    double? carbsGrams,
    double? fatGrams,
    String? portion,
    bool? isCustom,
    DateTime? loggedAt,
  }) {
    return MealItem(
      id: id ?? this.id,
      name: name ?? this.name,
      mealType: mealType ?? this.mealType,
      dietType: dietType ?? this.dietType,
      calories: calories ?? this.calories,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      fatGrams: fatGrams ?? this.fatGrams,
      portion: portion ?? this.portion,
      isCustom: isCustom ?? this.isCustom,
      loggedAt: loggedAt ?? this.loggedAt,
    );
  }
}

enum LiquidDrinkType {
  water,
  creatine,
  glucose,
  protein,
  custom,
}

class LiquidDrinkEntry {
  final String id;
  final LiquidDrinkType type;
  final String name;
  final int volumeMl;
  final DateTime loggedAt;
  final String? note;

  const LiquidDrinkEntry({
    required this.id,
    required this.type,
    required this.name,
    required this.volumeMl,
    required this.loggedAt,
    this.note,
  });

  LiquidDrinkEntry copyWith({
    String? id,
    LiquidDrinkType? type,
    String? name,
    int? volumeMl,
    DateTime? loggedAt,
    String? note,
  }) {
    return LiquidDrinkEntry(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      volumeMl: volumeMl ?? this.volumeMl,
      loggedAt: loggedAt ?? this.loggedAt,
      note: note ?? this.note,
    );
  }
}

class DailyNutritionState {
  final int targetCalories;
  final int targetProtein;
  final int targetCarbs;
  final int targetFat;
  final List<MealItem> loggedMeals;
  final List<MealItem> customMeals;
  final int waterGlasses;
  final int targetWater;
  final List<LiquidDrinkEntry> loggedDrinks;
  final int manualCaloriesBurned;
  final int workoutCaloriesBurned;
  final String dietFilter; // 'all', 'vegan', 'non_veg'
  final String goalMode; // 'hypertrophy', 'cutting', 'recomp'

  const DailyNutritionState({
    this.targetCalories = 2250,
    this.targetProtein = 145,
    this.targetCarbs = 250,
    this.targetFat = 60,
    this.loggedMeals = const [],
    this.customMeals = const [],
    this.waterGlasses = 0,
    this.targetWater = 10,
    this.loggedDrinks = const [],
    this.manualCaloriesBurned = 0,
    this.workoutCaloriesBurned = 0,
    this.dietFilter = 'all',
    this.goalMode = 'maintenance',
  });

  int get totalCaloriesGained =>
      loggedMeals.fold<int>(0, (sum, m) => sum + m.calories);

  int get totalCaloriesBurned => manualCaloriesBurned + workoutCaloriesBurned;

  int get remainingCalories =>
      targetCalories - totalCaloriesGained + totalCaloriesBurned;

  double get totalProteinGained =>
      loggedMeals.fold<double>(0.0, (sum, m) => sum + m.proteinGrams);

  double get totalCarbsGained =>
      loggedMeals.fold<double>(0.0, (sum, m) => sum + m.carbsGrams);

  double get totalFatGained =>
      loggedMeals.fold<double>(0.0, (sum, m) => sum + m.fatGrams);

  int get targetFats => targetFat;
  double get totalProtein => totalProteinGained;
  double get totalCarbs => totalCarbsGained;
  double get totalFats => totalFatGained;

  int get totalDrinkMl =>
      loggedDrinks.fold<int>(0, (sum, d) => sum + d.volumeMl);

  int get totalHydrationMl {
    if (loggedDrinks.isNotEmpty) {
      final glassesFromDrinks = (totalDrinkMl / 250).floor();
      final extraGlasses = (waterGlasses - glassesFromDrinks).clamp(0, 99);
      return totalDrinkMl + (extraGlasses * 250);
    }
    return waterGlasses * 250;
  }

  int get targetHydrationMl => targetWater * 250;

  DailyNutritionState copyWith({
    int? targetCalories,
    int? targetProtein,
    int? targetCarbs,
    int? targetFat,
    List<MealItem>? loggedMeals,
    List<MealItem>? customMeals,
    int? waterGlasses,
    int? targetWater,
    List<LiquidDrinkEntry>? loggedDrinks,
    int? manualCaloriesBurned,
    int? workoutCaloriesBurned,
    String? dietFilter,
    String? goalMode,
  }) {
    return DailyNutritionState(
      targetCalories: targetCalories ?? this.targetCalories,
      targetProtein: targetProtein ?? this.targetProtein,
      targetCarbs: targetCarbs ?? this.targetCarbs,
      targetFat: targetFat ?? this.targetFat,
      loggedMeals: loggedMeals ?? this.loggedMeals,
      customMeals: customMeals ?? this.customMeals,
      waterGlasses: waterGlasses ?? this.waterGlasses,
      targetWater: targetWater ?? this.targetWater,
      loggedDrinks: loggedDrinks ?? this.loggedDrinks,
      manualCaloriesBurned: manualCaloriesBurned ?? this.manualCaloriesBurned,
      workoutCaloriesBurned: workoutCaloriesBurned ?? this.workoutCaloriesBurned,
      dietFilter: dietFilter ?? this.dietFilter,
      goalMode: goalMode ?? this.goalMode,
    );
  }
}

