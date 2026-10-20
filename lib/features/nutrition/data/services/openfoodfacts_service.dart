import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/models/food_item.dart';

class OpenFoodFactsService {
  final http.Client _client;

  OpenFoodFactsService([http.Client? client]) : _client = client ?? http.Client();

  static const String _userAgent = 'FitHostApp - Android/iOS - Version 1.0';

  Future<FoodItem?> fetchProductByBarcode(String barcode) async {
    try {
      final cleanBarcode = barcode.trim();
      if (cleanBarcode.isEmpty) return null;

      final url = Uri.parse('https://world.openfoodfacts.org/api/v2/product/$cleanBarcode.json');
      final response = await _client.get(
        url,
        headers: {'User-Agent': _userAgent},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status'] as int? ?? 0;
      if (status != 1 || data['product'] == null) {
        return null;
      }

      return parseProductJson(data['product'] as Map<String, dynamic>, cleanBarcode);
    } catch (e) {
      debugPrint('OpenFoodFactsService fetch error: $e');
      return null;
    }
  }

  Future<List<FoodItem>> searchProducts(String query, {int limit = 15}) async {
    try {
      final cleanQuery = Uri.encodeComponent(query.trim());
      if (cleanQuery.isEmpty) return [];

      final url = Uri.parse(
        'https://world.openfoodfacts.org/cgi/search.pl?search_terms=$cleanQuery&search_simple=1&action=process&json=1&page_size=$limit',
      );

      final response = await _client.get(
        url,
        headers: {'User-Agent': _userAgent},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final products = data['products'] as List<dynamic>? ?? [];

      final results = <FoodItem>[];
      for (final p in products) {
        if (p is Map<String, dynamic>) {
          final item = parseProductJson(p, p['code'] as String?);
          if (item != null) {
            results.add(item);
          }
        }
      }
      return results;
    } catch (e) {
      debugPrint('OpenFoodFactsService search error: $e');
      return [];
    }
  }

  FoodItem? parseProductJson(Map<String, dynamic>? data, [String? fallbackBarcode]) {
    if (data == null || data.isEmpty) return null;
    try {
      final Map<String, dynamic> product;
      String? barcode = fallbackBarcode;

      if (data.containsKey('product')) {
        final p = data['product'];
        if (p is! Map<String, dynamic>) return null;
        product = p;
        barcode = (data['code'] as String?) ?? fallbackBarcode;
      } else {
        product = data;
      }

      final name = (product['product_name'] as String?)?.trim() ??
          (product['product_name_en'] as String?)?.trim() ??
          '';
      if (name.isEmpty) return null;

      final brand = (product['brands'] as String?)?.split(',').first.trim();
      barcode = (product['code'] as String?) ?? barcode;
      final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};

      final protein = _extractNum(nutriments, ['proteins_100g', 'proteins']);
      final carbs = _extractNum(nutriments, ['carbohydrates_100g', 'carbohydrates']);
      final fat = _extractNum(nutriments, ['fat_100g', 'fat']);

      // Calories: energy-kcal_100g or convert from kJ (energy_100g / 4.184)
      double calories = _extractNum(nutriments, ['energy-kcal_100g', 'energy-kcal', 'energy_kcal']);
      if (calories <= 0) {
        final kj = _extractNum(nutriments, ['energy-kj_100g', 'energy-kj', 'energy_100g', 'energy']);
        if (kj > 0) {
          calories = kj / 4.184;
        } else {
          // Approximate from macros if calories are completely missing
          calories = (protein * 4) + (carbs * 4) + (fat * 9);
        }
      }

      final imageUrl = (product['image_front_url'] as String?) ??
          (product['image_url'] as String?);

      return FoodItem(
        id: 'off_${barcode ?? name.hashCode}',
        barcode: barcode,
        name: name,
        brand: brand,
        proteinPer100g: double.parse(protein.toStringAsFixed(1)),
        carbsPer100g: double.parse(carbs.toStringAsFixed(1)),
        fatsPer100g: double.parse(fat.toStringAsFixed(1)),
        caloriesPer100g: double.parse(calories.toStringAsFixed(1)),
        source: FoodSource.openfoodfacts,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        servingPresets: const [
          ServingPreset(label: '100g', grams: 100),
          ServingPreset(label: '1 serving (50g)', grams: 50),
          ServingPreset(label: '1 tbsp (15g)', grams: 15),
        ],
      );
    } catch (e) {
      debugPrint('Error parsing OFF product: $e');
      return null;
    }
  }

  double _extractNum(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      if (map[k] != null) {
        final val = (map[k] as num?)?.toDouble();
        if (val != null) return val < 0 ? 0.0 : val;
      }
    }
    return 0.0;
  }
}
