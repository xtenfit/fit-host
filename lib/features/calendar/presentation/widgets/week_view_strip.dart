import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/calendar_event.dart';
import '../../domain/models/day_summary.dart';
import 'day_detail_sheet.dart';

class WeekViewStrip extends StatelessWidget {
  final DateTime selectedDate;
  final List<CalendarEvent> allEvents;
  final Map<String, DaySummary>? daySummaries;
  final Function(DateTime) onSelectDate;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  const WeekViewStrip({
    super.key,
    required this.selectedDate,
    required this.allEvents,
    this.daySummaries,
    required this.onSelectDate,
    this.onSwipeLeft,
    this.onSwipeRight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Monday as start of the week: weekday 1 = Monday ... 7 = Sunday
    final monday = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));

    // Group events by YYYY-MM-DD
    final Map<String, List<CalendarEvent>> eventsByDate = {};
    for (final event in allEvents) {
      final key = DateFormat('yyyy-MM-dd').format(event.scheduledDate);
      eventsByDate.putIfAbsent(key, () => []).add(event);
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -200) {
            onSwipeLeft?.call();
          } else if (details.primaryVelocity! > 200) {
            onSwipeRight?.call();
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: weekDays.map((day) {
            final isSelected = day.year == selectedDate.year &&
                day.month == selectedDate.month &&
                day.day == selectedDate.day;
            final isToday = day.year == today.year &&
                day.month == today.month &&
                day.day == today.day;
            final dateKey = DateFormat('yyyy-MM-dd').format(day);
            final dayEvents = eventsByDate[dateKey] ?? [];
            final summary = daySummaries?[dateKey];

            final bool stepGoalMet = summary != null && summary.isStepsGoalMet();
            final bool hasWorkout = (summary?.hasWorkout ?? false) ||
                dayEvents.any((e) => e.eventType == CalendarEventType.workout);
            final bool hasMeal = (summary?.hasMealLogged ?? false) ||
                dayEvents.any((e) => e.eventType == CalendarEventType.meal);
            final bool hasWater = summary?.hasWaterLogged ?? false;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  onSelectDate(day);
                  if (summary != null) {
                    DayDetailBottomSheet.show(context, daySummary: summary);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.electricBlue
                        : (isToday
                            ? (isDark
                                ? AppColors.electricBlue.withValues(alpha: 0.2)
                                : AppColors.electricBlue.withValues(alpha: 0.1))
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: stepGoalMet
                          ? const Color(0xFF10B981) // Green ring for step goal met
                          : (isToday && !isSelected
                              ? AppColors.electricBlue
                              : Colors.transparent),
                      width: stepGoalMet ? 2.0 : 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('E').format(day).substring(0, 3),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.9)
                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: isSelected
                              ? Colors.white
                              : (isToday
                                  ? AppColors.electricBlue
                                  : (isDark ? Colors.white : AppColors.lightTextPrimary)),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Badges: Workout (blue), meal (green), water (cyan)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (hasWorkout)
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? Colors.white : AppColors.electricBlue,
                              ),
                            ),
                          if (hasMeal)
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? Colors.white : const Color(0xFF22C55E),
                              ),
                            ),
                          if (hasWater)
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? Colors.white : const Color(0xFF06B6D4),
                              ),
                            ),
                          if (!hasWorkout && !hasMeal && !hasWater)
                            const SizedBox(height: 5),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
