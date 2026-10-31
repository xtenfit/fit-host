import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../workouts/presentation/controllers/workout_providers.dart';
import '../../../workouts/domain/models/workout_models.dart';
import '../controllers/home_dashboard_controller.dart';

class HomeStreakDateStrip extends ConsumerWidget {
  final bool isDark;

  const HomeStreakDateStrip({super.key, required this.isDark});

  int _calculateStreak(List<WorkoutEntity> completed) {
    if (completed.isEmpty) return 0;

    final workoutDates = completed.map((w) {
      final d = w.startedAt;
      return DateTime(d.year, d.month, d.day);
    }).toSet();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    DateTime checkDate;
    if (workoutDates.contains(today)) {
      checkDate = today;
    } else if (workoutDates.contains(yesterday)) {
      checkDate = yesterday;
    } else {
      return 0;
    }

    int streak = 0;
    while (workoutDates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(homeDashboardProvider);
    final notifier = ref.read(homeDashboardProvider.notifier);
    final workoutsAsync = ref.watch(workoutsStreamProvider);
    final now = DateTime.now();

    final completedWorkouts = workoutsAsync.maybeWhen(
      data: (workouts) =>
          workouts.where((w) => w.status == 'completed').toList(),
      orElse: () => <WorkoutEntity>[],
    );
    final streakDays = _calculateStreak(completedWorkouts);

    final selectedDay = calendarDate(dashboard.selectedDate);
    final today = calendarDate(now);
    final days = List.generate(
      5,
      (index) => selectedDay.add(Duration(days: index - 3)),
    );

    return Column(
      children: [
        // Top row: Streak Pill & Status Pill
        Row(
          children: [
            // Streak Pill: 🔥 Real Streak
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkSurfaceBorder
                      : AppColors.lightSurfaceBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B4A).withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    '$streakDays',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    streakDays == 1 ? 'Day Streak' : 'Days Streak',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Workout Status Pill: [Wed] Time to workout • Tap for Calendar with Bouncy Spring
            Expanded(
              child: BouncyTap(
                onTap: () => context.push('/calendar'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
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
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.limeGreen,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          DateFormat('E').format(selectedDay),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Time to workout',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.calendar_month_rounded,
                        size: 16,
                        color: AppColors.electricBlue,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (!isSameCalendarDate(selectedDay, today))
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => notifier.selectDate(today),
              child: const Text('Today'),
            ),
          ),
        const SizedBox(height: 12),

        // Mini Horizontal Date Selector (5 days: past 3 days, today, next day)
        SizedBox(
          height: 78,
          child: Row(
            children: [
              for (int index = 0; index < days.length; index++) ...[
                if (index > 0) const SizedBox(width: 8),
                Expanded(
                  child: _buildDateCard(
                    date: days[index],
                    dashboard: dashboard,
                    notifier: notifier,
                    now: now,
                    isDark: isDark,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateCard({
    required DateTime date,
    required HomeDashboardState dashboard,
    required HomeDashboardNotifier notifier,
    required DateTime now,
    required bool isDark,
  }) {
    final isSelected =
        date.year == dashboard.selectedDate.year &&
        date.month == dashboard.selectedDate.month &&
        date.day == dashboard.selectedDate.day;
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    return BouncyTap(
      scaleDown: 0.94,
      onTap: () {
        AppMotion.selectHaptic();
        notifier.selectDate(date);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: AppMotion.iosSpring,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? AppColors.limeGreen.withValues(alpha: 0.15)
                    : AppColors.limeGreen.withValues(alpha: 0.2))
              : (isDark ? AppColors.darkSurfaceElevated : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.limeGreen
                : (isToday
                      ? AppColors.electricCyan.withValues(alpha: 0.6)
                      : (isDark
                            ? AppColors.darkSurfaceBorder
                            : AppColors.lightSurfaceBorder)),
            width: isSelected ? 1.8 : (isToday ? 1.4 : 1),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isSelected
                    ? (isDark ? AppColors.limeGreen : AppColors.limeGreenDark)
                    : (isToday
                          ? AppColors.electricCyan
                          : (isDark
                                ? Colors.white
                                : AppColors.lightTextPrimary)),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('E').format(date),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? (isDark ? AppColors.limeGreen : AppColors.limeGreenDark)
                    : (isToday
                          ? AppColors.electricCyan
                          : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary)),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 3),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: isToday ? AppColors.electricCyan : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
