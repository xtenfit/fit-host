import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../nutrition/presentation/controllers/nutrition_controller.dart';
import '../../domain/models/day_summary.dart';

class DayDetailBottomSheet extends ConsumerWidget {
  final DaySummary daySummary;
  final VoidCallback? onAddEvent;

  const DayDetailBottomSheet({
    super.key,
    required this.daySummary,
    this.onAddEvent,
  });

  static Future<void> show(
    BuildContext context, {
    required DaySummary daySummary,
    VoidCallback? onAddEvent,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DayDetailBottomSheet(
        daySummary: daySummary,
        onAddEvent: onAddEvent,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(daySummary.date);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161A24) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (daySummary.hasWorkout)
                            _TagBadge(label: 'Workout Done', color: AppColors.electricBlue),
                          if (daySummary.hasMealLogged)
                            _TagBadge(label: 'Meals Tracked', color: const Color(0xFF22C55E)),
                          if (daySummary.isStepsGoalMet())
                            _TagBadge(label: 'Step Goal Met 🎯', color: const Color(0xFFF59E0B)),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Steps & Movement Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: CircularProgressIndicator(
                            value: (daySummary.steps / 10000.0).clamp(0.0, 1.0),
                            backgroundColor: isDark ? Colors.white12 : Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
                            strokeWidth: 5,
                          ),
                        ),
                        const Icon(Icons.directions_walk_rounded, color: Color(0xFF10B981), size: 24),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${daySummary.steps} Steps',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                daySummary.formattedDistance,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Target: 10,000 steps • ${((daySummary.steps / 10000) * 100).toInt()}% completed',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Workouts & Calories Card
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.fitness_center_rounded, size: 16, color: AppColors.electricBlue),
                              SizedBox(width: 6),
                              Text(
                                'Workout',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.electricBlue),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${daySummary.workoutCount} completed',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                          ),
                          Text(
                            '${daySummary.workoutDurationMin} mins active',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.local_fire_department_rounded, size: 16, color: Color(0xFFFF5252)),
                              SizedBox(width: 6),
                              Text(
                                'Calories Burned',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFF5252)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${daySummary.caloriesBurned} kcal',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                          ),
                          Text(
                            'Workouts + movement',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Nutrition & Hydration Card
              // Nutrition & Hydration Card (with Meal Type Breakdown & Editable Meals)
              Builder(
                builder: (context) {
                  final nutrition = ref.watch(nutritionProvider);
                  final dayMeals = nutrition.loggedMeals.where((m) {
                    return m.loggedAt.year == daySummary.date.year &&
                        m.loggedAt.month == daySummary.date.month &&
                        m.loggedAt.day == daySummary.date.day;
                  }).toList();

                  // Meal type subtotals
                  final breakfastCal = dayMeals
                      .where((m) => m.mealType.toLowerCase() == 'breakfast')
                      .fold<int>(0, (sum, m) => sum + m.calories);
                  final lunchCal = dayMeals
                      .where((m) => m.mealType.toLowerCase() == 'lunch')
                      .fold<int>(0, (sum, m) => sum + m.calories);
                  final dinnerCal = dayMeals
                      .where((m) => m.mealType.toLowerCase() == 'dinner')
                      .fold<int>(0, (sum, m) => sum + m.calories);
                  final snackCal = dayMeals
                      .where((m) => m.mealType.toLowerCase().contains('snack'))
                      .fold<int>(0, (sum, m) => sum + m.calories);

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
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
                            const Text(
                              'Nutrition & Water Logged',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                            Text(
                              '${daySummary.caloriesIn} kcal In',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: Color(0xFF22C55E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Calories In vs Out Balance
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF141923) : Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'In: ${daySummary.caloriesIn} kcal  •  Out: ${daySummary.caloriesBurned} kcal',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              Text(
                                'Net: ${daySummary.netCalories > 0 ? '+' : ''}${daySummary.netCalories} kcal',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: daySummary.netCalories <= 0 ? const Color(0xFF22C55E) : const Color(0xFFFF9500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _MacroItem(label: 'Protein', value: '${daySummary.proteinG}g', color: const Color(0xFF3B82F6)),
                            _MacroItem(label: 'Carbs', value: '${daySummary.carbsG}g', color: const Color(0xFFF59E0B)),
                            _MacroItem(label: 'Fats', value: '${daySummary.fatsG}g', color: const Color(0xFFEC4899)),
                            _MacroItem(label: 'Water', value: '${daySummary.waterMl}ml', color: const Color(0xFF06B6D4)),
                          ],
                        ),

                        // Meal Type Breakdown Chips
                        if (dayMeals.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          const Text(
                            'MEAL BREAKDOWN',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (breakfastCal > 0)
                                _MealTypeChip(label: '🌅 Breakfast', calories: breakfastCal),
                              if (lunchCal > 0)
                                _MealTypeChip(label: '☀️ Lunch', calories: lunchCal),
                              if (dinnerCal > 0)
                                _MealTypeChip(label: '🌙 Dinner', calories: dinnerCal),
                              if (snackCal > 0)
                                _MealTypeChip(label: '🍎 Snacks', calories: snackCal),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Logged Meals with Edit Action
                          ...dayMeals.map((meal) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          meal.name,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                        ),
                                        Text(
                                          '${meal.portion} • P: ${meal.proteinGrams.toStringAsFixed(1)}g • ${meal.calories} kcal',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 16),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      context.push('/nutrition/diary');
                                    },
                                    tooltip: 'Edit in Diary',
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Quick Actions Row (Editable)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/workouts');
                      },
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Workout'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.electricBlue,
                        side: const BorderSide(color: AppColors.electricBlue),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/nutrition');
                      },
                      icon: const Icon(Icons.restaurant_rounded, size: 16),
                      label: const Text('Meal'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF22C55E),
                        side: const BorderSide(color: Color(0xFF22C55E)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref.read(nutritionProvider.notifier).incrementWater();
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.water_drop_rounded, size: 16),
                      label: const Text('+Water'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF06B6D4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _TagBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _MacroItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}

class _MealTypeChip extends StatelessWidget {
  final String label;
  final int calories;

  const _MealTypeChip({required this.label, required this.calories});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.limeGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.limeGreen.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $calories kcal',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.limeGreen,
        ),
      ),
    );
  }
}
