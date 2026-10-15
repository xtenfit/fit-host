import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fit_host/core/theme/app_colors.dart';
import 'package:fit_host/features/workouts/presentation/controllers/workout_providers.dart';

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
        title: Row(
          children: [
            Image.asset(
              'assets/images/fit_host_icon.png',
              height: 28,
              width: 28,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Text(
              'FIT HOST',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Offline First',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
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
            // Hero Start Workout Card
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ready to Train?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.limeGreen.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.limeGreen.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Image.asset(
                          'assets/images/fit_host_icon.png',
                          height: 32,
                          width: 32,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Log your sets, reps, and track your progressive overload seamlessly offline.',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
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
            const SizedBox(height: 24),

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
