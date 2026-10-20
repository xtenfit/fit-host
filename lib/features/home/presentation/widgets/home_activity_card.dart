import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../workouts/domain/models/workout_models.dart';
import '../../../workouts/presentation/controllers/workout_providers.dart';
import '../../../steps/presentation/controllers/step_controller.dart';
import '../../../steps/domain/step_calculator.dart';
import '../../../profile/presentation/controllers/user_profile_controller.dart';
import '../controllers/home_dashboard_controller.dart';

class HomeActivityCard extends ConsumerWidget {
  final bool isDark;

  const HomeActivityCard({super.key, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(homeDashboardProvider);
    final notifier = ref.read(homeDashboardProvider.notifier);
    final workoutsAsync = ref.watch(workoutsStreamProvider);
    final profile = ref.watch(userProfileProvider);

    final completedWorkouts = workoutsAsync.maybeWhen(
      data: (workouts) => workouts.where((w) => w.status == 'completed').toList(),
      orElse: () => <WorkoutEntity>[],
    );

    final totalActiveMinutes = completedWorkouts.fold<int>(
      0,
      (sum, w) => sum + (w.durationSeconds ~/ 60),
    );

    final goalMinutes = profile.dailyWorkoutMinutes > 0 ? profile.dailyWorkoutMinutes : 45;
    final progress = (totalActiveMinutes / goalMinutes).clamp(0.0, 1.0);
    final leftMinutes = (goalMinutes - totalActiveMinutes).clamp(0, goalMinutes);
    final restMinutes = (totalActiveMinutes * 0.15).round();

    const filters = ['Today', 'Weekly', 'Monthly', 'Yearly', 'All Time'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header: Your Activity
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            InkWell(
              onTap: () => context.go('/progress'),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  'Analytics',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.limeGreen : AppColors.limeGreenDark,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Time Filter Horizontal Pills
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final filter = filters[index];
              final isSelected = filter == dashboard.selectedActivityFilter;

              return InkWell(
                onTap: () => notifier.setActivityFilter(filter),
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFF6B4A)
                        : (isDark ? AppColors.darkSurfaceElevated : Colors.white),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFF6B4A)
                          : (isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      filter,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Today's Workout Detailed Activity Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header Row: ✓ Today's Workout  14 / 20
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppColors.limeGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 11,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Today\'s Workout',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${completedWorkouts.length} Completed',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.limeGreen : AppColors.limeGreenDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Circular Timer Gauge: Active vs Goal min.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        'Rest',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '$restMinutes',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFFB300),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'min.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Center Ring
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(110, 110),
                          painter: _ActivityGaugePainter(
                            progress: progress,
                            isDark: isDark,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$totalActiveMinutes',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'of $goalMinutes min.',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Column(
                    children: [
                      Text(
                        'Left',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '$leftMinutes',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFFB300),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'min.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Workout Activity Items: Real Database Entries or Start Routine Prompt
              if (completedWorkouts.isNotEmpty) ...[
                ...completedWorkouts.take(2).map((w) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _WorkoutActivityTile(
                      title: w.title,
                      subtitle: '${w.totalVolumeKg.toInt()} kg volume • ${w.completedSets} sets completed',
                      duration: '${(w.durationSeconds ~/ 60)} min.',
                      icon: Icons.fitness_center_rounded,
                      iconColor: const Color(0xFFFFB300),
                      isDark: isDark,
                    ),
                  );
                }),
              ] else ...[
                InkWell(
                  onTap: () => context.go('/workouts'),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.limeGreen.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.fitness_center_rounded,
                            size: 16,
                            color: AppColors.limeGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ready to Train?',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                ),
                              ),
                              Text(
                                'Start a workout routine to record real volume and duration',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: AppColors.limeGreen,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Bottom Mini Cards: Walk (6432 Steps) and Sleep (7.40 Hours)
        Row(
          children: [
            // Walk Card
            Expanded(
              child: InkWell(
                onTap: () => _showLogStepsDialog(context, ref),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                    borderRadius: BorderRadius.circular(20),
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
                            'Walk',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.lightTextPrimary,
                            ),
                          ),
                          const Icon(
                            Icons.directions_walk_rounded,
                            size: 16,
                            color: AppColors.electricCyan,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              '${dashboard.walkSteps}',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                              ),
                            ),
                            Text(
                              'Steps',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Sleep Card
            Expanded(
              child: InkWell(
                onTap: () => _showLogSleepDialog(context, ref, dashboard.sleepHours),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                    borderRadius: BorderRadius.circular(20),
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
                            'Sleep',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.lightTextPrimary,
                            ),
                          ),
                          const Text('🌙', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              dashboard.sleepHours.toStringAsFixed(2),
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFF6B4A),
                              ),
                            ),
                            Text(
                              'Hours',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showLogStepsDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final textVal = controller.text.trim();
            final parsed = int.tryParse(textVal) ?? 0;
            final dist = StepCalculator.distanceKm(steps: parsed, strideCm: 72.6);
            final cal = StepCalculator.estimateCalories(parsed);

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              title: const Row(
                children: [
                  Icon(Icons.directions_walk_rounded, color: AppColors.limeGreen),
                  SizedBox(width: 10),
                  Text('Log Walk Steps', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter your actual steps walked today from a treadmill, outdoor walk, or smartwatch session.',
                    style: TextStyle(fontSize: 13, height: 1.35),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'e.g. 2500',
                      labelText: 'Actual Steps',
                      prefixIcon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  if (parsed > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.limeGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Est. Distance: ${dist.toStringAsFixed(2)} km', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text('Est. Burn: $cal kcal', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.limeGreen)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/steps');
                  },
                  child: const Text('View All Steps'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: parsed <= 0
                      ? null
                      : () {
                          ref.read(homeDashboardProvider.notifier).logSteps(parsed);
                          ref.read(stepControllerProvider.notifier).addSimulatedSteps(parsed);
                          Navigator.pop(ctx);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.limeGreen,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Save Steps'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLogSleepDialog(BuildContext context, WidgetRef ref, double current) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Sleep Duration', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('7.5 Hours (Optimal Recovery)'),
              onTap: () {
                ref.read(homeDashboardProvider.notifier).setSleepHours(7.5);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('8.0 Hours (Deep Sleep)'),
              onTap: () {
                ref.read(homeDashboardProvider.notifier).setSleepHours(8.0);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('6.5 Hours (Short Rest)'),
              onTap: () {
                ref.read(homeDashboardProvider.notifier).setSleepHours(6.5);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutActivityTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String duration;
  final IconData icon;
  final Color iconColor;
  final bool isDark;

  const _WorkoutActivityTile({
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.icon,
    required this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              duration,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityGaugePainter extends CustomPainter {
  final double progress;
  final bool isDark;

  const _ActivityGaugePainter({
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background Arc
    final bgPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Dynamic Gradient Progress Arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
      colors: const [
        Color(0xFFFFB300),
        AppColors.limeGreen,
        AppColors.electricCyan,
      ],
      stops: const [0.0, 0.5, 1.0],
      transform: const GradientRotation(-math.pi / 2),
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _ActivityGaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
