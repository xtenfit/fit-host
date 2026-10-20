class IngredientEstimate {
  final String name;
  final double estimatedGrams;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatsPer100g;
  final double caloriesPer100g;

  const IngredientEstimate({
    required this.name,
    required this.estimatedGrams,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatsPer100g,
    required this.caloriesPer100g,
  });

  double get protein => (proteinPer100g * estimatedGrams) / 100;
  double get carbs => (carbsPer100g * estimatedGrams) / 100;
  double get fats => (fatsPer100g * estimatedGrams) / 100;
  double get calories => (caloriesPer100g * estimatedGrams) / 100;

  IngredientEstimate copyWith({
    String? name,
    double? estimatedGrams,
    double? proteinPer100g,
    double? carbsPer100g,
    double? fatsPer100g,
    double? caloriesPer100g,
  }) =>
      IngredientEstimate(
        name: name ?? this.name,
        estimatedGrams: estimatedGrams ?? this.estimatedGrams,
        proteinPer100g: proteinPer100g ?? this.proteinPer100g,
        carbsPer100g: carbsPer100g ?? this.carbsPer100g,
        fatsPer100g: fatsPer100g ?? this.fatsPer100g,
        caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'estimated_grams': estimatedGrams,
        'protein_per_100g': proteinPer100g,
        'carbs_per_100g': carbsPer100g,
        'fats_per_100g': fatsPer100g,
        'calories_per_100g': caloriesPer100g,
      };

  factory IngredientEstimate.fromJson(Map<String, dynamic> json) =>
      IngredientEstimate(
        name: json['name'] as String? ?? 'Ingredient',
        estimatedGrams:
            (json['estimated_grams'] as num?)?.toDouble() ?? 50.0,
        proteinPer100g:
            (json['protein_per_100g'] as num?)?.toDouble() ?? 0.0,
        carbsPer100g: (json['carbs_per_100g'] as num?)?.toDouble() ?? 0.0,
        fatsPer100g: (json['fats_per_100g'] as num?)?.toDouble() ?? 0.0,
        caloriesPer100g:
            (json['calories_per_100g'] as num?)?.toDouble() ?? 0.0,
      );
}

class PhotoMealDraft {
  final String mealName;
  final String imagePath;
  final List<IngredientEstimate> estimatedIngredients;
  final double confidence;
  final bool userEdited;

  const PhotoMealDraft({
    this.mealName = 'Meal Analysis',
    required this.imagePath,
    required this.estimatedIngredients,
    this.confidence = 1.0,
    this.userEdited = false,
  });

  double get totalProtein =>
      estimatedIngredients.fold(0.0, (sum, i) => sum + i.protein);

  double get totalCarbs =>
      estimatedIngredients.fold(0.0, (sum, i) => sum + i.carbs);

  double get totalFats =>
      estimatedIngredients.fold(0.0, (sum, i) => sum + i.fats);

  double get totalCalories =>
      estimatedIngredients.fold(0.0, (sum, i) => sum + i.calories);

  double get totalGrams =>
      estimatedIngredients.fold(0.0, (sum, i) => sum + i.estimatedGrams);

  PhotoMealDraft copyWith({
    String? mealName,
    String? imagePath,
    List<IngredientEstimate>? estimatedIngredients,
    double? confidence,
    bool? userEdited,
  }) =>
      PhotoMealDraft(
        mealName: mealName ?? this.mealName,
        imagePath: imagePath ?? this.imagePath,
        estimatedIngredients:
            estimatedIngredients ?? this.estimatedIngredients,
        confidence: confidence ?? this.confidence,
        userEdited: userEdited ?? this.userEdited,
      );

  Map<String, dynamic> toJson() => {
        'meal_name': mealName,
        'image_path': imagePath,
        'confidence': confidence,
        'user_edited': userEdited,
        'estimated_ingredients':
            estimatedIngredients.map((i) => i.toJson()).toList(),
        'total_protein': totalProtein,
        'total_carbs': totalCarbs,
        'total_fats': totalFats,
        'total_calories': totalCalories,
      };

  factory PhotoMealDraft.fromJson(Map<String, dynamic> json) {
    List<IngredientEstimate> ingredients = [];
    if (json['ingredients'] != null && json['ingredients'] is List) {
      ingredients = (json['ingredients'] as List)
          .map((i) => IngredientEstimate.fromJson(i as Map<String, dynamic>))
          .toList();
    } else if (json['estimated_ingredients'] != null &&
        json['estimated_ingredients'] is List) {
      ingredients = (json['estimated_ingredients'] as List)
          .map((i) => IngredientEstimate.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    return PhotoMealDraft(
      mealName: json['meal_name'] as String? ?? 'Meal Analysis',
      imagePath: json['image_path'] as String? ?? '',
      estimatedIngredients: ingredients,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      userEdited: json['user_edited'] as bool? ?? false,
    );
  }
}
