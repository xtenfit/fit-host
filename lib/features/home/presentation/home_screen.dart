import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_host/core/theme/app_colors.dart';
import 'package:fit_host/core/theme/app_motion.dart';
import 'package:fit_host/features/workouts/presentation/controllers/workout_providers.dart';
import 'package:fit_host/features/nutrition/presentation/controllers/nutrition_controller.dart';
import 'widgets/home_header.dart';
import 'widgets/home_streak_date_strip.dart';
import 'widgets/home_statistics_grid.dart';
import 'widgets/home_today_workout_hero.dart';
import 'widgets/home_step_card.dart';
import 'widgets/home_diet_diary_card.dart';
import 'widgets/home_activity_card.dart';
import 'widgets/guest_upgrade_banner.dart';

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
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 140),
            children: [
              // 1. Top Header: Grid Menu, Greeting/Profile Name, Notification, Avatar
              HomeHeader(isDark: isDark),
              const SizedBox(height: 14),

              // 1b. Non-blocking Guest -> Account Upgrade Banner
              GuestUpgradeBanner(isDark: isDark),

              // 2. Today's Workout Glassmorphic Hero Carousel
              HomeTodayWorkoutHero(isDark: isDark),
              const SizedBox(height: 24),

              // 3. Real Training Metrics (Streak Date Strip + Statistics Grid)
              HomeStreakDateStrip(isDark: isDark),
              const SizedBox(height: 20),
              HomeStatisticsGrid(isDark: isDark),
              const SizedBox(height: 24),

              // 4. Daily Steps & Distance Tracker Card
              HomeStepCard(isDark: isDark),
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
                  const Expanded(
                    child: Text(
                      'Workout Categories',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
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
                height: 200,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  children: [
                    _CategoryCard(
                      title: 'Strength',
                      subtitle: 'Build muscle',
                      imagePath: 'assets/images/categories/strength.png',
                      icon: Icons.fitness_center_rounded,
                      color: AppColors.electricBlue,
                      onTap: () => context.push('/workout-category/Strength'),
                    ),
                    const SizedBox(width: 12),
                    _CategoryCard(
                      title: 'Cardio',
                      subtitle: 'Burn fat & stamina',
                      imagePath: 'assets/images/categories/cardio.png',
                      icon: Icons.directions_run_rounded,
                      color: const Color(0xFFFF5252),
                      onTap: () => context.push('/workout-category/Cardio'),
                    ),
                    const SizedBox(width: 12),
                    _CategoryCard(
                      title: 'HIIT',
                      subtitle: 'High intensity burn',
                      imagePath: 'assets/images/categories/hiit.png',
                      icon: Icons.local_fire_department_rounded,
                      color: const Color(0xFFFF6D00),
                      onTap: () => context.push('/workout-category/HIIT'),
                    ),
                    const SizedBox(width: 12),
                    _CategoryCard(
                      title: 'Bodyweight',
                      subtitle: 'No equipment needed',
                      imagePath: 'assets/images/categories/bodyweight.png',
                      icon: Icons.accessibility_new_rounded,
                      color: AppColors.electricCyan,
                      onTap: () => context.push('/workout-category/Bodyweight'),
                    ),
                    const SizedBox(width: 12),
                    _CategoryCard(
                      title: 'Yoga',
                      subtitle: 'Mind & flexibility',
                      imagePath: 'assets/images/categories/yoga.png',
                      icon: Icons.spa_rounded,
                      color: const Color(0xFF00E676),
                      onTap: () => context.push('/workout-category/Yoga'),
                    ),
                    const SizedBox(width: 12),
                    _CategoryCard(
                      title: 'Running',
                      subtitle: 'Road & sprint pace',
                      imagePath: 'assets/images/categories/running.png',
                      icon: Icons.speed_rounded,
                      color: const Color(0xFF00B0FF),
                      onTap: () => context.push('/workout-category/Running'),
                    ),
                    const SizedBox(width: 12),
                    _CategoryCard(
                      title: 'Cycling',
                      subtitle: 'Speed & endurance',
                      imagePath: 'assets/images/categories/cycling.png',
                      icon: Icons.pedal_bike_rounded,
                      color: const Color(0xFF76FF03),
                      onTap: () => context.push('/workout-category/Cycling'),
                    ),
                    const SizedBox(width: 12),
                    _CategoryCard(
                      title: 'Mobility',
                      subtitle: 'Joint health & range',
                      imagePath: 'assets/images/categories/mobility.png',
                      icon: Icons.airline_seat_legroom_extra_rounded,
                      color: const Color(0xFFE040FB),
                      onTap: () => context.push('/workout-category/Mobility'),
                    ),
                    const SizedBox(width: 12),
                    _CategoryCard(
                      title: 'Stretching',
                      subtitle: 'Recovery & length',
                      imagePath: 'assets/images/categories/stretching.png',
                      icon: Icons.self_improvement_rounded,
                      color: const Color(0xFF1DE9B6),
                      onTap: () => context.push('/workout-category/Mobility'),
                    ),
                    const SizedBox(width: 12),
                    _CategoryCard(
                      title: 'Meditation',
                      subtitle: 'Focus & breathwork',
                      imagePath: 'assets/images/categories/meditation.png',
                      icon: Icons.nature_people_rounded,
                      color: const Color(0xFF651FFF),
                      onTap: () => context.push('/workout-category/Yoga'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 120),
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

    return BouncyTap(
      scaleDown: 0.94,
      onTap: onTap,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
          borderRadius: BorderRadius.circular(18),
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
                Container(
                  height: 125,
                  width: double.infinity,
                  color: Colors.transparent,
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(icon, color: color, size: 36),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
