import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/food_repository_impl.dart';
import '../../domain/models/food_item.dart';

class UserFoodFormSheet extends ConsumerStatefulWidget {
  final String? initialBarcode;
  final String? initialName;

  const UserFoodFormSheet({
    super.key,
    this.initialBarcode,
    this.initialName,
  });

  static Future<FoodItem?> show(
    BuildContext context, {
    String? initialBarcode,
    String? initialName,
  }) {
    return showModalBottomSheet<FoodItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UserFoodFormSheet(
        initialBarcode: initialBarcode,
        initialName: initialName,
      ),
    );
  }

  @override
  ConsumerState<UserFoodFormSheet> createState() => _UserFoodFormSheetState();
}

class _UserFoodFormSheetState extends ConsumerState<UserFoodFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _barcodeController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatsController;
  late TextEditingController _caloriesController;

  final List<ServingPreset> _presets = [
    const ServingPreset(label: '100g', grams: 100),
    const ServingPreset(label: '1 serving (50g)', grams: 50),
  ];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _brandController = TextEditingController();
    _barcodeController = TextEditingController(text: widget.initialBarcode ?? '');
    _proteinController = TextEditingController(text: '0');
    _carbsController = TextEditingController(text: '0');
    _fatsController = TextEditingController(text: '0');
    _caloriesController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _barcodeController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _recalcCalories() {
    final p = double.tryParse(_proteinController.text) ?? 0.0;
    final c = double.tryParse(_carbsController.text) ?? 0.0;
    final f = double.tryParse(_fatsController.text) ?? 0.0;
    final cal = (p * 4) + (c * 4) + (f * 9);
    _caloriesController.text = cal.round().toString();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final p = double.tryParse(_proteinController.text) ?? 0.0;
    final c = double.tryParse(_carbsController.text) ?? 0.0;
    final f = double.tryParse(_fatsController.text) ?? 0.0;
    double cal = double.tryParse(_caloriesController.text) ?? 0.0;
    if (cal <= 0) {
      cal = (p * 4) + (c * 4) + (f * 9);
    }

    final newFood = FoodItem(
      id: const Uuid().v4(),
      barcode: _barcodeController.text.trim().isNotEmpty
          ? _barcodeController.text.trim()
          : null,
      name: _nameController.text.trim(),
      brand: _brandController.text.trim().isNotEmpty
          ? _brandController.text.trim()
          : null,
      proteinPer100g: p,
      carbsPer100g: c,
      fatsPer100g: f,
      caloriesPer100g: cal,
      servingPresets: _presets,
      source: FoodSource.user_custom,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(foodRepositoryProvider).saveFood(newFood);
      if (mounted) {
        Navigator.of(context).pop(newFood);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save food: $e')),
        );
      }
    }
  }

  void _addPresetDialog() {
    final labelCtrl = TextEditingController(text: '1 portion');
    final gramsCtrl = TextEditingController(text: '100');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Serving Preset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(labelText: 'Label (e.g. 1 scoop, 1 cup)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: gramsCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Grams equivalent'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final g = double.tryParse(gramsCtrl.text) ?? 0.0;
              if (labelCtrl.text.isNotEmpty && g > 0) {
                setState(() {
                  _presets.add(ServingPreset(label: labelCtrl.text.trim(), grams: g));
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark
              ? AppColors.darkSurfaceBorder
              : AppColors.lightSurfaceBorder,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                child: Row(
                  children: [
                    const Icon(Icons.restaurant_rounded, color: AppColors.limeGreen),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Add Custom Food',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Form fields
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Food Name *',
                        hintText: 'e.g. Masala Oats with Nuts',
                        prefixIcon: Icon(Icons.fastfood_rounded),
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _brandController,
                            decoration: const InputDecoration(
                              labelText: 'Brand (Optional)',
                              hintText: 'e.g. Quaker / Homemade',
                              prefixIcon: Icon(Icons.branding_watermark_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _barcodeController,
                            decoration: const InputDecoration(
                              labelText: 'Barcode (Optional)',
                              prefixIcon: Icon(Icons.qr_code_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Nutritional Values per 100g',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _proteinController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Protein (g)',
                              suffixText: 'g',
                            ),
                            onChanged: (_) => _recalcCalories(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _carbsController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Carbs (g)',
                              suffixText: 'g',
                            ),
                            onChanged: (_) => _recalcCalories(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _fatsController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Fats (g)',
                              suffixText: 'g',
                            ),
                            onChanged: (_) => _recalcCalories(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _caloriesController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Calories',
                              suffixText: 'kcal',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Serving presets
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Serving Presets',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addPresetDialog,
                          icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.limeGreen),
                          label: const Text('Add Preset', style: TextStyle(color: AppColors.limeGreen)),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _presets.map((preset) {
                        return Chip(
                          label: Text('${preset.label} (${preset.grams.toInt()}g)'),
                          deleteIcon: const Icon(Icons.close_rounded, size: 16),
                          onDeleted: _presets.length > 1
                              ? () => setState(() => _presets.remove(preset))
                              : null,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.limeGreen,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    onPressed: _isSaving ? null : _submit,
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text('Save & Continue'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
