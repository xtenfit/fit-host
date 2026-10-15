import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/calendar_event.dart';

class MonthViewGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDate;
  final List<CalendarEvent> monthEvents;
  final Function(DateTime) onSelectDate;

  const MonthViewGrid({
    super.key,
    required this.focusedMonth,
    required this.selectedDate,
    required this.monthEvents,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;

    // Monday as first day of week: 1 = Mon ... 7 = Sun
    // starting weekday offset: (weekday - 1)
    final startingOffset = (firstDayOfMonth.weekday - 1) % 7;
    final totalCells = ((startingOffset + daysInMonth + 6) ~/ 7) * 7;

    final weekHeaders = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    // Map events by day of month
    final Map<int, List<CalendarEvent>> eventsByDay = {};
    for (final event in monthEvents) {
      if (event.scheduledDate.year == focusedMonth.year &&
          event.scheduledDate.month == focusedMonth.month) {
        eventsByDay.putIfAbsent(event.scheduledDate.day, () => []).add(event);
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          // Weekday header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekHeaders.map((header) {
              return SizedBox(
                width: 38,
                child: Center(
                  child: Text(
                    header,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Days grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 6,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - startingOffset + 1;
              final isCurrentMonth = dayNumber >= 1 && dayNumber <= daysInMonth;

              if (!isCurrentMonth) {
                return const SizedBox.shrink();
              }

              final cellDate = DateTime(focusedMonth.year, focusedMonth.month, dayNumber);
              final isSelected = cellDate.year == selectedDate.year &&
                  cellDate.month == selectedDate.month &&
                  cellDate.day == selectedDate.day;
              final isToday = cellDate.year == today.year &&
                  cellDate.month == today.month &&
                  cellDate.day == today.day;

              final dayEvents = eventsByDay[dayNumber] ?? [];

              return InkWell(
                onTap: () => onSelectDate(cellDate),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.electricBlue
                        : (isToday
                            ? (isDark
                                ? AppColors.electricBlue.withValues(alpha: 0.2)
                                : AppColors.electricBlue.withValues(alpha: 0.1))
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isToday && !isSelected
                          ? AppColors.electricBlue
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected || isToday ? FontWeight.w900 : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isToday
                                  ? AppColors.electricBlue
                                  : (isDark ? Colors.white : AppColors.lightTextPrimary)),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Event indicators
                      if (dayEvents.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: dayEvents.take(3).map((e) {
                            return Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? Colors.white : e.eventType.color,
                              ),
                            );
                          }).toList(),
                        )
                      else
                        const SizedBox(height: 5),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
