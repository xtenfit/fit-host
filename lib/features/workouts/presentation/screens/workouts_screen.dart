import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fit_host/core/theme/app_colors.dart';
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
          title: const Text('Workouts'),
          actions: [
            IconButton(
              icon: const Icon(Icons.menu_book_rounded),
              tooltip: 'Exercise Library',
              onPressed: () => context.push('/exercises'),
            ),
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
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.limeGreen,
          foregroundColor: Colors.black,
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'New Workout',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            ref.read(activeWorkoutProvider.notifier).startNewWorkout(
                  title: 'Workout ${DateFormat('EEE, MMM d').format(DateTime.now())}',
                );
            context.push('/active-workout');
          },
        ),
        body: TabBarView(
          children: [
            // History Tab
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: workouts.length,
                    itemBuilder: (context, idx) {
                      final w = workouts[idx];
                      final dateStr =
                          DateFormat('EEEE, MMM d, y • h:mm a').format(w.startedAt);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
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
                                // Exercises preview tags
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

            // Routines / Templates Tab
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _RoutineCard(
                  title: 'Push Day (Chest, Shoulders, Triceps)',
                  description:
                      'Bench Press, Incline DB Press, Overhead Press, Cable Pushdowns',
                  exerciseCount: 4,
                  imageAsset: 'assets/images/workouts/strength.jpg',
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
                  imageAsset: 'assets/images/workouts/gym_workout.jpg',
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
                  imageAsset: 'assets/images/workouts/bodyweight.jpg',
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
              ],
            ),
          ],
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.asset(
              imageAsset,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(
                  height: 140,
                  child: Center(
                    child: Icon(Icons.fitness_center),
                  ),
                );
              },
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
                    icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
                    label: const Text(
                      'Start Routine',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
