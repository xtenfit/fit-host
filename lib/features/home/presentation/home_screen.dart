import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fit_host/core/theme/app_colors.dart';
import 'package:fit_host/features/workouts/presentation/controllers/workout_providers.dart';
import 'package:fit_host/features/nutrition/presentation/controllers/nutrition_controller.dart';
import 'package:fit_host/features/nutrition/presentation/widgets/custom_meal_routine_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeState = ref.watch(activeWorkoutProvider);
    final workoutsAsync = ref.watch(workoutsStreamProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'Nutrient & Meal Menu',
            onPressed: () => CustomMealRoutineSheet.show(context),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.limeGreen.withValues(alpha: 0.35),
            ),
          ),
          child: Image.asset(
            'assets/images/fithost_logo_lockup.png',
            height: 26,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Text(
              'FIT HOST',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 0.8,
                color: Colors.white,
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Nutrient & Calorie Tracker',
            icon: const Icon(Icons.restaurant_menu_rounded, color: AppColors.limeGreen),
            onPressed: () => CustomMealRoutineSheet.show(context),
          ),
          IconButton(
            tooltip: 'Browse Exercises',
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push('/exercises'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(workoutsStreamProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Hero Start Workout Card with Cropped Photographic Banner
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? AppColors.limeGreen.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                    child: Image.asset(
                      'assets/images/workouts/strength_hero.jpg',
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ready to Train?',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            icon: Icon(
                              activeState.isActive ? Icons.play_arrow_rounded : Icons.add_rounded,
                              color: Colors.black,
                            ),
                            label: Text(
                              activeState.isActive ? 'Resume Active Workout' : 'Start Quick Workout',
                              style: const TextStyle(color: Colors.black, fontSize: 16),
                            ),
                            onPressed: () {
                              if (!activeState.isActive) {
                                ref.read(activeWorkoutProvider.notifier).startNewWorkout(
                                      title: 'Workout ${DateFormat('EEE, MMM d').format(DateTime.now())}',
                                    );
                              }
                              context.push('/active-workout');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Daily Calorie & Nutrient Tracking Balance Card (Gain vs Burn)
            _HomeNutritionBalanceCard(
              isDark: isDark,
              onTap: () => CustomMealRoutineSheet.show(context),
            ),
            const SizedBox(height: 16),

            // Quick Stats Row
            workoutsAsync.when(
              data: (workouts) {
                final completedWorkouts =
                    workouts.where((w) => w.status == 'completed').toList();
                final totalVolume = completedWorkouts.fold(
                    0.0, (sum, w) => sum + w.totalVolumeKg);
                final totalSets =
                    completedWorkouts.fold(0, (sum, w) => sum + w.completedSets);

                return Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Workouts',
                        value: '${completedWorkouts.length}',
                        subtitle: 'Completed',
                        icon: Icons.fitness_center_rounded,
                        color: AppColors.limeGreen,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Total Sets',
                        value: '$totalSets',
                        subtitle: 'Recorded',
                        icon: Icons.repeat_rounded,
                        color: AppColors.electricCyan,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Volume',
                        value: totalVolume > 1000
                            ? '${(totalVolume / 1000).toStringAsFixed(1)}t'
                            : '${totalVolume.toInt()}kg',
                        subtitle: 'Lifted',
                        icon: Icons.trending_up_rounded,
                        color: const Color(0xFFA855F7),
                        isDark: isDark,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // Workout Categories Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Workout Categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/workouts'),
                  child: const Text('All Routines'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 155,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _CategoryCard(
                    title: 'Strength',
                    subtitle: 'Build muscle',
                    imageAsset: 'assets/images/categories/strength.jpg',
                    isDark: isDark,
                    onTap: () => context.go('/workouts'),
                  ),
                  const SizedBox(width: 12),
                  _CategoryCard(
                    title: 'Bodyweight',
                    subtitle: 'No equipment',
                    imageAsset: 'assets/images/categories/bodyweight.jpg',
                    isDark: isDark,
                    onTap: () => context.go('/workouts'),
                  ),
                  const SizedBox(width: 12),
                  _CategoryCard(
                    title: 'Gym Workout',
                    subtitle: 'Full body plans',
                    imageAsset: 'assets/images/categories/gym_workout.jpg',
                    isDark: isDark,
                    onTap: () => context.go('/workouts'),
                  ),
                  const SizedBox(width: 12),
                  _CategoryCard(
                    title: 'Cardio',
                    subtitle: 'Burn calories',
                    imageAsset: 'assets/images/categories/cardio.jpg',
                    isDark: isDark,
                    onTap: () => context.go('/workouts'),
                  ),
                  const SizedBox(width: 12),
                  _CategoryCard(
                    title: 'Yoga',
                    subtitle: 'Flexibility & calm',
                    imageAsset: 'assets/images/categories/yoga.jpg',
                    isDark: isDark,
                    onTap: () => context.go('/workouts'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Recent Workouts header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/workouts'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Workouts List
            workoutsAsync.when(
              data: (workouts) {
                if (workouts.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(
                          Icons.fitness_center_outlined,
                          size: 48,
                          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No workouts logged yet',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Start your first session above and see your history here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: workouts.take(4).map((w) {
                    final dateStr = DateFormat('EEEE, MMM d • h:mm a').format(w.startedAt);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => context.push('/workout/${w.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      w.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: w.status == 'completed'
                                          ? AppColors.limeGreen.withValues(alpha: 0.15)
                                          : AppColors.warning.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      w.status == 'completed' ? 'COMPLETED' : 'IN PROGRESS',
                                      style: TextStyle(
                                        color: w.status == 'completed'
                                            ? (isDark ? AppColors.limeGreen : AppColors.limeGreenLight)
                                            : AppColors.warning,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateStr,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _InfoBadge(
                                    icon: Icons.timer_outlined,
                                    text: _formatDuration(w.durationSeconds),
                                    isDark: isDark,
                                  ),
                                  const SizedBox(width: 12),
                                  _InfoBadge(
                                    icon: Icons.format_list_bulleted_rounded,
                                    text: '${w.exercises.length} exercises',
                                    isDark: isDark,
                                  ),
                                  const SizedBox(width: 12),
                                  _InfoBadge(
                                    icon: Icons.fitness_center_rounded,
                                    text: '${w.totalVolumeKg.toInt()} kg',
                                    isDark: isDark,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error loading workouts: $err'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;

  const _InfoBadge({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageAsset;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 135,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              imageAsset,
              height: 90,
              width: 135,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 90,
                color: isDark ? Colors.white10 : Colors.black12,
                child: const Center(child: Icon(Icons.fitness_center_rounded)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeNutritionBalanceCard extends ConsumerWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _HomeNutritionBalanceCard({
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nutrition = ref.watch(nutritionProvider);
    final gained = nutrition.totalCaloriesGained;
    final burned = nutrition.totalCaloriesBurned;
    final remaining = nutrition.remainingCalories;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.limeGreen.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.restaurant_menu_rounded,
                        size: 16,
                        color: AppColors.limeGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Calories: Gain vs Burn',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Custom Meals',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.limeGreen : AppColors.limeGreenDark,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 11),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _QuickStat(
                  label: 'Calories Gained',
                  value: '$gained',
                  unit: 'kcal in',
                  color: AppColors.limeGreen,
                  icon: Icons.fastfood_rounded,
                  isDark: isDark,
                ),
                Container(
                  width: 1,
                  height: 38,
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
                _QuickStat(
                  label: 'Calories Burned',
                  value: '$burned',
                  unit: 'kcal out',
                  color: const Color(0xFFFF5252),
                  icon: Icons.local_fire_department_rounded,
                  isDark: isDark,
                ),
                Container(
                  width: 1,
                  height: 38,
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
                _QuickStat(
                  label: 'Remaining',
                  value: '$remaining',
                  unit: 'budget',
                  color: AppColors.electricCyan,
                  icon: Icons.track_changes_rounded,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '🥗 Vegan & 🥩 Non-Veg Meal Setup • Tap to Track & Log',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;
  final bool isDark;

  const _QuickStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
        Text(
          unit,
          style: TextStyle(
            fontSize: 9,
            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
          ),
        ),
      ],
    );
  }
}


