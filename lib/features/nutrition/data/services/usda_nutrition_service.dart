import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/models/food_item.dart';

class UsdaNutritionService {
  final http.Client _client;
  final String _websiteBaseUrl;

  UsdaNutritionService({http.Client? client, String? websiteBaseUrl})
    : _client = client ?? http.Client(),
      _websiteBaseUrl = websiteBaseUrl ?? 'https://fithost.amitrana.tech';

  Future<List<FoodItem>> searchFoods(String query, {int limit = 15}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    // 1. Try our Next.js secure server proxy first
    try {
      final proxyUri = Uri.parse(
        '$_websiteBaseUrl/api/nutrition/search?q=${Uri.encodeComponent(cleanQuery)}&limit=$limit',
      );
      final response = await _client
          .get(proxyUri)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        return items
            .map((item) => _mapJsonToFoodItem(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[UsdaNutritionService] Server proxy notice: $e');
    }

    // 2. Direct USDA API fallback with public DEMO_KEY
    try {
      final fallbackUri = Uri.parse(
        'https://api.nal.usda.gov/fdc/v1/foods/search?api_key=DEMO_KEY&query=${Uri.encodeComponent(cleanQuery)}&pageSize=$limit&dataType=Foundation,SR%20Legacy,Branded',
      );
      final fallbackResponse = await _client
          .get(fallbackUri)
          .timeout(const Duration(seconds: 8));

      if (fallbackResponse.statusCode == 200) {
        final data = jsonDecode(fallbackResponse.body) as Map<String, dynamic>;
        final foods = data['foods'] as List<dynamic>? ?? [];
        return foods
            .map((f) => _mapDirectUsdaJson(f as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[UsdaNutritionService] Direct USDA fallback notice: $e');
    }

    return [];
  }

  FoodItem _mapJsonToFoodItem(Map<String, dynamic> json) {
    final rawPresets = json['servingPresets'] as List<dynamic>? ?? [];
    final presets = rawPresets
        .map((p) => ServingPreset.fromJson(p as Map<String, dynamic>))
        .toList();

    return FoodItem(
      id:
          json['id'] as String? ??
          'usda_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Unknown Food',
      brand: json['brand'] as String? ?? 'USDA FoodData Central',
      servingUnit: json['servingUnit'] as String? ?? 'g',
      proteinPer100g: (json['proteinPer100g'] as num?)?.toDouble() ?? 0.0,
      carbsPer100g: (json['carbsPer100g'] as num?)?.toDouble() ?? 0.0,
      fatsPer100g: (json['fatsPer100g'] as num?)?.toDouble() ?? 0.0,
      caloriesPer100g: (json['caloriesPer100g'] as num?)?.toDouble() ?? 0.0,
      servingPresets: presets.isNotEmpty
          ? presets
          : const [ServingPreset(label: '100g', grams: 100.0)],
      source: FoodSource.usda,
    );
  }

  FoodItem _mapDirectUsdaJson(Map<String, dynamic> food) {
    final fdcId =
        food['fdcId']?.toString() ?? '${DateTime.now().millisecondsSinceEpoch}';
    final nutrients = food['foodNutrients'] as List<dynamic>? ?? [];

    double calories = 0.0;
    double protein = 0.0;
    double carbs = 0.0;
    double fats = 0.0;

    for (final n in nutrients) {
      if (n is Map<String, dynamic>) {
        final id = n['nutrientId'] as int?;
        final name = (n['nutrientName'] as String?)?.toLowerCase() ?? '';
        final val = (n['value'] as num?)?.toDouble() ?? 0.0;

        if (id == 1008 || name.contains('energy')) {
          calories = val > 0 ? val : calories;
        } else if (id == 1003 || name.contains('protein')) {
          protein = val > 0 ? val : protein;
        } else if (id == 1005 || name.contains('carbohydrate')) {
          carbs = val > 0 ? val : carbs;
        } else if (id == 1004 || name.contains('total lipid')) {
          fats = val > 0 ? val : fats;
        }
      }
    }

    final rawMeasures = food['foodMeasures'] as List<dynamic>? ?? [];
    final presets = <ServingPreset>[
      const ServingPreset(label: '100g', grams: 100.0),
    ];

    for (final m in rawMeasures) {
      if (m is Map<String, dynamic>) {
        final weight = (m['gramWeight'] as num?)?.toDouble() ?? 0.0;
        final label =
            m['disseminationText'] as String? ??
            m['householdMeasure'] as String? ??
            '${weight.toInt()}g portion';
        if (weight > 0 && !presets.any((p) => p.label == label)) {
          presets.insert(
            0,
            ServingPreset(label: '$label (${weight.round()}g)', grams: weight),
          );
        }
      }
    }

    return FoodItem(
      id: 'usda_$fdcId',
      name: food['description'] as String? ?? 'Food item',
      brand: food['brandOwner'] as String? ?? 'USDA FoodData',
      servingUnit: 'g',
      proteinPer100g: double.parse(protein.toStringAsFixed(2)),
      carbsPer100g: double.parse(carbs.toStringAsFixed(2)),
      fatsPer100g: double.parse(fats.toStringAsFixed(2)),
      caloriesPer100g: double.parse(calories.toStringAsFixed(1)),
      servingPresets: presets,
      source: FoodSource.usda,
    );
  }
}
