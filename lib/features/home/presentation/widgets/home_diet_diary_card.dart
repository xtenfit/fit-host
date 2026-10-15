import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../nutrition/presentation/controllers/nutrition_controller.dart';
import '../../../nutrition/presentation/widgets/custom_meal_routine_sheet.dart';
import '../controllers/home_dashboard_controller.dart';

class HomeDietDiaryCard extends ConsumerWidget {
  final bool isDark;

  const HomeDietDiaryCard({super.key, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nutrition = ref.watch(nutritionProvider);
    final dashboard = ref.watch(homeDashboardProvider);

    final eatenKcal = nutrition.totalCaloriesGained > 0
        ? nutrition.totalCaloriesGained
        : 2200;
    final burnedKcal = nutrition.totalCaloriesBurned > 0
        ? nutrition.totalCaloriesBurned
        : 220;
    final leftKcal = nutrition.remainingCalories > 0
        ? nutrition.remainingCalories
        : 1980;

    // Macro remaining amounts
    final carbsLeft = (nutrition.targetCarbs - nutrition.totalCarbs).clamp(0, 999).toInt();
    final proteinLeft = (nutrition.targetProtein - nutrition.totalProtein).clamp(0, 999).toInt();
    final fatsLeft = (nutrition.targetFats - nutrition.totalFats).clamp(0, 999).toInt();

    // Macro progress ratios
    final carbsProgress = (nutrition.totalCarbs / (nutrition.targetCarbs > 0 ? nutrition.targetCarbs : 1)).clamp(0.0, 1.0);
    final proteinProgress = (nutrition.totalProtein / (nutrition.targetProtein > 0 ? nutrition.targetProtein : 1)).clamp(0.0, 1.0);
    final fatsProgress = (nutrition.totalFats / (nutrition.targetFats > 0 ? nutrition.targetFats : 1)).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  Text(
                    dashboard.activeDietRoutine,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
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
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 13)),
                            const SizedBox(width: 5),
                            Text(
                              '$eatenKcal Kcal',
                              style: TextStyle(
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
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 13)),
                            const SizedBox(width: 5),
                            Text(
                              '$burnedKcal Kcal',
                              style: TextStyle(
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
                      width: 104,
                      height: 104,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(104, 104),
                            painter: _CalorieRadialGaugePainter(
                              progress: (leftKcal / (nutrition.targetCalories > 0 ? nutrition.targetCalories : 2500)).clamp(0.0, 1.0),
                              isDark: isDark,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$leftKcal',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFFFF6B4A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                'Kcal left',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
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
              Row(
                children: [
                  Expanded(
                    child: _MacroProgressItem(
                      label: 'Carbs',
                      leftAmount: '${carbsLeft > 0 ? carbsLeft : 24}g left',
                      progress: carbsProgress > 0 ? carbsProgress : 0.65,
                      color: AppColors.limeGreen,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _MacroProgressItem(
                      label: 'Protein',
                      leftAmount: '${proteinLeft > 0 ? proteinLeft : 30}g left',
                      progress: proteinProgress > 0 ? proteinProgress : 0.78,
                      color: AppColors.electricCyan,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _MacroProgressItem(
                      label: 'Fats',
                      leftAmount: '${fatsLeft > 0 ? fatsLeft : 50}g left',
                      progress: fatsProgress > 0 ? fatsProgress : 0.45,
                      color: const Color(0xFFFF6B4A),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Meal Item Card (✓ Breakfast - 544 Kcal with Vegan Burrito)
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breakfast Row Header
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
                        'Breakfast',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '544 Kcal',
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
                      'Customize',
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

              // Meal Content Row
              Row(
                children: [
                  // Food Photo Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/images/nutrition/vegan_burrito.jpg',
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 72,
                        height: 72,
                        color: AppColors.darkSurfaceBorder,
                        child: const Icon(Icons.restaurant_rounded, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Meal Details & Macro Pills
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vegan Burrito',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '1 Plate Serve | 480 Kcal',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Micro nutrient tags: C 78g, Fi 32g, P 14g, FA 8g
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _MacroPillTag(label: 'C 78g', isDark: isDark),
                            _MacroPillTag(label: 'Fi 32g', isDark: isDark),
                            _MacroPillTag(label: 'P 14g', isDark: isDark),
                            _MacroPillTag(label: 'FA 8g', isDark: isDark),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
