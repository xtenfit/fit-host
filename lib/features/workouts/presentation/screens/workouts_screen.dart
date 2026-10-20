import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fit_host/core/theme/app_colors.dart';
import 'package:fit_host/core/theme/app_motion.dart';
import 'package:fit_host/features/workouts/presentation/controllers/workout_providers.dart';

class WorkoutsScreen extends ConsumerWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(workoutsStreamProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Workouts',
            style: TextStyle(fontFamily: 'Arial', fontWeight: FontWeight.w800),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                ref.read(activeWorkoutProvider.notifier).startNewWorkout(
                      title: 'Workout ${DateFormat('EEE, MMM d').format(DateTime.now())}',
                    );
                context.push('/active-workout');
              },
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'New Workout',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.limeGreen,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.menu_book_rounded),
              tooltip: 'Exercise Library',
              onPressed: () => context.push('/exercises'),
            ),
            const SizedBox(width: 4),
          ],
          bottom: const TabBar(
            indicatorColor: AppColors.limeGreen,
            labelColor: AppColors.limeGreen,
            tabs: [
              Tab(text: 'History'),
              Tab(text: 'Routines & Plans'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              // 1. History Tab
              RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(workoutsStreamProvider);
                },
                child: workoutsAsync.when(
                  data: (workouts) {
                    if (workouts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 64,
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No workout history yet',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Complete a session to start tracking your progress.',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () {
                                ref
                                    .read(activeWorkoutProvider.notifier)
                                    .startNewWorkout();
                                context.push('/active-workout');
                              },
                              icon: const Icon(Icons.play_arrow_rounded,
                                  color: Colors.black),
                              label: const Text(
                                'Start First Workout',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                      physics: const BouncingScrollPhysics(),
                      itemCount: workouts.length,
                      itemBuilder: (context, idx) {
                        final w = workouts[idx];
                        final dateStr =
                            DateFormat('EEEE, MMM d, y • h:mm a').format(w.startedAt);

                        return BouncyTap(
                          scaleDown: 0.97,
                          onTap: () => context.push('/workout/${w.id}'),
                          child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            margin: const EdgeInsets.only(bottom: 12),
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
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: w.status == 'completed'
                                              ? AppColors.limeGreen
                                                  .withValues(alpha: 0.15)
                                              : AppColors.warning
                                                  .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          w.status.toUpperCase(),
                                          style: TextStyle(
                                            color: w.status == 'completed'
                                                ? (isDark
                                                    ? AppColors.limeGreen
                                                    : AppColors.limeGreenLight)
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
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: w.exercises.map((e) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.darkSurfaceElevated
                                              : AppColors.lightSurfaceElevated,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${e.sets.length} × ${e.exerciseName}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.lightTextSecondary,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _Metric(
                                        label: 'Duration',
                                        value: _formatDuration(w.durationSeconds),
                                        isDark: isDark,
                                      ),
                                      _Metric(
                                        label: 'Sets',
                                        value: '${w.completedSets}/${w.totalSets}',
                                        isDark: isDark,
                                      ),
                                      _Metric(
                                        label: 'Volume',
                                        value: '${w.totalVolumeKg.toInt()} kg',
                                        isDark: isDark,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
              ),

              // 2. Routines & Plans Tab (Requirement 3: Grouped by Active Plan, Saved Routines, Templates with Sticky Headers & BouncingScrollPhysics)
              CustomScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  // SECTION 1: FEATURED TRAINING PLAN
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickySectionHeaderDelegate(
                      title: 'Active Plan',
                      badge: 'FEATURED',
                      isDark: isDark,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      child: _ActivePlanCard(
                        title: 'Hypertrophy & Power Mass',
                        subtitle: 'Recommended • 4-5 workouts / week • 60 min',
                        progress: 0.0,
                        progressText: '12-Week Structured Progression',
                        imageAsset: 'assets/images/workouts/today_workout_athlete.png',
                        isDark: isDark,
                        onTap: () => context.push('/workout/plan-hypertrophy'),
                        onResume: () {
                          ref.read(activeWorkoutProvider.notifier).startNewWorkout(
                                title: 'Hypertrophy & Power Mass - Day 1',
                              );
                          context.push('/active-workout');
                        },
                      ),
                    ),
                  ),

                  // SECTION 2: SAVED ROUTINES
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickySectionHeaderDelegate(
                      title: 'Saved Routines',
                      badge: '3 ROUTINES',
                      isDark: isDark,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _RoutineCard(
                          title: 'Push Day (Chest, Shoulders, Triceps)',
                          description:
                              'Bench Press, Incline DB Press, Overhead Press, Cable Pushdowns',
                          exerciseCount: 4,
                          imageAsset: 'assets/images/workouts/strength.png',
                          isDark: isDark,
                          onStart: () {
                            _startRoutine(
                              ref,
                              context,
                              title: 'Push Day',
                              exerciseIds: [
                                'ex-bench-press',
                                'ex-incline-db-press',
                                'ex-overhead-press',
                                'ex-tricep-pushdown',
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _RoutineCard(
                          title: 'Pull Day (Back, Rear Delts, Biceps)',
                          description:
                              'Conventional Deadlift, Pull-Ups, Barbell Row, Bicep Curls',
                          exerciseCount: 4,
                          imageAsset: 'assets/images/workouts/today_workout_athlete.png',
                          isDark: isDark,
                          onStart: () {
                            _startRoutine(
                              ref,
                              context,
                              title: 'Pull Day',
                              exerciseIds: [
                                'ex-deadlift',
                                'ex-pullup',
                                'ex-barbell-row',
                                'ex-bicep-curl',
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _RoutineCard(
                          title: 'Leg Day (Quads, Hamstrings, Core)',
                          description:
                              'Barbell Squat, Romanian Deadlift, Core Plank',
                          exerciseCount: 3,
                          imageAsset: 'assets/images/categories/bodyweight.png',
                          isDark: isDark,
                          onStart: () {
                            _startRoutine(
                              ref,
                              context,
                              title: 'Leg Day',
                              exerciseIds: [
                                'ex-barbell-squat',
                                'ex-romanian-deadlift',
                                'ex-plank',
                              ],
                            );
                          },
                        ),
                      ]),
                    ),
                  ),

                  // SECTION 3: TEMPLATES
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickySectionHeaderDelegate(
                      title: 'Templates',
                      badge: 'EXPLORE',
                      isDark: isDark,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _TemplateCard(
                          title: 'Full Body Blitz',
                          description: 'High intensity compound lifts with functional power',
                          subtitle: '5 exercises • 35 min',
                          badge: 'FAT BURN',
                          imageAsset: 'assets/images/categories/bodyweight.png',
                          isDark: isDark,
                          onStart: () {
                            _startRoutine(
                              ref,
                              context,
                              title: 'Full Body Blitz',
                              exerciseIds: [
                                'ex-barbell-squat',
                                'ex-bench-press',
                                'ex-pullup',
                                'ex-plank',
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _TemplateCard(
                          title: 'Upper Body Power Spec',
                          description: 'Maximal strength progression with heavy barbell work',
                          subtitle: '6 exercises • 55 min',
                          badge: 'MASS',
                          imageAsset: 'assets/images/categories/strength.png',
                          isDark: isDark,
                          onStart: () {
                            _startRoutine(
                              ref,
                              context,
                              title: 'Upper Body Power Spec',
                              exerciseIds: [
                                'ex-bench-press',
                                'ex-incline-db-press',
                                'ex-overhead-press',
                                'ex-barbell-row',
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _TemplateCard(
                          title: 'Core & Kinetic Mobility',
                          description: 'Spinal decompression and posterior chain resilience',
                          subtitle: '4 exercises • 25 min',
                          badge: 'MOBILITY',
                          imageAsset: 'assets/images/workouts/today_workout_athlete.png',
                          isDark: isDark,
                          onStart: () {
                            _startRoutine(
                              ref,
                              context,
                              title: 'Core & Kinetic Mobility',
                              exerciseIds: [
                                'ex-plank',
                                'ex-romanian-deadlift',
                              ],
                            );
                          },
                        ),
                      ]),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 120),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startRoutine(
    WidgetRef ref,
    BuildContext context, {
    required String title,
    required List<String> exerciseIds,
  }) async {
    final repo = ref.read(workoutRepositoryProvider);
    final all = await repo.getExercises();
    final selected = all.where((e) => exerciseIds.contains(e.id)).toList();

    ref.read(activeWorkoutProvider.notifier).startNewWorkout(
          title: title,
          initialExercises: selected,
        );
    if (context.mounted) {
      context.push('/active-workout');
    }
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }
}

/// Sticky Header with frosted glass background that pins neatly at the top of each category
class _StickySectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final String badge;
  final bool isDark;

  const _StickySectionHeaderDelegate({
    required this.title,
    required this.badge,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: (isDark ? AppColors.darkBackground : AppColors.lightBackground)
              .withValues(alpha: overlapsContent ? 0.92 : 1.0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00E676).withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF00E676),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  double get minExtent => 44.0;

  @override
  double get maxExtent => 44.0;

  @override
  bool shouldRebuild(covariant _StickySectionHeaderDelegate oldDelegate) {
    return oldDelegate.title != title ||
        oldDelegate.badge != badge ||
        oldDelegate.isDark != isDark;
  }
}

/// Futuristic Active Plan Card with neon glow border, progress indicator, and action buttons
class _ActivePlanCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double progress;
  final String progressText;
  final String imageAsset;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onResume;

  const _ActivePlanCard({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.progressText,
    required this.imageAsset,
    required this.isDark,
    required this.onTap,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF00E676).withValues(alpha: 0.50),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E676).withValues(alpha: isDark ? 0.25 : 0.15),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Athlete Banner with Hero expansion
            SizedBox(
              height: 150,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'workout_hero_image_plan-hypertrophy',
                    child: Image.asset(
                      imageAsset,
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          (isDark ? AppColors.darkSurface : Colors.white)
                              .withValues(alpha: 0.95),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'CURRENT ENROLLED PLAN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Progress Bar & Percentage
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          progressText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF00E676),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF00E676),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontFamily: 'Arial',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
                      label: const Text(
                        'Start Today\'s Workout',
                        style: TextStyle(
                          fontFamily: 'Arial',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                      onPressed: onResume,
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

/// Template Workout Card
class _TemplateCard extends StatelessWidget {
  final String title;
  final String description;
  final String subtitle;
  final String badge;
  final String imageAsset;
  final bool isDark;
  final VoidCallback onStart;

  const _TemplateCard({
    required this.title,
    required this.description,
    required this.subtitle,
    required this.badge,
    required this.imageAsset,
    required this.isDark,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 72,
                height: 72,
                color: isDark ? const Color(0xFF1B202B) : const Color(0xFFF1F5F9),
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, st) => const Icon(Icons.fitness_center),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF00E676),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.lightTextTertiary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: onStart,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow_rounded, size: 14, color: Colors.black),
                              SizedBox(width: 2),
                              Text(
                                'Start',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _Metric({
    required this.label,
    required this.value,
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
            fontSize: 11,
            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _RoutineCard extends StatelessWidget {
  final String title;
  final String description;
  final int exerciseCount;
  final String imageAsset;
  final bool isDark;
  final VoidCallback onStart;

  const _RoutineCard({
    required this.title,
    required this.description,
    required this.exerciseCount,
    required this.imageAsset,
    required this.isDark,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              height: 160,
              width: double.infinity,
              color: isDark ? const Color(0xFF1B202B) : const Color(0xFFF1F5F9),
              padding: const EdgeInsets.all(8),
              child: Center(
                child: Image.asset(
                  imageAsset,
                  height: 160,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox(
                      height: 160,
                      child: Center(
                        child: Icon(Icons.fitness_center),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.limeGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$exerciseCount exercises',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.limeGreen : AppColors.limeGreenLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      textStyle: const TextStyle(
                        fontFamily: 'Arial',
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
                    label: const Text(
                      'Start Routine',
                      style: TextStyle(
                        fontFamily: 'Arial',
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: onStart,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
