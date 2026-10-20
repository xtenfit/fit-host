import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/photo_meal_draft.dart';

class GeminiNutritionService {
  final Dio _dio;
  final String? _apiKeyOverride;

  GeminiNutritionService({Dio? dio, String? apiKey})
      : _dio = dio ?? Dio(),
        _apiKeyOverride = apiKey;

  String? get _apiKey =>
      _apiKeyOverride ?? dotenv.env['GEMINI_API_KEY'];

  static const String _prompt =
      'Analyze this meal photo. Identify each visible ingredient separately. '
      'For each ingredient, estimate the quantity in grams and provide per-100g: '
      'protein, carbohydrates, fats (in grams), and calories (kcal). '
      'Return ONLY valid JSON in this exact schema, no prose, no markdown: '
      '{\n'
      '  "meal_name": "string",\n'
      '  "confidence": 0.0-1.0,\n'
      '  "ingredients": [\n'
      '    {\n'
      '      "name": "string",\n'
      '      "estimated_grams": number,\n'
      '      "protein_per_100g": number,\n'
      '      "carbs_per_100g": number,\n'
      '      "fats_per_100g": number,\n'
      '      "calories_per_100g": number\n'
      '    }\n'
      '  ]\n'
      '}\n'
      'If you cannot identify the meal, return {"confidence": 0.0, "ingredients": []}.';

  Future<PhotoMealDraft> analyzeMealPhoto(String imagePath) async {
    final apiKey = _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('[GeminiNutritionService] Warning: GEMINI_API_KEY is not configured');
      return PhotoMealDraft(
        mealName: 'Unrecognized Meal',
        imagePath: imagePath,
        estimatedIngredients: const [],
        confidence: 0.0,
      );
    }

    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Image file not found at $imagePath');
      }

      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      final url =
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': _prompt},
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.2,
          'responseMimeType': 'application/json',
        }
      };

      final response = await _dio.post(
        url,
        data: requestBody,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
        ),
      );

      if (response.statusCode != 200 || response.data == null) {
        debugPrint('[GeminiNutritionService] Error: HTTP ${response.statusCode} -> ${response.data}');
        return PhotoMealDraft(
          mealName: 'Failed Analysis',
          imagePath: imagePath,
          estimatedIngredients: const [],
          confidence: 0.0,
        );
      }

      final candidates = response.data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        return PhotoMealDraft(
          mealName: 'No Candidates Returned',
          imagePath: imagePath,
          estimatedIngredients: const [],
          confidence: 0.0,
        );
      }

      final content = candidates.first['content']?['parts']?[0]?['text'] as String?;
      if (content == null || content.isEmpty) {
        return PhotoMealDraft(
          mealName: 'Empty Analysis',
          imagePath: imagePath,
          estimatedIngredients: const [],
          confidence: 0.0,
        );
      }

      return parseGeminiResponse(content, imagePath: imagePath);
    } catch (e, st) {
      debugPrint('[GeminiNutritionService] Exception during meal analysis: $e\n$st');
      return PhotoMealDraft(
        mealName: 'Analysis Error',
        imagePath: imagePath,
        estimatedIngredients: const [],
        confidence: 0.0,
      );
    }
  }

  /// Parses and sanitizes raw Gemini JSON output with Task 13 safety rules.
  PhotoMealDraft parseGeminiResponse(String rawText, {String imagePath = ''}) {
    try {
      String cleanText = rawText.trim();
      if (cleanText.startsWith('```json')) {
        cleanText = cleanText.substring(7);
      }
      if (cleanText.startsWith('```')) {
        cleanText = cleanText.substring(3);
      }
      if (cleanText.endsWith('```')) {
        cleanText = cleanText.substring(0, cleanText.length - 3);
      }
      cleanText = cleanText.trim();

      final json = jsonDecode(cleanText) as Map<String, dynamic>;
      final mealName = (json['meal_name'] as String?)?.trim() ?? 'Identified Meal';
      double confidence = (json['confidence'] as num?)?.toDouble() ?? 0.8;
      final rawIngredients = json['ingredients'] as List<dynamic>? ?? [];

      final ingredients = <IngredientEstimate>[];
      for (final item in rawIngredients) {
        if (item is Map<String, dynamic>) {
          final name = (item['name'] as String?)?.trim() ?? 'Ingredient';
          double grams = (item['estimated_grams'] as num?)?.toDouble() ?? 50.0;
          double p = (item['protein_per_100g'] as num?)?.toDouble() ?? 0.0;
          double c = (item['carbs_per_100g'] as num?)?.toDouble() ?? 0.0;
          double f = (item['fats_per_100g'] as num?)?.toDouble() ?? 0.0;
          double cal = (item['calories_per_100g'] as num?)?.toDouble() ?? 0.0;

          // TASK 13 SANITY & SAFETY CHECKS:
          // 1. Grams must be strictly positive
          if (grams <= 0) grams = 50.0;

          // 2. Each macro must be non-negative
          if (p < 0) p = 0.0;
          if (c < 0) c = 0.0;
          if (f < 0) f = 0.0;
          if (cal < 0) cal = 0.0;

          // 3. Calories per 100g must not exceed pure fat (900 kcal / 100g)
          if (cal > 900.0) {
            debugPrint('[GeminiNutritionService] Sanity warning: $name has suspicious $cal kcal/100g, clamping to 900.0');
            cal = 900.0;
            confidence = (confidence * 0.7).clamp(0.0, 1.0);
          }

          // Macro plausibility check: pure fat gives max 900 kcal, pure protein/carb 400 kcal
          final theoreticalMax = (p * 4) + (c * 4) + (f * 9);
          if (cal <= 0 && theoreticalMax > 0) {
            cal = theoreticalMax;
          }

          ingredients.add(
            IngredientEstimate(
              name: name,
              estimatedGrams: double.parse(grams.toStringAsFixed(1)),
              proteinPer100g: double.parse(p.toStringAsFixed(1)),
              carbsPer100g: double.parse(c.toStringAsFixed(1)),
              fatsPer100g: double.parse(f.toStringAsFixed(1)),
              caloriesPer100g: double.parse(cal.toStringAsFixed(1)),
            ),
          );
        }
      }

      if (ingredients.isEmpty) {
        confidence = 0.0;
      }

      return PhotoMealDraft(
        mealName: mealName,
        imagePath: imagePath,
        estimatedIngredients: ingredients,
        confidence: confidence.clamp(0.0, 1.0),
        userEdited: false,
      );
    } catch (e) {
      debugPrint('[GeminiNutritionService] JSON Parse error: $e for text: $rawText');
      return PhotoMealDraft(
        mealName: 'Unparsed Meal',
        imagePath: imagePath,
        estimatedIngredients: const [],
        confidence: 0.0,
      );
    }
  }
}

final geminiNutritionServiceProvider = Provider<GeminiNutritionService>((ref) {
  return GeminiNutritionService();
});
