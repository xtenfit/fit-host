import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/reminder.dart';

class ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final Function(bool) onToggle;
  final Function(int) onSnooze;
  final VoidCallback onComplete;
  final VoidCallback onDismiss;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ReminderCard({
    super.key,
    required this.reminder,
    required this.onToggle,
    required this.onSnooze,
    required this.onComplete,
    required this.onDismiss,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatNextAlarm() {
    if (!reminder.isEnabled) return 'Disabled';
    final now = DateTime.now();
    final next = reminder.nextOccurrence(now);
    final isToday = next.day == now.day && next.month == now.month && next.year == now.year;
    final isTomorrow = next.difference(now).inDays == 1 || (next.day == now.day + 1);

    final timeStr = DateFormat('h:mm a').format(next);
    if (isToday) return 'Today at $timeStr';
    if (isTomorrow) return 'Tomorrow at $timeStr';
    return '${DateFormat('EEE, MMM d').format(next)} at $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catColor = reminder.category.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: reminder.isEnabled
              ? (isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder)
              : Colors.transparent,
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
            // Top Row: Category Chip & Switch Toggle
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
                      Icon(reminder.category.icon, size: 13, color: catColor),
                      const SizedBox(width: 4),
                      Text(
                        reminder.category.label,
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

                // Sound / Vibration indicator icons
                if (reminder.soundEnabled)
                  Icon(
                    Icons.volume_up_rounded,
                    size: 14,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                const SizedBox(width: 4),
                if (reminder.vibrationEnabled)
                  Icon(
                    Icons.vibration_rounded,
                    size: 14,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),

                const Spacer(),

                // Enable/Disable Switch
                Switch.adaptive(
                  value: reminder.isEnabled,
                  activeTrackColor: AppColors.electricBlue,
                  onChanged: onToggle,
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Middle Row: Time & Title
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  reminder.formattedTime,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: reminder.isEnabled
                        ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                        : (isDark ? AppColors.darkTextSecondary : Colors.grey[400]),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    reminder.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: reminder.isEnabled
                          ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                          : (isDark ? AppColors.darkTextSecondary : Colors.grey[400]),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Schedule & Next Alarm row
            Row(
              children: [
                Icon(
                  Icons.repeat_rounded,
                  size: 14,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  reminder.repeatSummary,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '• ${_formatNextAlarm()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: reminder.isEnabled ? AppColors.electricBlue : Colors.grey[500],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Bottom Action Strip
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Snooze Action Button
                if (reminder.isEnabled)
                  OutlinedButton.icon(
                    onPressed: () => onSnooze(reminder.snoozeDurationMinutes),
                    icon: const Icon(Icons.snooze_rounded, size: 14),
                    label: Text('+${reminder.snoozeDurationMinutes}m'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),

                // Mark Done / Completed
                if (reminder.isEnabled)
                  ElevatedButton.icon(
                    onPressed: onComplete,
                    icon: const Icon(Icons.check_rounded, size: 14),
                    label: const Text('Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.limeGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                // More Menu Button
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    size: 20,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  onSelected: (val) {
                    if (val == 'edit') {
                      onEdit();
                    } else if (val == 'dismiss') {
                      onDismiss();
                    } else if (val == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Edit reminder'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'dismiss',
                      child: Row(
                        children: [
                          Icon(Icons.close_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Dismiss for now'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
