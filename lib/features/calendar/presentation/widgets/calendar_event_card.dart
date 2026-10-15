import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/calendar_event.dart';

class CalendarEventCard extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback onToggleComplete;
  final Function(DateTime newDate, DateTime? newTime) onReschedule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CalendarEventCard({
    super.key,
    required this.event,
    required this.onToggleComplete,
    required this.onReschedule,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatTime() {
    if (event.startTime == null) return 'All Day';
    final startStr = DateFormat('h:mm a').format(event.startTime!);
    if (event.endTime != null) {
      final endStr = DateFormat('h:mm a').format(event.endTime!);
      return '$startStr - $endStr';
    }
    return startStr;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catColor = event.eventType.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: event.isCompleted
              ? AppColors.limeGreen.withValues(alpha: 0.5)
              : (isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder),
          width: event.isCompleted ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Category Pill, Status Badge & Actions
            Row(
              children: [
                // Category Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(event.eventType.icon, size: 13, color: catColor),
                      const SizedBox(width: 4),
                      Text(
                        event.eventType.label,
                        style: TextStyle(
                          color: catColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Status Badge (Completed / Missed / Today / Upcoming)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: event.statusColor.withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    event.statusDisplay,
                    style: TextStyle(
                      color: event.statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),

                // More Actions Menu
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    size: 20,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  padding: EdgeInsets.zero,
                  onSelected: (value) async {
                    if (value == 'reschedule') {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: event.scheduledDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (pickedDate != null && context.mounted) {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: event.startTime != null
                              ? TimeOfDay.fromDateTime(event.startTime!)
                              : const TimeOfDay(hour: 17, minute: 30),
                        );
                        DateTime? finalTime;
                        if (pickedTime != null) {
                          finalTime = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        }
                        onReschedule(pickedDate, finalTime);
                      }
                    } else if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'reschedule',
                      child: Row(
                        children: [
                          Icon(Icons.edit_calendar_rounded, size: 18),
                          SizedBox(width: 10),
                          Text('Reschedule'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 18),
                          SizedBox(width: 10),
                          Text('Edit details'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Middle Row: Checkbox + Title + Description
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Toggle Completion Button
                InkWell(
                  onTap: onToggleComplete,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 26,
                    height: 26,
                    margin: const EdgeInsets.only(top: 2, right: 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: event.isCompleted ? AppColors.limeGreen : Colors.transparent,
                      border: Border.all(
                        color: event.isCompleted
                            ? AppColors.limeGreen
                            : (isDark ? AppColors.darkSurfaceBorder : Colors.grey[400]!),
                        width: 2,
                      ),
                    ),
                    child: event.isCompleted
                        ? const Icon(Icons.check_rounded, size: 16, color: Colors.black)
                        : null,
                  ),
                ),

                // Title & Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          decoration: event.isCompleted ? TextDecoration.lineThrough : null,
                          color: event.isCompleted
                              ? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                              : null,
                        ),
                      ),
                      if (event.description != null && event.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          event.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Bottom Info Bar: Time & Metrics & Recurrence
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTime(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                if (event.recurrenceRule != RecurrenceRule.none) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.repeat_rounded,
                    size: 14,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    event.recurrenceRule.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
                const Spacer(),
                if (event.targetMetrics != null && event.targetMetrics!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF202430) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Target: ${event.targetMetrics!.values.first}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
