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

class DailyNutritionState {
  final int targetCalories;
  final int targetProtein;
  final int targetCarbs;
  final int targetFat;
  final List<MealItem> loggedMeals;
  final List<MealItem> customMeals;
  final int waterGlasses;
  final int targetWater;
  final int manualCaloriesBurned;
  final int workoutCaloriesBurned;
  final String dietFilter; // 'all', 'vegan', 'non_veg'
  final String goalMode; // 'hypertrophy', 'cutting', 'recomp'

  const DailyNutritionState({
    this.targetCalories = 2400,
    this.targetProtein = 175,
    this.targetCarbs = 245,
    this.targetFat = 65,
    this.loggedMeals = const [],
    this.customMeals = const [],
    this.waterGlasses = 4,
    this.targetWater = 8,
    this.manualCaloriesBurned = 250,
    this.workoutCaloriesBurned = 320,
    this.dietFilter = 'all',
    this.goalMode = 'hypertrophy',
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

  DailyNutritionState copyWith({
    int? targetCalories,
    int? targetProtein,
    int? targetCarbs,
    int? targetFat,
    List<MealItem>? loggedMeals,
    List<MealItem>? customMeals,
    int? waterGlasses,
    int? targetWater,
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
      manualCaloriesBurned: manualCaloriesBurned ?? this.manualCaloriesBurned,
      workoutCaloriesBurned: workoutCaloriesBurned ?? this.workoutCaloriesBurned,
      dietFilter: dietFilter ?? this.dietFilter,
      goalMode: goalMode ?? this.goalMode,
    );
  }
}
