import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../workouts/presentation/controllers/workout_providers.dart';
import '../../../nutrition/presentation/controllers/nutrition_controller.dart';
import '../../../nutrition/presentation/widgets/custom_meal_routine_sheet.dart';
import '../controllers/home_dashboard_controller.dart';

class HomeStatisticsGrid extends ConsumerWidget {
  final bool isDark;

  const HomeStatisticsGrid({super.key, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(homeDashboardProvider);
    final notifier = ref.read(homeDashboardProvider.notifier);
    final nutrition = ref.watch(nutritionProvider);
    final workoutsAsync = ref.watch(workoutsStreamProvider);

    final completedWorkoutsCount = workoutsAsync.maybeWhen(
      data: (workouts) => workouts.where((w) => w.status == 'completed').length,
      orElse: () => 14,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Card 1: Calories
            Expanded(
              child: _StatGridCard(
                title: 'Calories',
                value: '${nutrition.totalCaloriesGained > 0 ? nutrition.totalCaloriesGained : 1200} Kcal',
                icon: Icons.local_fire_department_rounded,
                accentColor: AppColors.limeGreen,
                isDark: isDark,
                onTap: () => CustomMealRoutineSheet.show(context),
              ),
            ),
            const SizedBox(width: 12),

            // Card 2: Steps
            Expanded(
              child: _StatGridCard(
                title: 'Steps',
                value: '${dashboard.stepsCount} Steps',
                icon: Icons.directions_walk_rounded,
                accentColor: AppColors.electricCyan,
                isDark: isDark,
                onTap: () {
                  notifier.addSteps(250);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🚶 Logged +250 active steps in real-time!'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Card 3: Heart Beats
            Expanded(
              child: _StatGridCard(
                title: 'Heart Beats',
                value: '${dashboard.heartRateBpm} bpm',
                icon: Icons.favorite_rounded,
                accentColor: const Color(0xFFFF5252),
                isDark: isDark,
                onTap: () {
                  notifier.pulseHeartRate();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❤️ Resting Heart Rate calibrated: ${dashboard.heartRateBpm} bpm'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),

            // Card 4: Workouts
            Expanded(
              child: _StatGridCard(
                title: 'Workouts',
                value: '$completedWorkoutsCount / 20',
                icon: Icons.fitness_center_rounded,
                accentColor: const Color(0xFFA855F7),
                isDark: isDark,
                onTap: () => context.go('/workouts'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatGridCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onTap;

  const _StatGridCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
              blurRadius: 10,
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
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                Icon(
                  icon,
                  size: 16,
                  color: accentColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
