import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/nutrition_models.dart';
import '../controllers/nutrition_controller.dart';
import 'add_meal_screen.dart';
import 'quantity_entry_screen.dart';

class NutritionDiaryScreen extends ConsumerStatefulWidget {
  const NutritionDiaryScreen({super.key});

  @override
  ConsumerState<NutritionDiaryScreen> createState() => _NutritionDiaryScreenState();
}

class _NutritionDiaryScreenState extends ConsumerState<NutritionDiaryScreen> {
  DateTime _selectedDate = DateTime.now();

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
  }

  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nutrition = ref.watch(nutritionProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isToday = _isSameDay(_selectedDate, DateTime.now());

    // Filter meals for the selected date
    final dayMeals = nutrition.loggedMeals.where((m) => _isSameDay(m.loggedAt, _selectedDate)).toList();

    // Group meals by meal type
    final breakfastMeals = dayMeals.where((m) => m.mealType.toLowerCase() == 'breakfast').toList();
    final lunchMeals = dayMeals.where((m) => m.mealType.toLowerCase() == 'lunch').toList();
    final dinnerMeals = dayMeals.where((m) => m.mealType.toLowerCase() == 'dinner').toList();
    final snackMeals = dayMeals.where((m) => m.mealType.toLowerCase() == 'snack' || m.mealType.toLowerCase() == 'snacks').toList();
    final customMeals = dayMeals.where((m) =>
        m.mealType.toLowerCase() != 'breakfast' &&
        m.mealType.toLowerCase() != 'lunch' &&
        m.mealType.toLowerCase() != 'dinner' &&
        m.mealType.toLowerCase() != 'snack' &&
        m.mealType.toLowerCase() != 'snacks').toList();

    // Calculate totals for today
    final totalCalories = dayMeals.fold<int>(0, (sum, m) => sum + m.calories);
    final totalProtein = dayMeals.fold<double>(0, (sum, m) => sum + m.proteinGrams);
    final totalCarbs = dayMeals.fold<double>(0, (sum, m) => sum + m.carbsGrams);
    final totalFat = dayMeals.fold<double>(0, (sum, m) => sum + m.fatGrams);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Diary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Select Date',
            onPressed: _pickDate,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // Date navigation header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: _previousDay,
                  tooltip: 'Previous Day',
                ),
                GestureDetector(
                  onTap: _pickDate,
                  child: Row(
                    children: [
                      Icon(
                        Icons.today_rounded,
                        size: 18,
                        color: isToday ? AppColors.limeGreen : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isToday ? 'Today, ${DateFormat('MMM d').format(_selectedDate)}' : DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isToday ? AppColors.limeGreen : (isDark ? Colors.white : Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: isToday ? null : _nextDay,
                  tooltip: 'Next Day',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Today's Total Summary Card
          _buildSummaryCard(
            context: context,
            isDark: isDark,
            totalCalories: totalCalories,
            targetCalories: nutrition.targetCalories,
            totalProtein: totalProtein,
            targetProtein: nutrition.targetProtein,
            totalCarbs: totalCarbs,
            targetCarbs: nutrition.targetCarbs,
            totalFat: totalFat,
            targetFat: nutrition.targetFat,
            mealsCount: dayMeals.length,
          ),
          const SizedBox(height: 20),

          // Meal Sections
          _buildMealSection(
            context: context,
            title: 'Breakfast',
            emoji: '🌅',
            meals: breakfastMeals,
            isDark: isDark,
            mealType: MealType.breakfast,
          ),
          const SizedBox(height: 14),

          _buildMealSection(
            context: context,
            title: 'Lunch',
            emoji: '☀️',
            meals: lunchMeals,
            isDark: isDark,
            mealType: MealType.lunch,
          ),
          const SizedBox(height: 14),

          _buildMealSection(
            context: context,
            title: 'Dinner',
            emoji: '🌙',
            meals: dinnerMeals,
            isDark: isDark,
            mealType: MealType.dinner,
          ),
          const SizedBox(height: 14),

          _buildMealSection(
            context: context,
            title: 'Snacks',
            emoji: '🍎',
            meals: snackMeals,
            isDark: isDark,
            mealType: MealType.snack,
          ),
          const SizedBox(height: 14),

          if (customMeals.isNotEmpty)
            _buildMealSection(
              context: context,
              title: 'Custom Meals',
              emoji: '🍽️',
              meals: customMeals,
              isDark: isDark,
              mealType: MealType.custom,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.limeGreen,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Meal', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AddMealScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required bool isDark,
    required int totalCalories,
    required int targetCalories,
    required double totalProtein,
    required int targetProtein,
    required double totalCarbs,
    required int targetCarbs,
    required double totalFat,
    required int targetFat,
    required int mealsCount,
  }) {
    final calProgress = (totalCalories / (targetCalories > 0 ? targetCalories : 2000)).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DAILY TOTALS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: AppColors.limeGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$totalCalories',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        ' / $targetCalories kcal',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.limeGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.restaurant_rounded, size: 14, color: AppColors.limeGreen),
                    const SizedBox(width: 4),
                    Text(
                      '$mealsCount meals logged',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.limeGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Calorie progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: calProgress,
              minHeight: 8,
              backgroundColor: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
              valueColor: const AlwaysStoppedAnimation(AppColors.limeGreen),
            ),
          ),
          const SizedBox(height: 16),

          // Macro breakdown rows
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroStat(
                label: 'Protein',
                current: totalProtein,
                target: targetProtein,
                unit: 'g',
                color: AppColors.limeGreen,
                isDark: isDark,
              ),
              _buildMacroStat(
                label: 'Carbs',
                current: totalCarbs,
                target: targetCarbs,
                unit: 'g',
                color: AppColors.electricCyan,
                isDark: isDark,
              ),
              _buildMacroStat(
                label: 'Fats',
                current: totalFat,
                target: targetFat,
                unit: 'g',
                color: const Color(0xFFFFB300),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroStat({
    required String label,
    required double current,
    required int target,
    required String unit,
    required Color color,
    required bool isDark,
  }) {
    final progress = (current / (target > 0 ? target : 100)).clamp(0.0, 1.0);

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${current.round()}$unit',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          '/ $target$unit',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 50,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealSection({
    required BuildContext context,
    required String title,
    required String emoji,
    required List<MealItem> meals,
    required bool isDark,
    required MealType mealType,
  }) {
    final sectionCalories = meals.fold<int>(0, (sum, m) => sum + m.calories);
    final sectionProtein = meals.fold<double>(0, (sum, m) => sum + m.proteinGrams);
    final sectionCarbs = meals.fold<double>(0, (sum, m) => sum + m.carbsGrams);
    final sectionFat = meals.fold<double>(0, (sum, m) => sum + m.fatGrams);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  '$sectionCalories kcal',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.limeGreen,
                  ),
                ),
              ],
            ),
          ),

          // Macro Subtotal pills
          if (meals.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'P: ${sectionProtein.toStringAsFixed(1)}g  •  C: ${sectionCarbs.toStringAsFixed(1)}g  •  F: ${sectionFat.toStringAsFixed(1)}g',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
              ),
            ),

          const SizedBox(height: 6),
          const Divider(height: 1),

          // Items List
          if (meals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Center(
                child: Text(
                  'No meals logged for $title yet',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: meals.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final meal = meals[index];
                return Dismissible(
                  key: Key(meal.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: AppColors.error,
                    child: const Icon(Icons.delete_forever_rounded, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    // Remove from provider
                    ref.read(nutritionProvider.notifier).removeLoggedMeal(meal.id);

                    // Show undo snackbar
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Removed "${meal.name}"'),
                        duration: const Duration(seconds: 5),
                        action: SnackBarAction(
                          label: 'Undo',
                          textColor: AppColors.limeGreen,
                          onPressed: () {
                            ref.read(nutritionProvider.notifier).logMeal(meal);
                          },
                        ),
                      ),
                    );
                  },
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text(
                      meal.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      '${meal.portion} • P: ${meal.proteinGrams.toStringAsFixed(1)}g • C: ${meal.carbsGrams.toStringAsFixed(1)}g • F: ${meal.fatGrams.toStringAsFixed(1)}g',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${meal.calories} kcal',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          onPressed: () async {
                            // Extract grams from portion if present
                            double parsedGrams = 100.0;
                            final match = RegExp(r'(\d+(\.\d+)?)g').firstMatch(meal.portion);
                            if (match != null) {
                              parsedGrams = double.tryParse(match.group(1)!) ?? 100.0;
                            }

                            final entry = MealEntry(
                              id: meal.id,
                              foodName: meal.name,
                              quantityGrams: parsedGrams,
                              mealType: mealType,
                              consumedAt: meal.loggedAt,
                              proteinPer100g: parsedGrams > 0 ? (meal.proteinGrams * 100) / parsedGrams : meal.proteinGrams,
                              carbsPer100g: parsedGrams > 0 ? (meal.carbsGrams * 100) / parsedGrams : meal.carbsGrams,
                              fatsPer100g: parsedGrams > 0 ? (meal.fatGrams * 100) / parsedGrams : meal.fatGrams,
                              caloriesPer100g: parsedGrams > 0 ? (meal.calories * 100) / parsedGrams : meal.calories.toDouble(),
                            );

                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => QuantityEntryScreen(existingEntry: entry),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
