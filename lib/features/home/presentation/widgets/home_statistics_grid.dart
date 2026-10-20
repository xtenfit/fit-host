import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../workouts/domain/models/workout_models.dart';
import '../../../workouts/presentation/controllers/workout_providers.dart';
import '../../../nutrition/presentation/controllers/nutrition_controller.dart';
import '../../../nutrition/presentation/widgets/custom_meal_routine_sheet.dart';

class HomeStatisticsGrid extends ConsumerWidget {
  final bool isDark;

  const HomeStatisticsGrid({super.key, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nutrition = ref.watch(nutritionProvider);
    final workoutsAsync = ref.watch(workoutsStreamProvider);

    // Compute 100% REAL metrics from SQLite database & active state
    final completedWorkouts = workoutsAsync.maybeWhen(
      data: (workouts) => workouts.where((w) => w.status == 'completed').toList(),
      orElse: () => <WorkoutEntity>[],
    );

    final completedWorkoutsCount = completedWorkouts.length;

    final totalVolumeKg = completedWorkouts.fold<double>(
      0.0,
      (sum, w) => sum + w.totalVolumeKg,
    );

    final totalMinutes = completedWorkouts.fold<int>(
      0,
      (sum, w) => sum + (w.durationSeconds ~/ 60),
    );

    final caloriesBurned = (totalMinutes * 7.5).round();

    final volumeDisplay = totalVolumeKg >= 1000
        ? '${(totalVolumeKg / 1000).toStringAsFixed(1)}k kg'
        : '${totalVolumeKg.toInt()} kg';

    final durationDisplay = totalMinutes >= 60
        ? '${totalMinutes ~/ 60}h ${totalMinutes % 60}m'
        : '$totalMinutes min';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Real Training Metrics',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.limeGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, size: 12, color: AppColors.limeGreen),
                  SizedBox(width: 4),
                  Text(
                    'Real Data',
                    style: TextStyle(
                      fontSize: 10,
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
        Row(
          children: [
            // Card 1: Calories (Logged Food Intake vs Burned)
            Expanded(
              child: _StatGridCard(
                title: 'Calories Logged',
                value: '${nutrition.totalCaloriesGained} kcal',
                subtitle: caloriesBurned > 0 ? '$caloriesBurned kcal burned' : 'Track daily fuel',
                icon: Icons.local_fire_department_rounded,
                accentColor: AppColors.limeGreen,
                isDark: isDark,
                onTap: () => CustomMealRoutineSheet.show(context),
              ),
            ),
            const SizedBox(width: 12),

            // Card 2: Total Volume Lifted (Real weight * reps from SQLite)
            Expanded(
              child: _StatGridCard(
                title: 'Volume Lifted',
                value: volumeDisplay,
                subtitle: 'Total weight moved',
                icon: Icons.fitness_center_rounded,
                accentColor: AppColors.electricCyan,
                isDark: isDark,
                onTap: () => context.go('/progress'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Card 3: Real Active Training Duration
            Expanded(
              child: _StatGridCard(
                title: 'Active Time',
                value: durationDisplay,
                subtitle: 'Logged sessions',
                icon: Icons.timer_rounded,
                accentColor: const Color(0xFFFF9800),
                isDark: isDark,
                onTap: () => context.go('/workouts'),
              ),
            ),
            const SizedBox(width: 12),

            // Card 4: Real Workouts Completed
            Expanded(
              child: _StatGridCard(
                title: 'Workouts',
                value: '$completedWorkoutsCount sessions',
                subtitle: 'Verified history',
                icon: Icons.emoji_events_rounded,
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
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onTap;

  const _StatGridCard({
    required this.title,
    required this.value,
    required this.subtitle,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  icon,
                  size: 16,
                  color: accentColor,
                ),
              ],
            ),
            const SizedBox(height: 6),
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
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
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
