import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/food_item.dart';
import '../../domain/models/meal_entry.dart';
import '../../domain/models/photo_meal_draft.dart';
import '../controllers/nutrition_controller.dart';

class QuantityEntryScreen extends ConsumerStatefulWidget {
  final FoodItem? food;
  final PhotoMealDraft? photoDraft;
  final MealEntry? existingEntry; // if editing an existing entry

  const QuantityEntryScreen({
    super.key,
    this.food,
    this.photoDraft,
    this.existingEntry,
  }) : assert(food != null || photoDraft != null || existingEntry != null,
            'Must provide food, photoDraft, or existingEntry');

  @override
  ConsumerState<QuantityEntryScreen> createState() => _QuantityEntryScreenState();
}

class _QuantityEntryScreenState extends ConsumerState<QuantityEntryScreen> {
  late double _quantityGrams;
  late TextEditingController _quantityController;
  late MealType _selectedMealType;
  late TextEditingController _customMealLabelController;
  late DateTime _selectedDate;

  // Photo meal editable ingredients
  List<IngredientEstimate> _ingredients = [];

  @override
  void initState() {
    super.initState();
    if (widget.photoDraft != null) {
      _ingredients = List.from(widget.photoDraft!.estimatedIngredients);
      _quantityGrams = widget.photoDraft!.totalGrams > 0
          ? widget.photoDraft!.totalGrams
          : 150.0;
    } else if (widget.existingEntry != null) {
      _quantityGrams = widget.existingEntry!.quantityGrams;
    } else {
      _quantityGrams = 100.0;
    }

    _quantityController = TextEditingController(text: '${_quantityGrams.toInt()}');
    _selectedMealType = widget.existingEntry?.mealType ?? MealType.fromCurrentHour();
    _customMealLabelController = TextEditingController(
      text: widget.existingEntry?.customMealLabel ?? '',
    );
    _selectedDate = widget.existingEntry?.consumedAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _customMealLabelController.dispose();
    super.dispose();
  }

  void _updateQuantity(double val) {
    setState(() {
      _quantityGrams = val.clamp(1.0, 2000.0);
      _quantityController.text = '${_quantityGrams.toInt()}';
    });
  }

  // Live macro calculation
  double get _proteinPer100g {
    if (widget.photoDraft != null && _ingredients.isNotEmpty) {
      final totalGrams = _ingredients.fold(0.0, (sum, i) => sum + i.estimatedGrams);
      if (totalGrams <= 0) return 0.0;
      final totalP = _ingredients.fold(0.0, (sum, i) => sum + i.protein);
      return (totalP / totalGrams) * 100;
    }
    return widget.food?.proteinPer100g ??
        widget.existingEntry?.proteinPer100g ??
        0.0;
  }

  double get _carbsPer100g {
    if (widget.photoDraft != null && _ingredients.isNotEmpty) {
      final totalGrams = _ingredients.fold(0.0, (sum, i) => sum + i.estimatedGrams);
      if (totalGrams <= 0) return 0.0;
      final totalC = _ingredients.fold(0.0, (sum, i) => sum + i.carbs);
      return (totalC / totalGrams) * 100;
    }
    return widget.food?.carbsPer100g ??
        widget.existingEntry?.carbsPer100g ??
        0.0;
  }

  double get _fatsPer100g {
    if (widget.photoDraft != null && _ingredients.isNotEmpty) {
      final totalGrams = _ingredients.fold(0.0, (sum, i) => sum + i.estimatedGrams);
      if (totalGrams <= 0) return 0.0;
      final totalF = _ingredients.fold(0.0, (sum, i) => sum + i.fats);
      return (totalF / totalGrams) * 100;
    }
    return widget.food?.fatsPer100g ??
        widget.existingEntry?.fatsPer100g ??
        0.0;
  }

  double get _caloriesPer100g {
    if (widget.photoDraft != null && _ingredients.isNotEmpty) {
      final totalGrams = _ingredients.fold(0.0, (sum, i) => sum + i.estimatedGrams);
      if (totalGrams <= 0) return 0.0;
      final totalCal = _ingredients.fold(0.0, (sum, i) => sum + i.calories);
      return (totalCal / totalGrams) * 100;
    }
    return widget.food?.caloriesPer100g ??
        widget.existingEntry?.caloriesPer100g ??
        0.0;
  }

