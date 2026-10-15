import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../workouts/presentation/controllers/workout_providers.dart';
import '../controllers/home_dashboard_controller.dart';

class HomeTodayWorkoutHero extends ConsumerWidget {
  final bool isDark;

  const HomeTodayWorkoutHero({super.key, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeState = ref.watch(activeWorkoutProvider);
    final dashboard = ref.watch(homeDashboardProvider);
    final dashboardNotifier = ref.read(homeDashboardProvider.notifier);

    final workoutTitle = activeState.isActive && activeState.workout != null
        ? activeState.workout!.title
        : 'Full Body Workout';

    final caloriesText = activeState.isActive && activeState.workout != null
        ? '${(activeState.workout!.durationSeconds * 0.12).toInt() + 150} Kcal'
        : '1800 Kcal';

    final durationText = activeState.isActive && activeState.workout != null
        ? '${(activeState.workout!.durationSeconds ~/ 60)} min'
        : '60 min';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today\'s Workout',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Right-aligned Athlete Illustration with Gradient Blend
              Positioned(
                right: -10,
                top: 0,
                bottom: 0,
                width: 210,
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                        Colors.black,
                      ],
                      stops: const [0.0, 0.35, 1.0],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Image.asset(
                    'assets/images/workouts/today_workout_athlete.jpg',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/images/workouts/strength_hero.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              // Left-aligned Content
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Row: Tag Pill & Favorite Star
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: AppColors.limeGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '• Advanced',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Star Favorite Button
                        InkWell(
                          onTap: () => dashboardNotifier.toggleFavorite(),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              dashboard.isFavoriteWorkout
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: const Color(0xFFFFB300),
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Middle: Workout Title
                    SizedBox(
                      width: 170,
                      child: Text(
                        workoutTitle,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          height: 1.15,
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Bottom: Play Button & Sub-stats
                    Row(
                      children: [
                        // Circular Play Button
                        GestureDetector(
                          onTap: () {
                            if (!activeState.isActive) {
                              ref.read(activeWorkoutProvider.notifier).startNewWorkout(
                                    title: 'Workout ${DateFormat('EEE, MMM d').format(DateTime.now())}',
                                  );
                            }
                            context.push('/active-workout');
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.limeGreen,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.limeGreen.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              activeState.isActive
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.black,
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Sub-stats: Calories & Time
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Text('🔥', style: TextStyle(fontSize: 11)),
                                const SizedBox(width: 4),
                                Text(
                                  caloriesText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Text('⏳', style: TextStyle(fontSize: 11)),
                                const SizedBox(width: 4),
                                Text(
                                  durationText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
