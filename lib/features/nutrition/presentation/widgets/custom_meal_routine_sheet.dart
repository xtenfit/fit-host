import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/nutrition_models.dart';
import '../controllers/nutrition_controller.dart';

class CustomMealRoutineSheet extends ConsumerStatefulWidget {
  const CustomMealRoutineSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CustomMealRoutineSheet(),
    );
  }

  @override
  ConsumerState<CustomMealRoutineSheet> createState() =>
      _CustomMealRoutineSheetState();
}

class _CustomMealRoutineSheetState
    extends ConsumerState<CustomMealRoutineSheet> {
  String _selectedDiet = 'all'; // 'all', 'vegan', 'non_veg'
  final String _selectedMealCategory = 'all'; // 'all', 'breakfast', 'lunch', 'dinner', 'snack'

  @override
  Widget build(BuildContext context) {
    final nutrition = ref.watch(nutritionProvider);
    final notifier = ref.read(nutritionProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final allPresets = [...defaultPresetMeals, ...nutrition.customMeals];
    final filteredMeals = allPresets.where((m) {
      if (_selectedDiet != 'all' && m.dietType != _selectedDiet) {
        return false;
      }
      if (_selectedMealCategory != 'all' && m.mealType != _selectedMealCategory) {
        return false;
      }
      return true;
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.96,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBackground : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag Handle & Header
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.limeGreen.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.restaurant_menu_rounded,
                            color: AppColors.limeGreen,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nutrient & Calorie Tracker',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Gain vs Burn • Vegan & Non-Veg Routines',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.darkTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Scrollable Body
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  children: [
                    // 1. Calorie Balance Card (Gain vs Burn vs Remaining)
                    _CalorieBalanceCard(
                      nutrition: nutrition,
                      isDark: isDark,
                      onAddBurn: () => notifier.addBurnedCalories(50),
                    ),
                    const SizedBox(height: 16),

                    // 2. Macro Split Progress
                    _MacroSplitBar(
                      nutrition: nutrition,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 20),

                    // 3. Goal Mode Switcher
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Nutrition Goal',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${nutrition.targetCalories} kcal target',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.electricCyan,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _GoalChip(
                          label: '💪 Hypertrophy (+300)',
                          isSelected: nutrition.goalMode == 'hypertrophy',
                          onTap: () => notifier.setGoalMode('hypertrophy'),
                          isDark: isDark,
                        ),
                        _GoalChip(
                          label: '✂️ Fat Loss (-500)',
                          isSelected: nutrition.goalMode == 'cutting',
                          onTap: () => notifier.setGoalMode('cutting'),
                          isDark: isDark,
                        ),
                        _GoalChip(
                          label: '⚖️ Recomp (Maintain)',
                          isSelected: nutrition.goalMode == 'recomp',
                          onTap: () => notifier.setGoalMode('recomp'),
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 4. Meal Routine Setup Header & Dietary Filter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Custom Meal Routines',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Tap + to log directly to daily intake',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.darkTextSecondary,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 16, color: Colors.black),
                          label: const Text(
                            'Custom Meal',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          onPressed: () => _showAddCustomMealDialog(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Vegan vs Non-Veg Filter Chips
                    Row(
                      children: [
                        _DietFilterPill(
                          label: 'All Diets',
                          icon: Icons.all_inclusive_rounded,
                          isSelected: _selectedDiet == 'all',
                          onTap: () => setState(() => _selectedDiet = 'all'),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _DietFilterPill(
                          label: '🥗 Vegan',
                          icon: Icons.eco_rounded,
                          isSelected: _selectedDiet == 'vegan',
                          onTap: () => setState(() => _selectedDiet = 'vegan'),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _DietFilterPill(
                          label: '🥩 Non-Veg',
                          icon: Icons.restaurant_rounded,
                          isSelected: _selectedDiet == 'non_veg',
                          onTap: () => setState(() => _selectedDiet = 'non_veg'),
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Preset Meal Routines List
                    ...filteredMeals.map((meal) {
                      return _MealRoutineItemCard(
                        meal: meal,
                        isDark: isDark,
                        onLog: () {
                          notifier.logMeal(meal);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Logged ${meal.name} (+${meal.calories} kcal)'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      );
                    }),
                    const SizedBox(height: 24),

                    // 5. Today's Logged Meals Summary
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Today\'s Intake (${nutrition.loggedMeals.length} logged)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${nutrition.totalCaloriesGained} kcal total',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.limeGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (nutrition.loggedMeals.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'No meals logged yet today. Choose from the routines above!',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.darkTextSecondary,
                            ),
                          ),
                        ),
                      )
                    else
                      ...nutrition.loggedMeals.map((meal) {
                        return _LoggedMealTile(
                          meal: meal,
                          isDark: isDark,
                          onDelete: () => notifier.removeLoggedMeal(meal.id),
                        );
                      }),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddCustomMealDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();
    final carbsCtrl = TextEditingController();
    final fatCtrl = TextEditingController();
    String mealType = 'lunch';
    String dietType = 'vegan';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            title: const Text('Create Custom Meal Routine'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Meal Name',
                      hintText: 'e.g., Post-Workout High Protein Oats',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: dietType,
                          decoration: const InputDecoration(labelText: 'Diet Type'),
                          items: const [
                            DropdownMenuItem(value: 'vegan', child: Text('🥗 Vegan')),
                            DropdownMenuItem(value: 'non_veg', child: Text('🥩 Non-Veg')),
                          ],
                          onChanged: (v) => setDlgState(() => dietType = v!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: mealType,
                          decoration: const InputDecoration(labelText: 'Meal Type'),
                          items: const [
                            DropdownMenuItem(value: 'breakfast', child: Text('Breakfast')),
                            DropdownMenuItem(value: 'lunch', child: Text('Lunch')),
                            DropdownMenuItem(value: 'dinner', child: Text('Dinner')),
                            DropdownMenuItem(value: 'snack', child: Text('Snack')),
                          ],
                          onChanged: (v) => setDlgState(() => mealType = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: calCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Calories (kcal)',
                      suffixText: 'kcal',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: proteinCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Protein',
                            suffixText: 'g',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: carbsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Carbs',
                            suffixText: 'g',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: fatCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Fat',
                            suffixText: 'g',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  final cal = int.tryParse(calCtrl.text) ?? 350;
                  final p = double.tryParse(proteinCtrl.text) ?? 25.0;
                  final c = double.tryParse(carbsCtrl.text) ?? 30.0;
                  final f = double.tryParse(fatCtrl.text) ?? 10.0;

                  final customMeal = MealItem(
                    id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    mealType: mealType,
                    dietType: dietType,
                    calories: cal,
                    proteinGrams: p,
                    carbsGrams: c,
                    fatGrams: f,
                    portion: 'Custom serving',
                    isCustom: true,
                    loggedAt: DateTime.now(),
                  );

                  ref.read(nutritionProvider.notifier).addCustomMeal(customMeal);
                  Navigator.pop(ctx);
                },
                child: const Text('Save & Log Meal'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CalorieBalanceCard extends StatelessWidget {
  final DailyNutritionState nutrition;
  final bool isDark;
  final VoidCallback onAddBurn;

  const _CalorieBalanceCard({
    required this.nutrition,
    required this.isDark,
    required this.onAddBurn,
  });

  @override
  Widget build(BuildContext context) {
    final gained = nutrition.totalCaloriesGained;
    final burned = nutrition.totalCaloriesBurned;
    final remaining = nutrition.remainingCalories;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Energy Balance Equations',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (remaining >= 0 ? AppColors.limeGreen : AppColors.warning)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  remaining >= 0 ? '$remaining kcal left' : '${remaining.abs()} kcal surplus',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: remaining >= 0 ? AppColors.limeGreen : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 3 Column Grid: Intake (Gain), Burned (Workouts), Target
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MetricCol(
                label: 'Calories Gained',
                value: '$gained',
                sub: 'Food intake',
                color: AppColors.limeGreen,
                icon: Icons.fastfood_rounded,
              ),
              Container(width: 1, height: 48, color: isDark ? Colors.white12 : Colors.black12),
              _MetricCol(
                label: 'Calories Burned',
                value: '$burned',
                sub: 'Active & workout',
                color: const Color(0xFFFF5252),
                icon: Icons.local_fire_department_rounded,
                onAdd: onAddBurn,
              ),
              Container(width: 1, height: 48, color: isDark ? Colors.white12 : Colors.black12),
              _MetricCol(
                label: 'Daily Target',
                value: '${nutrition.targetCalories}',
                sub: 'Goal budget',
                color: AppColors.electricCyan,
                icon: Icons.flag_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCol extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;
  final IconData icon;
  final VoidCallback? onAdd;

  const _MetricCol({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.icon,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              sub,
              style: const TextStyle(fontSize: 10, color: AppColors.darkTextSecondary),
            ),
            if (onAdd != null) ...[
              const SizedBox(width: 2),
              InkWell(
                onTap: onAdd,
                child: const Icon(Icons.add_circle_outline_rounded,
                    size: 13, color: Color(0xFFFF5252)),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _MacroSplitBar extends StatelessWidget {
  final DailyNutritionState nutrition;
  final bool isDark;

  const _MacroSplitBar({
    required this.nutrition,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final proteinP = (nutrition.totalProteinGained / nutrition.targetProtein).clamp(0.0, 1.0);
    final carbsP = (nutrition.totalCarbsGained / nutrition.targetCarbs).clamp(0.0, 1.0);
    final fatP = (nutrition.totalFatGained / nutrition.targetFat).clamp(0.0, 1.0);

    return Column(
      children: [
        _MacroRow(
          label: 'Protein',
          current: nutrition.totalProteinGained.toInt(),
          target: nutrition.targetProtein,
          progress: proteinP,
          color: AppColors.electricCyan,
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _MacroRow(
          label: 'Carbs',
          current: nutrition.totalCarbsGained.toInt(),
          target: nutrition.targetCarbs,
          progress: carbsP,
          color: const Color(0xFFF59E0B),
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _MacroRow(
          label: 'Fats',
          current: nutrition.totalFatGained.toInt(),
          target: nutrition.targetFat,
          progress: fatP,
          color: const Color(0xFFA855F7),
          isDark: isDark,
        ),
      ],
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final int current;
  final int target;
  final double progress;
  final Color color;
  final bool isDark;

  const _MacroRow({
    required this.label,
    required this.current,
    required this.target,
    required this.progress,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            Text('$current / ${target}g',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: isDark ? Colors.white12 : Colors.black12,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _GoalChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _GoalChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.limeGreen.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: isSelected
            ? AppColors.limeGreen
            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
      ),
    );
  }
}

class _DietFilterPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _DietFilterPill({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.limeGreen
                : (isDark ? AppColors.darkSurface : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.limeGreen
                  : (isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? Colors.black : null),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.black : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MealRoutineItemCard extends StatelessWidget {
  final MealItem meal;
  final bool isDark;
  final VoidCallback onLog;

  const _MealRoutineItemCard({
    required this.meal,
    required this.isDark,
    required this.onLog,
  });

  @override
  Widget build(BuildContext context) {
    final isVegan = meal.dietType == 'vegan';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isVegan ? AppColors.limeGreen : const Color(0xFFF59E0B))
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isVegan ? Icons.eco_rounded : Icons.restaurant_rounded,
                color: isVegan ? AppColors.limeGreen : const Color(0xFFF59E0B),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          meal.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isVegan ? Colors.green : Colors.deepOrange)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isVegan ? 'VEGAN' : 'NON-VEG',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isVegan ? Colors.green : Colors.deepOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${meal.calories} kcal • ${meal.proteinGrams.toInt()}g P • ${meal.carbsGrams.toInt()}g C • ${meal.fatGrams.toInt()}g F',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              icon: const Icon(Icons.add_rounded, size: 20),
              tooltip: 'Log Meal',
              onPressed: onLog,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoggedMealTile extends StatelessWidget {
  final MealItem meal;
  final bool isDark;
  final VoidCallback onDelete;

  const _LoggedMealTile({
    required this.meal,
    required this.isDark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  '${DateFormat('h:mm a').format(meal.loggedAt)} • ${meal.proteinGrams.toInt()}g Protein',
                  style: const TextStyle(fontSize: 11, color: AppColors.darkTextSecondary),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Text(
                '+${meal.calories} kcal',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.limeGreen),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
                color: Colors.redAccent,
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
