import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/calendar_event.dart';
import 'calendar_event_card.dart';

class DayViewTimeline extends StatelessWidget {
  final DateTime selectedDate;
  final List<CalendarEvent> dayEvents;
  final Function(CalendarEvent) onToggleComplete;
  final Function(CalendarEvent, DateTime newDate, DateTime? newTime) onReschedule;
  final Function(CalendarEvent) onEdit;
  final Function(CalendarEvent) onDelete;
  final Function(DateTime slotTime) onAddAtSlot;

  const DayViewTimeline({
    super.key,
    required this.selectedDate,
    required this.dayEvents,
    required this.onToggleComplete,
    required this.onReschedule,
    required this.onEdit,
    required this.onDelete,
    required this.onAddAtSlot,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Time buckets: 06:00, 08:00, 10:00, 12:00, 14:00, 16:00, 18:00, 20:00, 22:00
    final hours = [6, 8, 10, 12, 14, 16, 18, 20, 22];

    return Column(
      children: hours.map((hour) {
        final slotTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, hour);

        // Find events that fall in [hour, hour + 2)
        final slotEvents = dayEvents.where((e) {
          if (e.startTime == null) return hour == 8; // place all-day at 8am
          return e.startTime!.hour >= hour && e.startTime!.hour < (hour + 2);
        }).toList();

        final timeLabel = DateFormat('h a').format(slotTime);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time label column
              SizedBox(
                width: 54,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    timeLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              ),

              // Divider bar with dot
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: slotEvents.isNotEmpty ? AppColors.electricBlue : Colors.grey[400],
                    ),
                  ),
                  Container(
                    width: 2,
                    height: slotEvents.isNotEmpty ? (slotEvents.length * 130.0) : 40,
                    color: isDark ? AppColors.darkSurfaceBorder : Colors.grey[300],
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Events or Empty Add Prompt
              Expanded(
                child: slotEvents.isNotEmpty
                    ? Column(
                        children: slotEvents.map((event) {
                          return CalendarEventCard(
                            event: event,
                            onToggleComplete: () => onToggleComplete(event),
                            onReschedule: (newDate, newTime) =>
                                onReschedule(event, newDate, newTime),
                            onEdit: () => onEdit(event),
                            onDelete: () => onDelete(event),
                          );
                        }).toList(),
                      )
                    : InkWell(
                        onTap: () => onAddAtSlot(slotTime),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceElevated.withValues(alpha: 0.5)
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? AppColors.darkSurfaceBorder : Colors.grey[200]!,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.add_circle_outline_rounded,
                                size: 16,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Available slot - tap to schedule',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
