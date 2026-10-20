import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../core/database/database.dart' as db;
import '../../../../core/theme/app_colors.dart';

enum ReminderCategory {
  workout(label: 'Workout', icon: Icons.fitness_center_rounded, color: AppColors.electricBlue),
  meal(label: 'Meal Time', icon: Icons.restaurant_rounded, color: Color(0xFFFF6B4A)),
  hydration(label: 'Water Intake', icon: Icons.water_drop_rounded, color: Color(0xFF00B4D8)),
  sleep(label: 'Sleep & Wind-down', icon: Icons.bedtime_rounded, color: Color(0xFF9D4EDD)),
  habit(label: 'Daily Habit', icon: Icons.check_circle_rounded, color: AppColors.limeGreen),
  custom(label: 'Custom Alarm', icon: Icons.alarm_rounded, color: Color(0xFFFFD166));

  final String label;
  final IconData icon;
  final Color color;

  const ReminderCategory({
    required this.label,
    required this.icon,
    required this.color,
  });

  static ReminderCategory fromString(String val) {
    switch (val.toLowerCase()) {
      case 'workout':
        return ReminderCategory.workout;
      case 'meal':
        return ReminderCategory.meal;
      case 'hydration':
        return ReminderCategory.hydration;
      case 'sleep':
        return ReminderCategory.sleep;
      case 'habit':
        return ReminderCategory.habit;
      default:
        return ReminderCategory.custom;
    }
  }

  String get dbValue => name;
}

enum ReminderRecurrence {
  once(label: 'Once'),
  daily(label: 'Every day'),
  weekdays(label: 'Weekdays (Mon-Fri)'),
  weekly(label: 'Weekly'),
  monthly(label: 'Monthly'),
  custom(label: 'Custom days');

  final String label;
  const ReminderRecurrence({required this.label});

  static ReminderRecurrence fromString(String val) {
    switch (val.toLowerCase()) {
      case 'once':
        return ReminderRecurrence.once;
      case 'daily':
        return ReminderRecurrence.daily;
      case 'weekdays':
        return ReminderRecurrence.weekdays;
      case 'weekly':
        return ReminderRecurrence.weekly;
      case 'monthly':
        return ReminderRecurrence.monthly;
      case 'custom':
        return ReminderRecurrence.custom;
      default:
        return ReminderRecurrence.daily;
    }
  }

  String get dbValue => name;
}

class Reminder {
  final String id;
  final String title;
  final ReminderCategory category;
  final String timeOfDay; // 'HH:mm' 24-hr string
  final bool isEnabled;
  final ReminderRecurrence recurrence;
  final List<int> repeatDays; // 1 = Monday ... 7 = Sunday
  final bool soundEnabled;
  final bool vibrationEnabled;
  final int snoozeDurationMinutes;
  final DateTime? lastTriggeredAt;
  final DateTime? lastCompletedAt;
  final bool isDismissed;
  final DateTime createdAt;
  final DateTime updatedAt;

  Reminder({
    required this.id,
    required this.title,
    required this.category,
    required this.timeOfDay,
    this.isEnabled = true,
    this.recurrence = ReminderRecurrence.daily,
    this.repeatDays = const [],
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.snoozeDurationMinutes = 10,
    this.lastTriggeredAt,
    this.lastCompletedAt,
    this.isDismissed = false,
    required this.createdAt,
    required this.updatedAt,
  });

  int get hour {
    final parts = timeOfDay.split(':');
    return int.tryParse(parts[0]) ?? 8;
  }

  int get minute {
    final parts = timeOfDay.split(':');
    return parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
  }

  String get formattedTime {
    final dt = DateTime(2026, 1, 1, hour, minute);
    return DateFormat('h:mm a').format(dt);
  }

  String get repeatSummary {
    switch (recurrence) {
      case ReminderRecurrence.once:
        return 'Once';
      case ReminderRecurrence.daily:
        return 'Every day';
      case ReminderRecurrence.weekdays:
        return 'Mon - Fri';
      case ReminderRecurrence.weekly:
        return 'Weekly';
      case ReminderRecurrence.monthly:
        return 'Monthly';
      case ReminderRecurrence.custom:
        if (repeatDays.isEmpty) return 'No days selected';
        final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final selected = repeatDays.map((d) => dayNames[(d - 1) % 7]).toList();
        return selected.join(', ');
    }
  }

  /// Returns true if this reminder was completed today (before or after the scheduled time).
  bool get isCompletedToday {
    if (lastCompletedAt == null) return false;
    final now = DateTime.now();
    return lastCompletedAt!.year == now.year &&
        lastCompletedAt!.month == now.month &&
        lastCompletedAt!.day == now.day;
  }

