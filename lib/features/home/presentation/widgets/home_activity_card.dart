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

    final stepState = ref.watch(stepControllerProvider);
    final now = DateTime.now();
    final filter = dashboard.selectedActivityFilter;
    final rangeStart = _rangeStart(now, filter);

    final completedWorkouts = workoutsAsync.maybeWhen(
      data: (workouts) => workouts
          .where(
            (w) =>
                w.status == 'completed' &&
                _isInRange(w.startedAt.toLocal(), rangeStart, now),
          )
          .toList(),
      orElse: () => <WorkoutEntity>[],
    );

    final historySteps = stepState.history
        .where((record) => _isInRange(record.date, rangeStart, now))
        .fold<int>(0, (sum, record) => sum + record.steps);
    final displayedSteps = historySteps == 0 && filter == 'Today'
        ? stepState.todaySteps
        : historySteps;
    final totalActiveMinutes = completedWorkouts.fold<int>(
      0,
      (sum, w) => sum + (w.durationSeconds ~/ 60),
    );

    final goalMinutes = profile.dailyWorkoutMinutes > 0
        ? profile.dailyWorkoutMinutes
        : 45;
    final progress = (totalActiveMinutes / goalMinutes).clamp(0.0, 1.0);
    final leftMinutes = (goalMinutes - totalActiveMinutes).clamp(
      0,
      goalMinutes,
    );
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
                    color: isDark
                        ? AppColors.limeGreen
                        : AppColors.limeGreenDark,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFF6B4A)
                        : (isDark
                              ? AppColors.darkSurfaceElevated
                              : Colors.white),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFF6B4A)
                          : (isDark
                                ? AppColors.darkSurfaceBorder
                                : AppColors.lightSurfaceBorder),
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
                            : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
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
              color: isDark
                  ? AppColors.darkSurfaceBorder
                  : AppColors.lightSurfaceBorder,
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
                            filter == 'Today'
                                ? 'Today\'s Workout'
                                : '$filter Activity',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.lightTextPrimary,
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
                      color: isDark
                          ? AppColors.limeGreen
                          : AppColors.limeGreenDark,
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
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
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
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary,
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
                                color: isDark
                                    ? Colors.white
                                    : AppColors.lightTextPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'of $goalMinutes min.',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
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
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
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
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary,
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
                      subtitle:
                          '${w.totalVolumeKg.toInt()} kg volume • ${w.completedSets} sets completed',
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.04,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.08),
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
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                              Text(
                                'Start a workout routine to record real volume and duration',
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
                    color: isDark
                        ? AppColors.darkSurfaceElevated
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkSurfaceBorder
                          : AppColors.lightSurfaceBorder,
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
                              color: isDark
                                  ? Colors.white
                                  : AppColors.lightTextPrimary,
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
                              '$displayedSteps',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            Text(
                              'Steps',
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
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Sleep Card (Honest state: shows -- if unrecorded)
            Expanded(
              child: InkWell(
                onTap: () =>
                    _showLogSleepDialog(context, ref, dashboard.sleepHours),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceElevated
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkSurfaceBorder
                          : AppColors.lightSurfaceBorder,
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
                              color: isDark
                                  ? Colors.white
                                  : AppColors.lightTextPrimary,
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
                              dashboard.sleepHours > 0
                                  ? dashboard.sleepHours.toStringAsFixed(1)
                                  : '--',
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFF6B4A),
                              ),
                            ),
                            Text(
                              dashboard.sleepHours > 0 ? 'Hours' : 'Tap to log',
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

  DateTime _rangeStart(DateTime now, String filter) {
    final today = DateTime(now.year, now.month, now.day);
    switch (filter) {
      case 'Weekly':
        return today.subtract(const Duration(days: 6));
      case 'Monthly':
        return DateTime(today.year, today.month, 1);
      case 'Yearly':
        return DateTime(today.year);
      case 'All Time':
        return DateTime(2000);
      case 'Today':
      default:
        return today;
    }
  }

  bool _isInRange(DateTime value, DateTime start, DateTime now) {
    final date = DateTime(value.year, value.month, value.day);
    final end = DateTime(now.year, now.month, now.day);
    return !date.isBefore(start) && !date.isAfter(end);
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
            final dist = StepCalculator.distanceKm(
              steps: parsed,
              strideCm: 72.6,
            );
            final cal = StepCalculator.estimateCalories(parsed);

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.directions_walk_rounded,
                    color: AppColors.limeGreen,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Log Walk Steps',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                  ),
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
                      prefixIcon: const Icon(
                        Icons.add_circle_outline_rounded,
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  if (parsed > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.limeGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Est. Distance: ${dist.toStringAsFixed(2)} km',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Est. Burn: $cal kcal',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.limeGreen,
                            ),
                          ),
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
                          ref
                              .read(homeDashboardProvider.notifier)
                              .logSteps(parsed);
                          ref
                              .read(stepControllerProvider.notifier)
                              .addSimulatedSteps(parsed);
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

  void _showLogSleepDialog(
    BuildContext context,
    WidgetRef ref,
    double current,
  ) {
    double selected = (current > 0 ? current : 7.5).clamp(4.0, 14.0);
    final ctrl = TextEditingController(
      text: selected % 1 == 0
          ? selected.toInt().toString()
          : selected.toStringAsFixed(1),
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          void updateHours(double val) {
            final clamped = val.clamp(4.0, 14.0);
            setDialogState(() {
              selected = clamped;
              ctrl.text = clamped % 1 == 0
                  ? clamped.toInt().toString()
                  : clamped.toStringAsFixed(1);
            });
          }

          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF161F1A) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.limeGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bedtime_rounded,
                    color: AppColors.limeGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Log Sleep Duration',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  // Big display with stepper buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: selected > 4.0
                            ? () => updateHours(selected - 0.5)
                            : null,
                        icon: const Icon(
                          Icons.remove_circle_outline_rounded,
                          size: 32,
                        ),
                        color: AppColors.limeGreen,
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.limeGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.limeGreen.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '${selected % 1 == 0 ? selected.toInt() : selected.toStringAsFixed(1)} hrs',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppColors.limeGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: selected < 14.0
                            ? () => updateHours(selected + 0.5)
                            : null,
                        icon: const Icon(
                          Icons.add_circle_outline_rounded,
                          size: 32,
                        ),
                        color: AppColors.limeGreen,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Interactive Slider
                  Slider(
                    value: selected,
                    min: 4.0,
                    max: 14.0,
                    divisions: 20, // 0.5 hr increments
                    activeColor: AppColors.limeGreen,
                    onChanged: (v) => updateHours(v),
                  ),
                  const SizedBox(height: 12),
                  // Quick Presets
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [6.0, 7.0, 7.5, 8.0, 8.5, 9.0].map((preset) {
                      final isSelected = (selected - preset).abs() < 0.1;
                      return ChoiceChip(
                        label: Text(
                          '${preset % 1 == 0 ? preset.toInt() : preset}h',
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.limeGreen,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.black
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onSelected: (_) => updateHours(preset),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Direct number input
                  TextField(
                    controller: ctrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Or enter custom hours',
                      suffixText: 'hrs',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (txt) {
                      final val = double.tryParse(txt.trim());
                      if (val != null) updateHours(val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.limeGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  final parsed = double.tryParse(ctrl.text.trim());
                  final finalHours = (parsed ?? selected).clamp(4.0, 14.0);
                  ref
                      .read(homeDashboardProvider.notifier)
                      .setSleepHours(finalHours);
                  Navigator.pop(ctx);
                },
                child: const Text(
                  'Save Sleep',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
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
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
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
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.06,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              duration,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
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

  const _ActivityGaugePainter({required this.progress, required this.isDark});

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
