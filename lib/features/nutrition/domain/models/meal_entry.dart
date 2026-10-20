import 'nutrition_models.dart';

enum MealType {
  breakfast,
  lunch,
  dinner,
  snack,
  custom;

  String get displayName {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
      case MealType.custom:
        return 'Custom';
    }
  }

  static MealType fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'breakfast':
        return MealType.breakfast;
      case 'lunch':
        return MealType.lunch;
      case 'dinner':
        return MealType.dinner;
      case 'snack':
      case 'snacks':
        return MealType.snack;
      case 'custom':
        return MealType.custom;
      default:
        return MealType.snack;
    }
  }

  static MealType fromCurrentHour([DateTime? dt]) {
    final hour = (dt ?? DateTime.now()).hour;
    if (hour >= 5 && hour < 11) {
      return MealType.breakfast;
    } else if (hour >= 11 && hour < 16) {
      return MealType.lunch;
    } else if (hour >= 16 && hour < 21) {
      return MealType.dinner;
    } else {
      return MealType.snack;
    }
  }
}

class MealEntry {
  final String id;
  final String? foodId;
  final String foodName;
  final String? brand;
  final double quantityGrams;
  final MealType mealType;
  final String? customMealLabel;
  final DateTime consumedAt;

  // Base per-100g nutritional facts
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatsPer100g;
  final double caloriesPer100g;

  const MealEntry({
    required this.id,
    this.foodId,
    required this.foodName,
    this.brand,
    required this.quantityGrams,
    required this.mealType,
    this.customMealLabel,
    required this.consumedAt,
    this.proteinPer100g = 0.0,
    this.carbsPer100g = 0.0,
    this.fatsPer100g = 0.0,
    this.caloriesPer100g = 0.0,
  }) : assert(quantityGrams >= 0, 'Quantity in grams cannot be negative');

  // Computed nutritional content based on quantity
  double get protein => (proteinPer100g * quantityGrams) / 100;
  double get carbs => (carbsPer100g * quantityGrams) / 100;
  double get fats => (fatsPer100g * quantityGrams) / 100;
  double get calories => (caloriesPer100g * quantityGrams) / 100;
  int get caloriesInt => calories.round();

  MealEntry copyWith({
    String? id,
    String? foodId,
    String? foodName,
    String? brand,
    double? quantityGrams,
    MealType? mealType,
    String? customMealLabel,
    DateTime? consumedAt,
    double? proteinPer100g,
    double? carbsPer100g,
    double? fatsPer100g,
    double? caloriesPer100g,
  }) =>
      MealEntry(
        id: id ?? this.id,
        foodId: foodId ?? this.foodId,
        foodName: foodName ?? this.foodName,
        brand: brand ?? this.brand,
        quantityGrams: quantityGrams ?? this.quantityGrams,
        mealType: mealType ?? this.mealType,
        customMealLabel: customMealLabel ?? this.customMealLabel,
        consumedAt: consumedAt ?? this.consumedAt,
        proteinPer100g: proteinPer100g ?? this.proteinPer100g,
        carbsPer100g: carbsPer100g ?? this.carbsPer100g,
        fatsPer100g: fatsPer100g ?? this.fatsPer100g,
        caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
      );

  MealItem toMealItem() {
    return MealItem(
      id: id,
      name: brand != null && brand!.isNotEmpty ? '$foodName ($brand)' : foodName,
      mealType: mealType == MealType.custom
          ? (customMealLabel?.isNotEmpty == true ? customMealLabel! : 'custom')
          : mealType.name,
      dietType: 'balanced',
      calories: caloriesInt,
      proteinGrams: protein,
      carbsGrams: carbs,
      fatGrams: fats,
      portion: '${quantityGrams.toInt()}g',
      isCustom: mealType == MealType.custom,
      loggedAt: consumedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'food_id': foodId,
        'food_name': foodName,
        'brand': brand,
        'quantity_grams': quantityGrams,
        'meal_type': mealType.name,
        'custom_meal_label': customMealLabel,
        'consumed_at': consumedAt.toIso8601String(),
        'protein_per_100g': proteinPer100g,
        'carbs_per_100g': carbsPer100g,
        'fats_per_100g': fatsPer100g,
        'calories_per_100g': caloriesPer100g,
        'calories': caloriesInt,
        'protein': protein,
        'carbs': carbs,
        'fats': fats,
      };

  factory MealEntry.fromJson(Map<String, dynamic> json) => MealEntry(
        id: json['id'] as String,
        foodId: json['food_id'] as String?,
        foodName: json['food_name'] as String? ?? 'Meal',
        brand: json['brand'] as String?,
        quantityGrams: (json['quantity_grams'] as num?)?.toDouble() ?? 100.0,
        mealType: MealType.fromString(json['meal_type'] as String?),
        customMealLabel: json['custom_meal_label'] as String?,
        consumedAt: json['consumed_at'] != null
            ? DateTime.tryParse(json['consumed_at'] as String) ?? DateTime.now()
            : DateTime.now(),
        proteinPer100g: (json['protein_per_100g'] as num?)?.toDouble() ?? 0.0,
        carbsPer100g: (json['carbs_per_100g'] as num?)?.toDouble() ?? 0.0,
        fatsPer100g: (json['fats_per_100g'] as num?)?.toDouble() ?? 0.0,
        caloriesPer100g: (json['calories_per_100g'] as num?)?.toDouble() ?? 0.0,
      );
}
