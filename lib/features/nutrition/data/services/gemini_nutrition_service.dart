import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/photo_meal_draft.dart';

class GeminiNutritionService {
  final Dio _dio;
  final String? _apiKeyOverride;
  final String? _proxyUrlOverride;
  late final String _aiSessionId = Uuid().v4();

  GeminiNutritionService({Dio? dio, String? apiKey, String? proxyUrl})
    : _dio = dio ?? Dio(),
      _apiKeyOverride = apiKey,
      _proxyUrlOverride = proxyUrl;

  String? get _apiKey =>
      _apiKeyOverride ??
      (dotenv.isInitialized ? dotenv.env['GEMINI_API_KEY'] : null);

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

  static const String _defaultProxyUrl =
      'https://fithost.amitrana.tech/api/nutrition/ai-parse';

  String get _proxyUrl =>
      _proxyUrlOverride ??
      (dotenv.isInitialized ? dotenv.env['NUTRITION_API_URL'] : null) ??
      _defaultProxyUrl;

  Map<String, String> get _aiObservabilityHeaders {
    String? userId;
    try {
      userId = Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      // The service can run before an auth client is available in isolated tests.
    }

    return {
      'X-PostHog-AI-Session-ID': _aiSessionId,
      if (userId != null && userId.isNotEmpty) 'X-PostHog-Distinct-ID': userId,
    };
  }

