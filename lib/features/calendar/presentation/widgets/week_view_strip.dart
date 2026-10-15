import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/calendar_event.dart';

class WeekViewStrip extends StatelessWidget {
  final DateTime selectedDate;
  final List<CalendarEvent> allEvents;
  final Function(DateTime) onSelectDate;

  const WeekViewStrip({
    super.key,
    required this.selectedDate,
    required this.allEvents,
    required this.onSelectDate,
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

    return Container(
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

          return Expanded(
            child: GestureDetector(
              onTap: () => onSelectDate(day),
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
                    color: isToday && !isSelected
                        ? AppColors.electricBlue
                        : Colors.transparent,
                    width: 1.5,
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
            ),
          );
        }).toList(),
      ),
    );
  }
}
