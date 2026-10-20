import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../nutrition/presentation/controllers/nutrition_controller.dart';
import '../../../nutrition/presentation/widgets/custom_meal_routine_sheet.dart';
import '../../../nutrition/presentation/screens/quantity_entry_screen.dart';
import '../../../nutrition/domain/models/nutrition_models.dart';
import '../../../workouts/domain/models/workout_models.dart';
import '../../../workouts/presentation/controllers/workout_providers.dart';
import '../../../profile/presentation/controllers/user_profile_controller.dart';

class HomeDietDiaryCard extends ConsumerWidget {
  final bool isDark;

  const HomeDietDiaryCard({super.key, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nutrition = ref.watch(nutritionProvider);
    final profile = ref.watch(userProfileProvider);
    final workoutsAsync = ref.watch(workoutsStreamProvider);

    // Compute REAL calories burned today from SQLite completed workouts
    final completedWorkoutsToday = workoutsAsync.maybeWhen(
      data: (workouts) => workouts.where((w) {
        if (w.status != 'completed') return false;
        if (w.completedAt == null) return false;
        final now = DateTime.now();
        return w.completedAt!.year == now.year &&
            w.completedAt!.month == now.month &&
            w.completedAt!.day == now.day;
      }).toList(),
      orElse: () => <WorkoutEntity>[],
    );
    final todayWorkoutMinutes = completedWorkoutsToday.fold<int>(
      0,
      (sum, w) => sum + (w.durationSeconds ~/ 60),
    );
    final workoutBurned = (todayWorkoutMinutes * 7.5).round();
    final burnedKcal = workoutBurned + nutrition.manualCaloriesBurned;

    final eatenKcal = nutrition.totalCaloriesGained;
    final targetKcal = profile.dailyCaloriesTarget > 0 ? profile.dailyCaloriesTarget : 2250;
    final leftKcal = (targetKcal - eatenKcal + burnedKcal).clamp(0, 9999);

    // Real macro remaining amounts based on User Profile Targets
    final targetCarbs = profile.targetCarbsGrams > 0 ? profile.targetCarbsGrams : 250;
    final targetProtein = profile.targetProteinGrams > 0 ? profile.targetProteinGrams : 145;
    final targetFats = profile.targetFatsGrams > 0 ? profile.targetFatsGrams : 60;

    final carbsLeft = (targetCarbs - nutrition.totalCarbs).clamp(0, 999).toInt();
    final proteinLeft = (targetProtein - nutrition.totalProtein).clamp(0, 999).toInt();
    final fatsLeft = (targetFats - nutrition.totalFats).clamp(0, 999).toInt();

    // Macro progress ratios
    final carbsProgress = (nutrition.totalCarbs / targetCarbs).clamp(0.0, 1.0);
    final proteinProgress = (nutrition.totalProtein / targetProtein).clamp(0.0, 1.0);
    final fatsProgress = (nutrition.totalFats / targetFats).clamp(0.0, 1.0);

    // Task 12: Quick-Add Shortcuts (logged 3+ times in last 14 days)
    final fourteenDaysAgo = DateTime.now().subtract(const Duration(days: 14));
    final recentLogged = nutrition.loggedMeals.where((m) => m.loggedAt.isAfter(fourteenDaysAgo)).toList();
    final itemOccurrences = <String, List<MealItem>>{};
    for (final item in recentLogged) {
      itemOccurrences.putIfAbsent(item.name, () => []).add(item);
    }
    final quickAddItems = itemOccurrences.entries
        .where((entry) => entry.value.length >= 3)
        .map((entry) => entry.value.last)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (quickAddItems.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, size: 16, color: AppColors.limeGreen),
                const SizedBox(width: 4),
                Text(
                  'QUICK ADD',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: quickAddItems.map((quickMeal) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                    side: BorderSide(color: AppColors.limeGreen.withValues(alpha: 0.4)),
                    avatar: const Icon(Icons.flash_on_rounded, size: 14, color: AppColors.limeGreen),
                    label: Text(
                      '${quickMeal.name} (${quickMeal.portion})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () {
                      double grams = 100.0;
                      final match = RegExp(r'(\d+(\.\d+)?)g').firstMatch(quickMeal.portion);
                      if (match != null) {
                        grams = double.tryParse(match.group(1)!) ?? 100.0;
                      }
                      final entry = MealEntry(
                        id: const Uuid().v4(),
                        foodName: quickMeal.name,
                        quantityGrams: grams,
                        mealType: MealType.fromString(quickMeal.mealType),
                        consumedAt: DateTime.now(),
                        proteinPer100g: grams > 0 ? (quickMeal.proteinGrams * 100) / grams : quickMeal.proteinGrams,
                        carbsPer100g: grams > 0 ? (quickMeal.carbsGrams * 100) / grams : quickMeal.carbsGrams,
                        fatsPer100g: grams > 0 ? (quickMeal.fatGrams * 100) / grams : quickMeal.fatGrams,
                        caloriesPer100g: grams > 0 ? (quickMeal.calories * 100) / grams : quickMeal.calories.toDouble(),
                      );
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => QuantityEntryScreen(existingEntry: entry),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        // Main Diet Diary Container
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Diet Title & Details Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      profile.dietTypeTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => CustomMealRoutineSheet.show(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.limeGreen : AppColors.limeGreenDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Energy Balance: Eaten & Burned + Radial Calorie Left Gauge
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left side: Eaten & Burned
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Eaten',
                          style: TextStyle(
                            fontFamily: 'Arial',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              size: 16,
                              color: AppColors.limeGreen,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '$eatenKcal Kcal',
                              style: TextStyle(
                                fontFamily: 'Arial',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Burned',
                          style: TextStyle(
                            fontFamily: 'Arial',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              size: 16,
                              color: Color(0xFFFF5252),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '$burnedKcal Kcal',
                              style: TextStyle(
                                fontFamily: 'Arial',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFFF5252),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Right side: Circular Radial Gauge
                  GestureDetector(
                    onTap: () => CustomMealRoutineSheet.show(context),
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(100, 100),
                            painter: _CalorieRadialGaugePainter(
                              progress: (leftKcal / (targetKcal > 0 ? targetKcal : 2250)).clamp(0.0, 1.0),
                              isDark: isDark,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$leftKcal',
                                style: const TextStyle(
                                  fontFamily: 'Arial',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFFF6B4A),
                                  letterSpacing: -0.5,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                'Kcal left',
                                style: TextStyle(
                                  fontFamily: 'Arial',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  height: 1.1,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Macro Progress Rows: Carbs, Protein, Fats
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _MacroProgressItem(
                        label: 'Carbs',
                        leftAmount: '${carbsLeft}g left',
                        progress: carbsProgress,
                        color: AppColors.limeGreen,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MacroProgressItem(
                        label: 'Protein',
                        leftAmount: '${proteinLeft}g left',
                        progress: proteinProgress,
                        color: AppColors.electricCyan,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MacroProgressItem(
                        label: 'Fats',
                        leftAmount: '${fatsLeft}g left',
                        progress: fatsProgress,
                        color: const Color(0xFFFF6B4A),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Live Logged Meal or Clean Empty State
        if (nutrition.loggedMeals.isNotEmpty) ...[
          Builder(
            builder: (context) {
              final latestMeal = nutrition.loggedMeals.last;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: AppColors.limeGreen,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 11,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              latestMeal.mealType.toUpperCase(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${latestMeal.calories} Kcal',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => CustomMealRoutineSheet.show(context),
                          borderRadius: BorderRadius.circular(6),
                          child: Text(
                            '+ Add Another',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.limeGreen : AppColors.limeGreenDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 60,
                            height: 60,
                            color: AppColors.limeGreen.withValues(alpha: 0.15),
                            child: const Icon(Icons.restaurant_rounded, color: AppColors.limeGreen, size: 28),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                latestMeal.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${latestMeal.calories} Kcal • Logged Today',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  _MacroPillTag(label: 'P ${latestMeal.proteinGrams.toInt()}g', isDark: isDark),
                                  _MacroPillTag(label: 'C ${latestMeal.carbsGrams.toInt()}g', isDark: isDark),
                                  _MacroPillTag(label: 'F ${latestMeal.fatGrams.toInt()}g', isDark: isDark),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.limeGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.restaurant_menu_rounded, color: AppColors.limeGreen, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No Meals Logged Yet',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap to log breakfast, lunch or snacks',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => context.push('/nutrition/add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.limeGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Log Meal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MacroProgressItem extends StatelessWidget {
  final String label;
  final String leftAmount;
  final double progress;
  final Color color;
  final bool isDark;

  const _MacroProgressItem({
    required this.label,
    required this.leftAmount,
    required this.progress,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          leftAmount,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}

class _MacroPillTag extends StatelessWidget {
  final String label;
  final bool isDark;

  const _MacroPillTag({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
      ),
    );
  }
}

class _CalorieRadialGaugePainter extends CustomPainter {
  final double progress;
  final bool isDark;

  const _CalorieRadialGaugePainter({
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background Arc
    final bgPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Dynamic Gradient Progress Arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
      colors: const [
        Color(0xFFFF6B4A),
        Color(0xFFFF5252),
        AppColors.limeGreen,
      ],
      stops: const [0.0, 0.6, 1.0],
      transform: const GradientRotation(-math.pi / 2),
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _CalorieRadialGaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