  /// Analyzes natural-language meal text (e.g. "Two rotis, one bowl of dal, and 150g curd").
  Future<PhotoMealDraft> analyzeMealText(String textDescription) async {
    final query = textDescription.trim();
    if (query.isEmpty) {
      return const PhotoMealDraft(
        mealName: 'Empty Description',
        imagePath: '',
        estimatedIngredients: [],
        confidence: 0.0,
      );
    }

    // In test environment without an explicit proxy override, use deterministic offline fallback
    if (Platform.environment.containsKey('FLUTTER_TEST') &&
        _proxyUrlOverride == null) {
      return _parseTextFallback(query);
    }

    // 1. Try server-side AI parsing endpoint first (keeps secret keys off client)
    try {
      final response = await _dio.post(
        _proxyUrl,
        data: {'text': query},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            ..._aiObservabilityHeaders,
          },
          sendTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final rawIngredients = data['ingredients'] as List<dynamic>? ?? [];
        final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.8;
        final mealName = data['mealName'] as String? ?? query;

        final ingredients = <IngredientEstimate>[];
        for (final item in rawIngredients) {
          if (item is Map<String, dynamic>) {
            final name = (item['name'] as String?)?.trim() ?? 'Ingredient';
            final grams = (item['estimatedGrams'] as num?)?.toDouble() ?? 100.0;
            final p = (item['proteinPer100g'] as num?)?.toDouble() ?? 0.0;
            final c = (item['carbsPer100g'] as num?)?.toDouble() ?? 0.0;
            final f = (item['fatsPer100g'] as num?)?.toDouble() ?? 0.0;
            final cal = (item['caloriesPer100g'] as num?)?.toDouble() ?? 0.0;

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

        if (ingredients.isNotEmpty) {
          return PhotoMealDraft(
            mealName: mealName,
            imagePath: '',
            estimatedIngredients: ingredients,
            confidence: confidence,
            userEdited: false,
          );
        }
      }
    } catch (e) {
      debugPrint('[GeminiNutritionService] Server proxy text parse error: $e');
    }

    // 2. Client fallback if server proxy was unreachable and client API key is configured
    final apiKey = _apiKey;
    if (apiKey != null && apiKey.isNotEmpty) {
      final traceId = Uuid().v4();
      final stopwatch = Stopwatch()..start();
      late final String textPrompt;
      try {
        final url =
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';
        textPrompt =
            'Parse this meal text description: "$query". '
            'Identify each ingredient separately. '
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
            '}';

        final requestBody = {
          'contents': [
            {
              'parts': [
                {'text': textPrompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.2,
            'responseMimeType': 'application/json',
          },
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

        if (response.statusCode == 200 && response.data != null) {
          final candidates = response.data['candidates'] as List<dynamic>?;
          final content =
              candidates?.firstOrNull?['content']?['parts']?[0]?['text']
                  as String?;
          if (content != null && content.isNotEmpty) {
            stopwatch.stop();
            _captureGeminiGeneration(
              traceId: traceId,
              input: [
                {'role': 'user', 'content': textPrompt},
              ],
              output: content,
              latency: stopwatch.elapsed,
              httpStatus: response.statusCode,
            );
            return parseGeminiResponse(content, imagePath: '');
          }
        }

        stopwatch.stop();
        _captureGeminiGeneration(
          traceId: traceId,
          input: [
            {'role': 'user', 'content': textPrompt},
          ],
          latency: stopwatch.elapsed,
          httpStatus: response.statusCode,
          isError: true,
          error: 'Gemini response did not contain generated content',
        );
      } catch (e) {
        stopwatch.stop();
        _captureGeminiGeneration(
          traceId: traceId,
          input: [
            {'role': 'user', 'content': textPrompt},
          ],
          latency: stopwatch.elapsed,
          isError: true,
          error: 'Gemini request failed',
        );
        debugPrint(
          '[GeminiNutritionService] Direct client text parse exception: $e',
        );
      }
    }

    // 3. Deterministic natural language fallback (zero network dependency)
    return _parseTextFallback(query);
  }

  /// Rule-based parser for common dietary phrases when offline
  PhotoMealDraft _parseTextFallback(String query) {
    const knowledgeBase = <String, Map<String, double>>{
      'roti': {
        'p': 7.8,
        'c': 46.0,
        'f': 1.5,
        'cal': 230.0,
        'defaultPortion': 35.0,
      },
      'chapati': {
        'p': 7.8,
        'c': 46.0,
        'f': 1.5,
        'cal': 230.0,
        'defaultPortion': 35.0,
      },
      'paratha': {
        'p': 6.5,
        'c': 42.0,
        'f': 12.0,
        'cal': 302.0,
        'defaultPortion': 65.0,
      },
      'dal': {
        'p': 5.5,
        'c': 14.5,
        'f': 2.8,
        'cal': 105.0,
        'defaultPortion': 180.0,
      },
      'curd': {
        'p': 3.5,
        'c': 4.4,
        'f': 4.1,
        'cal': 68.0,
        'defaultPortion': 150.0,
      },
      'dahi': {
        'p': 3.5,
        'c': 4.4,
        'f': 4.1,
        'cal': 68.0,
        'defaultPortion': 150.0,
      },
      'milk': {
        'p': 3.2,
        'c': 4.8,
        'f': 3.5,
        'cal': 64.0,
        'defaultPortion': 250.0,
      },
      'banana': {
        'p': 1.1,
        'c': 22.8,
        'f': 0.3,
        'cal': 89.0,
        'defaultPortion': 118.0,
      },
      'apple': {
        'p': 0.3,
        'c': 13.8,
        'f': 0.2,
        'cal': 52.0,
        'defaultPortion': 182.0,
      },
      'egg': {
        'p': 12.6,
        'c': 0.7,
        'f': 9.9,
        'cal': 143.0,
        'defaultPortion': 50.0,
      },
      'rice': {
        'p': 2.7,
        'c': 28.2,
        'f': 0.3,
        'cal': 130.0,
        'defaultPortion': 150.0,
      },
      'paneer': {
        'p': 18.3,
        'c': 2.5,
        'f': 20.8,
        'cal': 265.0,
        'defaultPortion': 100.0,
      },
      'chicken': {
        'p': 31.0,
        'c': 0.0,
        'f': 3.6,
        'cal': 165.0,
        'defaultPortion': 120.0,
      },
      'oats': {
        'p': 13.5,
        'c': 68.0,
        'f': 6.5,
        'cal': 389.0,
        'defaultPortion': 40.0,
      },
      'maaza': {
        'p': 0.1,
        'c': 13.5,
        'f': 0.1,
        'cal': 54.0,
        'defaultPortion': 250.0,
      },
      'maja': {
        'p': 0.1,
        'c': 13.5,
        'f': 0.1,
        'cal': 54.0,
        'defaultPortion': 250.0,
      },
      'juice': {
        'p': 0.5,
        'c': 11.5,
        'f': 0.2,
        'cal': 50.0,
        'defaultPortion': 240.0,
      },
      'tea': {
        'p': 0.5,
        'c': 4.0,
        'f': 0.8,
        'cal': 25.0,
        'defaultPortion': 150.0,
      },
      'coffee': {
        'p': 0.8,
        'c': 5.0,
        'f': 1.0,
        'cal': 32.0,
        'defaultPortion': 150.0,
      },
      'ghee': {
        'p': 0.0,
        'c': 0.0,
        'f': 99.5,
        'cal': 900.0,
        'defaultPortion': 15.0,
      },
      'butter': {
        'p': 0.9,
        'c': 0.1,
        'f': 81.0,
        'cal': 717.0,
        'defaultPortion': 15.0,
      },
    };

    final segments = query
        .split(RegExp(r',|\band\b|\+|\&', caseSensitive: false))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);

    final ingredients = <IngredientEstimate>[];
    for (final seg in segments) {
      final match = RegExp(
        r'^(?:(\w+|\d+(?:\.\d+)?)\s+)?(?:(litres?|liters?|l|millilitres?|milliliters?|ml|kilograms?|kg|bowl|katori|cup|glass|slice|piece|serving|tbsp|tsp|grams?|g)\s+(?:of\s+)?)?(.+)$',
        caseSensitive: false,
      ).firstMatch(seg);

      double count = 1.0;
      String unit = '';
      String foodName = seg.toLowerCase();

      if (match != null) {
        final countStr = (match.group(1) ?? '1').toLowerCase();
        const wordToNum = {
          'one': 1.0,
          'two': 2.0,
          'three': 3.0,
          'four': 4.0,
          'five': 5.0,
          'six': 6.0,
          'seven': 7.0,
          'eight': 8.0,
          'nine': 9.0,
          'ten': 10.0,
          'a': 1.0,
          'an': 1.0,
        };
        count = wordToNum[countStr] ?? double.tryParse(countStr) ?? 1.0;
        unit = (match.group(2) ?? '').toLowerCase();
        foodName = (match.group(3) ?? '').toLowerCase().trim();
      }

      // Check for attached units like "150g", "250ml", "1l", "1kg"
      final explicitUnitMatch = RegExp(
        r'(\d+(?:\.\d+)?)\s*(litres?|liters?|l|millilitres?|milliliters?|ml|kilograms?|kg|grams?|g)\b',
        caseSensitive: false,
      ).firstMatch(seg);
      if (explicitUnitMatch != null) {
        count = double.parse(explicitUnitMatch.group(1)!);
        unit = explicitUnitMatch.group(2)!.toLowerCase();
      }

      String? matchedKey;
      for (final key in knowledgeBase.keys) {
        if (foodName.contains(key)) {
          matchedKey = key;
          break;
        }
      }

      // Determine food-specific density (g/ml) for liquid conversions
      double density = 1.0;
      final lowerSeg = seg.toLowerCase();
      if (lowerSeg.contains('maja') ||
          lowerSeg.contains('maaza') ||
          lowerSeg.contains('juice') ||
          lowerSeg.contains('frooti') ||
          lowerSeg.contains('syrup') ||
          lowerSeg.contains('soda')) {
        density = 1.05;
      } else if (lowerSeg.contains('milk') ||
          lowerSeg.contains('dahi') ||
          lowerSeg.contains('curd') ||
          lowerSeg.contains('lassi') ||
          lowerSeg.contains('shake')) {
        density = 1.03;
      } else if (lowerSeg.contains('oil') || lowerSeg.contains('ghee')) {
        density = 0.92;
      } else if (lowerSeg.contains('honey')) {
        density = 1.42;
      }

      double grams = 100.0;
      double p = 5.0;
      double c = 15.0;
      double f = 3.0;
      double cal = 107.0;

      if (matchedKey != null) {
        final info = knowledgeBase[matchedKey]!;
        p = info['p']!;
        c = info['c']!;
        f = info['f']!;
        cal = info['cal']!;

        if (unit == 'l' ||
            unit == 'litre' ||
            unit == 'litres' ||
            unit == 'liter' ||
            unit == 'liters') {
          grams = count * 1000.0 * density;
        } else if (unit == 'ml' ||
            unit == 'millilitre' ||
            unit == 'millilitres' ||
            unit == 'milliliter' ||
            unit == 'milliliters') {
          grams = count;
        } else if (unit == 'kg' || unit == 'kilogram' || unit == 'kilograms') {
          grams = count * 1000.0;
        } else if (unit == 'g' || unit == 'gram' || unit == 'grams') {
          grams = count;
        } else if (unit == 'bowl' || unit == 'katori') {
          grams = count * 180.0;
        } else if (unit == 'glass' || unit == 'cup') {
          grams = count * 240.0;
        } else if (unit == 'tbsp') {
          grams = count * 15.0 * density;
        } else if (unit == 'tsp') {
          grams = count * 5.0 * density;
        } else {
          grams = count * info['defaultPortion']!;
        }
      } else {
        if (unit == 'l' ||
            unit == 'litre' ||
            unit == 'litres' ||
            unit == 'liter' ||
            unit == 'liters') {
          grams = count * 1000.0 * density;
        } else if (unit == 'ml' ||
            unit == 'millilitre' ||
            unit == 'millilitres' ||
            unit == 'milliliter' ||
            unit == 'milliliters') {
          grams = count;
        } else if (unit == 'kg' || unit == 'kilogram' || unit == 'kilograms') {
          grams = count * 1000.0;
        } else if (unit == 'g' || unit == 'gram' || unit == 'grams') {
          grams = count;
        } else if (unit == 'glass' || unit == 'cup') {
          grams = count * 240.0;
        } else if (unit == 'bowl' || unit == 'katori') {
          grams = count * 180.0;
        } else {
          final gramMatch = RegExp(
            r'(\d+)\s*(g|grams|ml)\b',
            caseSensitive: false,
          ).firstMatch(seg);
          if (gramMatch != null) {
            grams = double.tryParse(gramMatch.group(1) ?? '') ?? 100.0;
          }
        }
      }

      ingredients.add(
        IngredientEstimate(
          name: seg.substring(0, 1).toUpperCase() + seg.substring(1),
          estimatedGrams: double.parse(grams.toStringAsFixed(1)),
          proteinPer100g: double.parse(p.toStringAsFixed(1)),
          carbsPer100g: double.parse(c.toStringAsFixed(1)),
          fatsPer100g: double.parse(f.toStringAsFixed(1)),
          caloriesPer100g: double.parse(cal.toStringAsFixed(1)),
        ),
      );
    }

    return PhotoMealDraft(
      mealName: query.length > 28 ? '${query.substring(0, 25)}...' : query,
      imagePath: '',
      estimatedIngredients: ingredients,
      confidence: ingredients.isNotEmpty ? 0.75 : 0.3,
      userEdited: false,
    );
  }

  Future<PhotoMealDraft> analyzeMealPhoto(String imagePath) async {
    final apiKey = _apiKey;
    String? traceId;
    Stopwatch? stopwatch;

    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Image file not found at $imagePath');
      }

      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Try server proxy first if client apiKey is not present
      if (apiKey == null || apiKey.isEmpty) {
        try {
          final proxyResponse = await _dio.post(
            _proxyUrl,
            data: {'imageBase64': base64Image},
            options: Options(
              headers: {
                'Content-Type': 'application/json',
                ..._aiObservabilityHeaders,
              },
              sendTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 25),
            ),
          );

          if (proxyResponse.statusCode == 200 && proxyResponse.data != null) {
            final data = proxyResponse.data as Map<String, dynamic>;
            final rawIngredients = data['ingredients'] as List<dynamic>? ?? [];
            final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.8;
            final mealName = data['mealName'] as String? ?? 'Detected Meal';

            final ingredients = <IngredientEstimate>[];
            for (final item in rawIngredients) {
              if (item is Map<String, dynamic>) {
                ingredients.add(
                  IngredientEstimate(
                    name: (item['name'] as String?)?.trim() ?? 'Ingredient',
                    estimatedGrams:
                        (item['estimatedGrams'] as num?)?.toDouble() ?? 100.0,
                    proteinPer100g:
                        (item['proteinPer100g'] as num?)?.toDouble() ?? 0.0,
                    carbsPer100g:
                        (item['carbsPer100g'] as num?)?.toDouble() ?? 0.0,
                    fatsPer100g:
                        (item['fatsPer100g'] as num?)?.toDouble() ?? 0.0,
                    caloriesPer100g:
                        (item['caloriesPer100g'] as num?)?.toDouble() ?? 0.0,
                  ),
                );
              }
            }

            return PhotoMealDraft(
              mealName: mealName,
              imagePath: imagePath,
              estimatedIngredients: ingredients,
              confidence: confidence,
              userEdited: false,
            );
          }
        } catch (e) {
          debugPrint(
            '[GeminiNutritionService] Server proxy photo parse error: $e',
          );
        }

        debugPrint(
          '[GeminiNutritionService] Warning: GEMINI_API_KEY is not configured and server proxy failed',
        );
        return PhotoMealDraft(
          mealName: 'Unrecognized Meal',
          imagePath: imagePath,
          estimatedIngredients: const [],
          confidence: 0.0,
        );
      }

      final url =
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';
      traceId = Uuid().v4();
      stopwatch = Stopwatch()..start();

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': _prompt},
              {
                'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image},
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.2,
          'responseMimeType': 'application/json',
        },
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
        stopwatch.stop();
        _captureGeminiGeneration(
          traceId: traceId,
          input: [
            {'role': 'user', 'content': _prompt},
          ],
          latency: stopwatch.elapsed,
          httpStatus: response.statusCode,
          isError: true,
          error: 'Gemini returned an unsuccessful response',
        );
        debugPrint(
          '[GeminiNutritionService] Error: HTTP ${response.statusCode} -> ${response.data}',
        );
        return PhotoMealDraft(
          mealName: 'Failed Analysis',
          imagePath: imagePath,
          estimatedIngredients: const [],
          confidence: 0.0,
        );
      }

      final candidates = response.data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        stopwatch.stop();
        _captureGeminiGeneration(
          traceId: traceId,
          input: [
            {'role': 'user', 'content': _prompt},
          ],
          latency: stopwatch.elapsed,
          httpStatus: response.statusCode,
          isError: true,
          error: 'Gemini returned no candidates',
        );
        return PhotoMealDraft(
          mealName: 'No Candidates Returned',
          imagePath: imagePath,
          estimatedIngredients: const [],
          confidence: 0.0,
        );
      }

      final content =
          candidates.first['content']?['parts']?[0]?['text'] as String?;
      if (content == null || content.isEmpty) {
        stopwatch.stop();
        _captureGeminiGeneration(
          traceId: traceId,
          input: [
            {'role': 'user', 'content': _prompt},
          ],
          latency: stopwatch.elapsed,
          httpStatus: response.statusCode,
          isError: true,
          error: 'Gemini returned empty content',
        );
        return PhotoMealDraft(
          mealName: 'Empty Analysis',
          imagePath: imagePath,
          estimatedIngredients: const [],
          confidence: 0.0,
        );
      }

      stopwatch.stop();
      _captureGeminiGeneration(
        traceId: traceId,
        input: [
          {'role': 'user', 'content': _prompt},
        ],
        output: content,
        latency: stopwatch.elapsed,
        httpStatus: response.statusCode,
      );
      return parseGeminiResponse(content, imagePath: imagePath);
    } catch (e, st) {
      if (traceId != null && stopwatch != null) {
        stopwatch.stop();
        _captureGeminiGeneration(
          traceId: traceId,
          input: [
            {'role': 'user', 'content': _prompt},
          ],
          latency: stopwatch.elapsed,
          isError: true,
          error: 'Gemini request failed',
        );
      }
      debugPrint(
        '[GeminiNutritionService] Exception during meal analysis: $e\n$st',
      );
      return PhotoMealDraft(
        mealName: 'Analysis Error',
        imagePath: imagePath,
        estimatedIngredients: const [],
        confidence: 0.0,
      );
    }
  }

  void _captureGeminiGeneration({
    required String traceId,
    required List<Map<String, String>> input,
    String? output,
    required Duration latency,
    int? httpStatus,
    bool isError = false,
    String? error,
  }) {
    final properties = <String, Object>{
      r'$ai_trace_id': traceId,
      r'$ai_session_id': _aiSessionId,
      r'$ai_span_name': 'nutrition_meal_analysis',
      r'$ai_model': 'gemini-1.5-flash',
      r'$ai_provider': 'gemini',
      r'$ai_input': input,
      r'$ai_latency': latency.inMicroseconds / Duration.microsecondsPerSecond,
      r'$ai_temperature': 0.2,
      r'$ai_is_error': isError,
    };
    if (output != null) {
      properties[r'$ai_output_choices'] = [
        {'role': 'assistant', 'content': output},
      ];
    }
    if (httpStatus != null) properties[r'$ai_http_status'] = httpStatus;
    if (error != null) properties[r'$ai_error'] = error;

    unawaited(_sendAiGeneration(properties));
  }

  Future<void> _sendAiGeneration(Map<String, Object> properties) async {
    try {
      await Posthog().capture(
        eventName: r'$ai_generation',
        properties: properties,
      );
    } catch (e) {
      debugPrint(
        '[GeminiNutritionService] AI observability capture failed: $e',
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
      final mealName =
          (json['meal_name'] as String?)?.trim() ?? 'Identified Meal';
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
            debugPrint(
              '[GeminiNutritionService] Sanity warning: $name has suspicious $cal kcal/100g, clamping to 900.0',
            );
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
      debugPrint(
        '[GeminiNutritionService] JSON Parse error: $e for text: $rawText',
      );
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
