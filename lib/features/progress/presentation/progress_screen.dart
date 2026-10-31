import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fit_host/core/theme/app_colors.dart';
import 'package:fit_host/core/services/supabase_service.dart';
import 'package:fit_host/features/auth/presentation/dialogs/feature_upsell_sheet.dart';
import 'package:fit_host/features/workouts/presentation/controllers/workout_providers.dart';
import 'package:fit_host/features/steps/presentation/controllers/step_controller.dart';
import 'package:fit_host/core/widgets/charts/volume_trend_chart.dart';
import 'package:fit_host/core/widgets/charts/weekly_steps_chart.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(workoutsStreamProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Progress & Analytics')),
      body: workoutsAsync.when(
        data: (workouts) {
          final completed = workouts
              .where((w) => w.status == 'completed')
              .toList();
          final totalVolume = completed.fold(
            0.0,
            (sum, w) => sum + w.totalVolumeKg,
          );
          final totalSets = completed.fold(
            0,
            (sum, w) => sum + w.completedSets,
          );
          final totalMinutes = completed.fold(
            0,
            (sum, w) => sum + (w.durationSeconds ~/ 60),
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
            children: [
              // Summary Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1B2A20), const Color(0xFF142028)]
                        : [const Color(0xFFECFDF5), const Color(0xFFF0FDF4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.limeGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          color: AppColors.limeGreen,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'All-Time Training Volume',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${(totalVolume / 1000).toStringAsFixed(2)} metric tons',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Accumulated across ${completed.length} completed workout sessions',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Metric Cards Grid
              Row(
                children: [
                  Expanded(
                    child: _AnalyticsCard(
                      label: 'Total Sessions',
                      value: '${completed.length}',
                      icon: Icons.check_circle_outline_rounded,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AnalyticsCard(
                      label: 'Total Sets Done',
                      value: '$totalSets',
                      icon: Icons.repeat_rounded,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AnalyticsCard(
                      label: 'Time Under Tension',
                      value: '${totalMinutes}m',
                      icon: Icons.timer_outlined,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Daily Steps & Movement Analytics Card
              _StepMovementCard(isDark: isDark),
              const SizedBox(height: 14),

              // 7-Day Interactive Step Bar Chart
              Consumer(
                builder: (context, ref, _) {
                  final stepState = ref.watch(stepControllerProvider);
                  return WeeklyStepsChart(
                    history: stepState.history,
                    todaySteps: stepState.todaySteps,
                    targetSteps: stepState.targetSteps,
                    isDark: isDark,
                  );
                },
              ),
              const SizedBox(height: 20),

              // Part 4: Body Measurements & Progress Photo Gallery
              Row(
                children: [
                  Expanded(
                    child: _QuickNavigationCard(
                      icon: Icons.straighten_rounded,
                      title: 'Body Metrics',
                      subtitle: 'Tape & weight log',
                      color: AppColors.limeGreen,
                      onTap: () => context.push('/progress/measurements'),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickNavigationCard(
                      icon: Icons.photo_library_outlined,
                      title: 'Photo Gallery',
                      subtitle: 'Before & After tool',
                      color: AppColors.electricCyan,
                      onTap: () => context.push('/progress/gallery'),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 14-Day Interactive Volume Progression Curve
              VolumeTrendChart(workouts: completed, days: 14, isDark: isDark),
              const SizedBox(height: 24),
              // Advanced Progress Charts (>7d) - Gated for guests
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Multi-Week Trends (>7d)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (ref.watch(authProvider).isGuest)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_rounded,
                            size: 12,
                            color: Colors.amber,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Account Only',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (ref.watch(authProvider).isGuest)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      FeatureUpsellSheet.show(
                        context,
                        title: 'Advanced Progress Charts (>7d)',
                        description:
                            'Track multi-month volume progression, progressive overload curves, and personal records beyond 7 days with a free Fit Host account.',
                        icon: Icons.insights_rounded,
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF19251E),
                                  const Color(0xFF141F28),
                                ]
                              : [
                                  const Color(0xFFF0FDF4),
                                  const Color(0xFFE8F6FE),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.limeGreen.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.limeGreen.withValues(
                                    alpha: 0.15,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.lock_outline_rounded,
                                  color: AppColors.limeGreen,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Historical Analytics Locked',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Guests can view current 7-day logs. Create a free account to unlock multi-month progressive overload graphs, 1RM curves, and training frequency heatmaps.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            onPressed: () {
                              FeatureUpsellSheet.show(
                                context,
                                title: 'Advanced Progress Charts (>7d)',
                                description:
                                    'Track multi-month volume progression, progressive overload curves, and personal records beyond 7 days with a free Fit Host account.',
                                icon: Icons.insights_rounded,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.limeGreen,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.lock_open_rounded, size: 16),
                            label: const Text(
                              'Unlock Advanced Charts',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                VolumeTrendChart(workouts: completed, days: 30, isDark: isDark),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;

  const _AnalyticsCard({
    required this.label,
    required this.value,
    required this.icon,
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
          color: isDark
              ? AppColors.darkSurfaceBorder
              : AppColors.lightSurfaceBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.limeGreen),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepMovementCard extends ConsumerWidget {
  final bool isDark;

  const _StepMovementCard({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = ref.watch(stepControllerProvider);
    final pct = (steps.progressPercentage * 100).toInt();

    return InkWell(
      onTap: () => context.push('/steps'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.limeGreen.withValues(alpha: 0.3),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.limeGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.directions_walk_rounded,
                    color: AppColors.limeGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daily Movement & Pedometer',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${NumberFormat('#,###').format(steps.todaySteps)} / ${NumberFormat('#,###').format(steps.targetSteps)} steps ($pct%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  steps.formattedDistance,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.electricCyan,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: steps.progressPercentage,
                minHeight: 6,
                backgroundColor: isDark ? Colors.white10 : Colors.black12,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.limeGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickNavigationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _QuickNavigationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppColors.darkSurfaceBorder
                : AppColors.lightSurfaceBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