  /// Calculates the next occurrence of this reminder strictly after [from].
  /// If this reminder was already completed today and [ignoreCompletedToday] is false,
  /// the search starts after today so today's completed alarm is not repeated.
  DateTime nextOccurrence(DateTime from, {bool ignoreCompletedToday = false}) {
    DateTime effectiveFrom = from;
    if (isCompletedToday && !ignoreCompletedToday) {
      final endOfToday = DateTime(from.year, from.month, from.day, 23, 59, 59);
      if (endOfToday.isAfter(effectiveFrom)) {
        effectiveFrom = endOfToday;
      }
    }

    DateTime candidate = DateTime(effectiveFrom.year, effectiveFrom.month, effectiveFrom.day, hour, minute);

    switch (recurrence) {
      case ReminderRecurrence.once:
        if (candidate.isAfter(effectiveFrom)) return candidate;
        return candidate.add(const Duration(days: 1));

      case ReminderRecurrence.daily:
        if (candidate.isAfter(effectiveFrom)) return candidate;
        return candidate.add(const Duration(days: 1));

      case ReminderRecurrence.weekdays:
        if (candidate.isAfter(effectiveFrom) && candidate.weekday >= DateTime.monday && candidate.weekday <= DateTime.friday) {
          return candidate;
        }
        do {
          candidate = candidate.add(const Duration(days: 1));
        } while (candidate.weekday == DateTime.saturday || candidate.weekday == DateTime.sunday);
        return candidate;

      case ReminderRecurrence.weekly:
        if (candidate.isAfter(effectiveFrom)) return candidate;
        return candidate.add(const Duration(days: 7));

      case ReminderRecurrence.monthly:
        if (candidate.isAfter(effectiveFrom)) return candidate;
        // next month same day, handling shorter month bounds
        int nextYear = candidate.year;
        int nextMonth = candidate.month + 1;
        if (nextMonth > 12) {
          nextMonth = 1;
          nextYear++;
        }
        int nextDay = candidate.day;
        final daysInNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        if (nextDay > daysInNextMonth) nextDay = daysInNextMonth;
        return DateTime(nextYear, nextMonth, nextDay, hour, minute);

      case ReminderRecurrence.custom:
        if (repeatDays.isEmpty) {
          if (candidate.isAfter(effectiveFrom)) return candidate;
          return candidate.add(const Duration(days: 1));
        }
        for (int i = 0; i < 14; i++) {
          final testDate = candidate.add(Duration(days: i));
          if (testDate.isAfter(effectiveFrom) && repeatDays.contains(testDate.weekday)) {
            return testDate;
          }
        }
        return candidate.add(const Duration(days: 1));
    }
  }

  Reminder copyWith({
    String? id,
    String? title,
    ReminderCategory? category,
    String? timeOfDay,
    bool? isEnabled,
    ReminderRecurrence? recurrence,
    List<int>? repeatDays,
    bool? soundEnabled,
    bool? vibrationEnabled,
    int? snoozeDurationMinutes,
    DateTime? lastTriggeredAt,
    DateTime? lastCompletedAt,
    bool? isDismissed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      isEnabled: isEnabled ?? this.isEnabled,
      recurrence: recurrence ?? this.recurrence,
      repeatDays: repeatDays ?? this.repeatDays,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      snoozeDurationMinutes: snoozeDurationMinutes ?? this.snoozeDurationMinutes,
      lastTriggeredAt: lastTriggeredAt ?? this.lastTriggeredAt,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      isDismissed: isDismissed ?? this.isDismissed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Reminder.fromDb(db.Reminder data) {
    List<int> days = [];
    if (data.repeatDays != null && data.repeatDays!.isNotEmpty) {
      days = data.repeatDays!
          .split(',')
          .map((s) => int.tryParse(s.trim()))
          .whereType<int>()
          .toList();
    }

    return Reminder(
      id: data.id,
      title: data.title,
      category: ReminderCategory.fromString(data.category),
      timeOfDay: data.timeOfDay,
      isEnabled: data.isEnabled,
      recurrence: ReminderRecurrence.fromString(data.recurrence),
      repeatDays: days,
      soundEnabled: data.soundEnabled,
      vibrationEnabled: data.vibrationEnabled,
      snoozeDurationMinutes: data.snoozeDurationMinutes,
      lastTriggeredAt: data.lastTriggeredAt,
      lastCompletedAt: data.lastCompletedAt,
      isDismissed: data.isDismissed,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }

  db.RemindersCompanion toCompanion() {
    return db.RemindersCompanion(
      id: drift.Value(id),
      title: drift.Value(title),
      category: drift.Value(category.dbValue),
      timeOfDay: drift.Value(timeOfDay),
      isEnabled: drift.Value(isEnabled),
      recurrence: drift.Value(recurrence.dbValue),
      repeatDays: drift.Value(repeatDays.isEmpty ? null : repeatDays.join(',')),
      soundEnabled: drift.Value(soundEnabled),
      vibrationEnabled: drift.Value(vibrationEnabled),
      snoozeDurationMinutes: drift.Value(snoozeDurationMinutes),
      lastTriggeredAt: drift.Value(lastTriggeredAt),
      lastCompletedAt: drift.Value(lastCompletedAt),
      isDismissed: drift.Value(isDismissed),
      createdAt: drift.Value(createdAt),
      updatedAt: drift.Value(updatedAt),
    );
  }
}