  double get _computedProtein => (_proteinPer100g * _quantityGrams) / 100;
  double get _computedCarbs => (_carbsPer100g * _quantityGrams) / 100;
  double get _computedFats => (_fatsPer100g * _quantityGrams) / 100;
  double get _computedCalories => (_caloriesPer100g * _quantityGrams) / 100;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  void _addCustomIngredientDialog() {
    final nameCtrl = TextEditingController();
    final gramsCtrl = TextEditingController(text: '50');
    final pCtrl = TextEditingController(text: '5');
    final cCtrl = TextEditingController(text: '10');
    final fCtrl = TextEditingController(text: '2');
    final calCtrl = TextEditingController(text: '80');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Ingredient'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name (e.g. Olive Oil)')),
              const SizedBox(height: 8),
              TextField(controller: gramsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Grams')),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: pCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'P / 100g'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: cCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'C / 100g'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: fCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'F / 100g'))),
                ],
              ),
              const SizedBox(height: 8),
              TextField(controller: calCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calories / 100g')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                final g = double.tryParse(gramsCtrl.text) ?? 50.0;
                final p = double.tryParse(pCtrl.text) ?? 0.0;
                final c = double.tryParse(cCtrl.text) ?? 0.0;
                final f = double.tryParse(fCtrl.text) ?? 0.0;
                final cal = double.tryParse(calCtrl.text) ?? ((p * 4) + (c * 4) + (f * 9));
                setState(() {
                  _ingredients.add(
                    IngredientEstimate(
                      name: nameCtrl.text.trim(),
                      estimatedGrams: g,
                      proteinPer100g: p,
                      carbsPer100g: c,
                      fatsPer100g: f,
                      caloriesPer100g: cal,
                    ),
                  );
                  _quantityGrams = _ingredients.fold(0.0, (s, i) => s + i.estimatedGrams);
                  _quantityController.text = '${_quantityGrams.toInt()}';
                });
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMeal() async {
    final foodName = widget.photoDraft != null
        ? widget.photoDraft!.mealName
        : (widget.food?.name ?? widget.existingEntry?.foodName ?? 'Meal');

    final brand = widget.food?.brand ?? widget.existingEntry?.brand;

    final entryId = widget.existingEntry?.id ?? const Uuid().v4();

    final entry = MealEntry(
      id: entryId,
      foodId: widget.food?.id ?? widget.existingEntry?.foodId,
      foodName: foodName,
      brand: brand,
      quantityGrams: _quantityGrams,
      mealType: _selectedMealType,
      customMealLabel: _selectedMealType == MealType.custom
          ? _customMealLabelController.text.trim()
          : null,
      consumedAt: _selectedDate,
      proteinPer100g: _proteinPer100g,
      carbsPer100g: _carbsPer100g,
      fatsPer100g: _fatsPer100g,
      caloriesPer100g: _caloriesPer100g,
    );

    final mealItem = entry.toMealItem();
    ref.read(nutritionProvider.notifier).logMeal(mealItem);

    // Close screen
    Navigator.of(context).pop(true);

    // Show SnackBar with Undo
    final mealTypeLabel = entry.mealType == MealType.custom &&
            entry.customMealLabel != null &&
            entry.customMealLabel!.isNotEmpty
        ? entry.customMealLabel!
        : entry.mealType.displayName;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added to $mealTypeLabel (${entry.caloriesInt} kcal)'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: AppColors.limeGreen,
          onPressed: () {
            ref.read(nutritionProvider.notifier).removeLoggedMeal(mealItem.id);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final foodName = widget.photoDraft != null
        ? widget.photoDraft!.mealName
        : (widget.food?.name ?? widget.existingEntry?.foodName ?? 'Meal');

    final brand = widget.food?.brand ?? widget.existingEntry?.brand;
    final presets = widget.food?.servingPresets ??
        const [
          ServingPreset(label: '100g', grams: 100),
          ServingPreset(label: '1 serving (50g)', grams: 50),
          ServingPreset(label: '1 cup (200g)', grams: 200),
        ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Meal'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            // 1. Food Header
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Photo or Icon
                    if (widget.photoDraft != null &&
                        widget.photoDraft!.imagePath.isNotEmpty &&
                        !kIsWeb &&
                        File(widget.photoDraft!.imagePath).existsSync())
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          File(widget.photoDraft!.imagePath),
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.limeGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.restaurant_rounded,
                          color: AppColors.limeGreen,
                          size: 28,
                        ),
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            foodName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          if (brand != null && brand.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              brand,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                          if (widget.photoDraft != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.auto_awesome_rounded,
                                    size: 14, color: AppColors.electricCyan),
                                const SizedBox(width: 4),
                                Text(
                                  'Gemini AI Estimate (${(widget.photoDraft!.confidence * 100).toInt()}% conf)',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.electricCyan,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // If photo meal: Ingredient editor
            if (widget.photoDraft != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Identified Ingredients',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addCustomIngredientDialog,
                    icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.limeGreen),
                    label: const Text('Add Ingredient', style: TextStyle(color: AppColors.limeGreen)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._ingredients.map((ing) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    title: Text(
                      ing.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${ing.estimatedGrams.toInt()}g · ${ing.calories.toInt()} kcal (P:${ing.protein.toStringAsFixed(1)}g C:${ing.carbs.toStringAsFixed(1)}g F:${ing.fats.toStringAsFixed(1)}g)',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                      onPressed: () {
                        setState(() {
                          _ingredients.remove(ing);
                          _quantityGrams = _ingredients.fold(0.0, (s, i) => s + i.estimatedGrams);
                          _quantityController.text = '${_quantityGrams.toInt()}';
                        });
                      },
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // 2. Quantity Input Section
            Text(
              'Quantity (Grams)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _quantityGrams.clamp(5.0, 1000.0),
                    min: 5.0,
                    max: 1000.0,
                    divisions: 199,
                    activeColor: AppColors.limeGreen,
                    inactiveColor: isDark
                        ? AppColors.darkSurfaceBorder
                        : AppColors.lightSurfaceBorder,
                    onChanged: (val) => _updateQuantity(val),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      suffixText: 'g',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onSubmitted: (val) {
                      final parsed = double.tryParse(val) ?? _quantityGrams;
                      _updateQuantity(parsed);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Serving Preset Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presets.map((p) {
                final isSelected = (_quantityGrams - p.grams).abs() < 1.0;
                return ChoiceChip(
                  label: Text(p.label),
                  selected: isSelected,
                  selectedColor: AppColors.limeGreen.withValues(alpha: 0.2),
                  side: BorderSide(
                    color: isSelected ? AppColors.limeGreen : Colors.transparent,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      _updateQuantity(p.grams);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Live-updating Macro Preview Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMacroTile(
                    label: 'Calories',
                    value: '${_computedCalories.round()}',
                    unit: 'kcal',
                    color: AppColors.limeGreen,
                    icon: '🔥',
                  ),
                  _buildMacroTile(
                    label: 'Protein',
                    value: _computedProtein.toStringAsFixed(1),
                    unit: 'g',
                    color: AppColors.electricCyan,
                    icon: '🥩',
                  ),
                  _buildMacroTile(
                    label: 'Carbs',
                    value: _computedCarbs.toStringAsFixed(1),
                    unit: 'g',
                    color: AppColors.electricBlueLight,
                    icon: '🍞',
                  ),
                  _buildMacroTile(
                    label: 'Fats',
                    value: _computedFats.toStringAsFixed(1),
                    unit: 'g',
                    color: AppColors.warmCoral,
                    icon: '🥑',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Meal Type Selector
            Text(
              'Meal Type',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MealType.values.map((type) {
                final isSelected = _selectedMealType == type;
                return ChoiceChip(
                  label: Text(type.displayName),
                  selected: isSelected,
                  selectedColor: AppColors.limeGreen,
                  labelStyle: TextStyle(
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.black : null,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedMealType = type);
                    }
                  },
                );
              }).toList(),
            ),

            if (_selectedMealType == MealType.custom) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customMealLabelController,
                decoration: InputDecoration(
                  labelText: 'Custom Meal Name',
                  hintText: 'e.g. Post-Workout Shake, Midnight Snack',
                  prefixIcon: const Icon(Icons.label_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // 4. Date / Time Picker
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.limeGreen),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
            ),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.limeGreen,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            onPressed: _saveMeal,
            child: Text(widget.existingEntry != null ? 'Update Meal' : 'Log to Diary'),
          ),
        ),
      ),
    );
  }

  Widget _buildMacroTile({
    required String label,
    required String value,
    required String unit,
    required Color color,
    required String icon,
  }) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
