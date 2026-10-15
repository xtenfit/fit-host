import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_host/core/theme/app_colors.dart';
import 'package:fit_host/features/workouts/presentation/controllers/workout_providers.dart';
import 'package:fit_host/features/nutrition/presentation/controllers/nutrition_controller.dart';
import 'package:fit_host/features/nutrition/presentation/widgets/custom_meal_routine_sheet.dart';
import 'widgets/home_header.dart';
import 'widgets/home_streak_date_strip.dart';
import 'widgets/home_statistics_grid.dart';
import 'widgets/home_today_workout_hero.dart';
import 'widgets/home_diet_diary_card.dart';
import 'widgets/home_activity_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(workoutsStreamProvider);
            ref.invalidate(nutritionProvider);
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            children: [
              // 1. Top Header: Grid Menu, Greeting/Profile Name, Notification, Avatar
              HomeHeader(isDark: isDark),
              const SizedBox(height: 18),

              // 2. Streak & Weekly Mini Date Strip
              HomeStreakDateStrip(isDark: isDark),
              const SizedBox(height: 22),

              // 3. Statistics 2x2 Grid (Calories, Steps, Heart Beats, Workouts)
              HomeStatisticsGrid(isDark: isDark),
              const SizedBox(height: 24),

              // 4. Today's Workout Glassmorphic Hero Card
              HomeTodayWorkoutHero(isDark: isDark),
              const SizedBox(height: 24),

              // 5. My Diary / Calorie Balance & Meal Routine Card (Radial Gauge & Burrito)
              HomeDietDiaryCard(isDark: isDark),
              const SizedBox(height: 24),

              // 6. Your Activity / Realtime Analytics (Time Filters, Ring Timer, Walk & Sleep)
              HomeActivityCard(isDark: isDark),
              const SizedBox(height: 24),

              // 7. Workout Categories Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Workout Categories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/routines'),
                    child: const Text('All Routines'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 156,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _CategoryCard(
                      title: 'Strength',
                      subtitle: 'Build muscle',
                      imagePath: 'assets/images/workouts/strength.jpg',
                      icon: Icons.fitness_center_rounded,
                      color: AppColors.limeGreen,
                      onTap: () => context.push('/routines'),
                    ),
                    const SizedBox(width: 12),
                    _CategoryCard(
                      title: 'Bodyweight',
                      subtitle: 'No equipment',
                      imagePath: 'assets/images/workouts/bodyweight.jpg',
                      icon: Icons.accessibility_new_rounded,
                      color: AppColors.electricCyan,
                      onTap: () => context.push('/routines'),
                    ),
                    const SizedBox(width: 12),
                    _CategoryCard(
                      title: 'Gym Workout',
                      subtitle: 'Full body plans',
                      imagePath: 'assets/images/workouts/gym_workout.jpg',
                      icon: Icons.sports_gymnastics_rounded,
                      color: const Color(0xFFFFB300),
                      onTap: () => context.push('/routines'),
                    ),
                    const SizedBox(width: 12),
                    _CategoryCard(
                      title: 'Cardio',
                      subtitle: 'Burn fat & HIIT',
                      imagePath: 'assets/images/workouts/cardio.jpg',
                      icon: Icons.directions_run_rounded,
                      color: const Color(0xFFFF5252),
                      onTap: () => context.push('/routines'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.asset(
                  imagePath,
                  height: 85,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 85,
                    color: color.withValues(alpha: 0.2),
                    child: Center(
                      child: Icon(icon, color: color, size: 28),
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 12, color: color),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
