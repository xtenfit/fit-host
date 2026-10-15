import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/home_dashboard_controller.dart';

class HomeStreakDateStrip extends ConsumerWidget {
  final bool isDark;

  const HomeStreakDateStrip({super.key, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(homeDashboardProvider);
    final notifier = ref.read(homeDashboardProvider.notifier);
    final now = DateTime.now();

    // Generate surrounding 5 days: today - 1 to today + 3
    final days = List.generate(5, (index) => now.add(Duration(days: index - 1)));

    return Column(
      children: [
        // Top row: Streak Pill & Status Pill
        Row(
          children: [
            // Streak Pill: 🔥 21 Strikes
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
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
                    '${dashboard.streakDays}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Strikes',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Workout Status Pill: [Wed] Time to workout
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.limeGreen,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        DateFormat('E').format(now),
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
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Mini Horizontal Date Selector
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final date = days[index];
              final isSelected = date.day == dashboard.selectedDate.day &&
                  date.month == dashboard.selectedDate.month;
              final isToday = date.day == now.day && date.month == now.month;

              return InkWell(
                onTap: () => notifier.selectDate(date),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 58,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? AppColors.limeGreen.withValues(alpha: 0.15) : AppColors.limeGreen.withValues(alpha: 0.2))
                        : (isDark ? AppColors.darkSurfaceElevated : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.limeGreen
                          : (isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder),
                      width: isSelected ? 1.5 : 1,
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
                              : (isDark ? Colors.white : AppColors.lightTextPrimary),
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
                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                      ),
                      if (isToday)
                        Container(
                          margin: const EdgeInsets.only(top: 3),
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppColors.electricCyan,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
