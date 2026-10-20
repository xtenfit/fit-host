import 'dart:convert';

enum FoodSource {
  seeded,
  openfoodfacts,
  gemini,
  // ignore: constant_identifier_names
  user_custom,
}

class ServingPreset {
  final String label;
  final double grams;

  const ServingPreset({
    required this.label,
    required this.grams,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'grams': grams,
      };

  factory ServingPreset.fromJson(Map<String, dynamic> json) => ServingPreset(
        label: json['label'] as String? ?? '100g',
        grams: (json['grams'] as num?)?.toDouble() ?? 100.0,
      );

  ServingPreset copyWith({
    String? label,
    double? grams,
  }) =>
      ServingPreset(
        label: label ?? this.label,
        grams: grams ?? this.grams,
      );
}

class FoodItem {
  final String id;
  final String? barcode;
  final String name;
  final String? brand;
  final String servingUnit;
  final List<ServingPreset> servingPresets;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatsPer100g;
  final double caloriesPer100g;
  final FoodSource source;
  final String? imageUrl;
  final DateTime createdAt;

  FoodItem({
    required this.id,
    this.barcode,
    required this.name,
    this.brand,
    this.servingUnit = 'g',
    this.servingPresets = const [],
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatsPer100g,
    required this.caloriesPer100g,
    this.source = FoodSource.seeded,
    this.imageUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  FoodItem copyWith({
    String? id,
    String? barcode,
    String? name,
    String? brand,
    String? servingUnit,
    List<ServingPreset>? servingPresets,
    double? proteinPer100g,
    double? carbsPer100g,
    double? fatsPer100g,
    double? caloriesPer100g,
    FoodSource? source,
    String? imageUrl,
    DateTime? createdAt,
  }) =>
      FoodItem(
        id: id ?? this.id,
        barcode: barcode ?? this.barcode,
        name: name ?? this.name,
        brand: brand ?? this.brand,
        servingUnit: servingUnit ?? this.servingUnit,
        servingPresets: servingPresets ?? this.servingPresets,
        proteinPer100g: proteinPer100g ?? this.proteinPer100g,
        carbsPer100g: carbsPer100g ?? this.carbsPer100g,
        fatsPer100g: fatsPer100g ?? this.fatsPer100g,
        caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
        source: source ?? this.source,
        imageUrl: imageUrl ?? this.imageUrl,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'barcode': barcode,
        'name': name,
        'brand': brand,
        'serving_unit': servingUnit,
        'serving_presets': servingPresets.map((p) => p.toJson()).toList(),
        'protein_per_100g': proteinPer100g,
        'carbs_per_100g': carbsPer100g,
        'fats_per_100g': fatsPer100g,
        'calories_per_100g': caloriesPer100g,
        'source': source.name,
        'image_url': imageUrl,
        'created_at': createdAt.toIso8601String(),
      };

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    List<ServingPreset> presets = [];
    if (json['serving_presets'] != null) {
      final list = json['serving_presets'] is String
          ? jsonDecode(json['serving_presets'] as String) as List<dynamic>
          : json['serving_presets'] as List<dynamic>;
      presets = list
          .map((p) => ServingPreset.fromJson(p as Map<String, dynamic>))
          .toList();
    }

    return FoodItem(
      id: json['id'] as String,
      barcode: json['barcode'] as String?,
      name: json['name'] as String? ?? 'Food Item',
      brand: json['brand'] as String?,
      servingUnit: json['serving_unit'] as String? ?? 'g',
      servingPresets: presets,
      proteinPer100g: (json['protein_per_100g'] as num?)?.toDouble() ?? 0.0,
      carbsPer100g: (json['carbs_per_100g'] as num?)?.toDouble() ?? 0.0,
      fatsPer100g: (json['fats_per_100g'] as num?)?.toDouble() ?? 0.0,
      caloriesPer100g: (json['calories_per_100g'] as num?)?.toDouble() ?? 0.0,
      source: FoodSource.values.firstWhere(
        (s) => s.name == (json['source'] as String? ?? 'seeded'),
        orElse: () => FoodSource.seeded,
      ),
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
