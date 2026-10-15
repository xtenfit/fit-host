import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../core/database/database.dart' as db;
import '../../../../core/theme/app_colors.dart';

enum CalendarEventType {
  workout(label: 'Workout', icon: Icons.fitness_center_rounded, color: AppColors.electricBlue),
  restDay(label: 'Rest Day', icon: Icons.spa_rounded, color: AppColors.limeGreen),
  meal(label: 'Meal / Nutrition', icon: Icons.restaurant_rounded, color: Color(0xFFFF6B4A)),
  hydration(label: 'Hydration', icon: Icons.water_drop_rounded, color: Color(0xFF00B4D8)),
  sleep(label: 'Sleep & Recovery', icon: Icons.bedtime_rounded, color: Color(0xFF9D4EDD)),
  weighIn(label: 'Weigh-in', icon: Icons.monitor_weight_rounded, color: Color(0xFFE0AAFF)),
  custom(label: 'Custom Activity', icon: Icons.star_rounded, color: Color(0xFFFFD166));

  final String label;
  final IconData icon;
  final Color color;

  const CalendarEventType({
    required this.label,
    required this.icon,
    required this.color,
  });

  static CalendarEventType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'workout':
        return CalendarEventType.workout;
      case 'rest_day':
      case 'restday':
        return CalendarEventType.restDay;
      case 'meal':
        return CalendarEventType.meal;
      case 'hydration':
        return CalendarEventType.hydration;
      case 'sleep':
        return CalendarEventType.sleep;
      case 'weigh_in':
      case 'weighin':
        return CalendarEventType.weighIn;
      default:
        return CalendarEventType.custom;
    }
  }

  String get dbValue {
    switch (this) {
      case CalendarEventType.workout:
        return 'workout';
      case CalendarEventType.restDay:
        return 'rest_day';
      case CalendarEventType.meal:
        return 'meal';
      case CalendarEventType.hydration:
        return 'hydration';
      case CalendarEventType.sleep:
        return 'sleep';
      case CalendarEventType.weighIn:
        return 'weigh_in';
      case CalendarEventType.custom:
        return 'custom';
    }
  }
}

enum RecurrenceRule {
  none(label: 'Does not repeat'),
  daily(label: 'Daily'),
  weekly(label: 'Weekly'),
  weekdays(label: 'Weekdays (Mon-Fri)'),
  monthly(label: 'Monthly');

  final String label;
  const RecurrenceRule({required this.label});

  static RecurrenceRule fromString(String val) {
    switch (val.toLowerCase()) {
      case 'daily':
        return RecurrenceRule.daily;
      case 'weekly':
        return RecurrenceRule.weekly;
      case 'weekdays':
        return RecurrenceRule.weekdays;
      case 'monthly':
        return RecurrenceRule.monthly;
      default:
        return RecurrenceRule.none;
    }
  }

  String get dbValue {
    switch (this) {
      case RecurrenceRule.daily:
        return 'daily';
      case RecurrenceRule.weekly:
        return 'weekly';
      case RecurrenceRule.weekdays:
        return 'weekdays';
      case RecurrenceRule.monthly:
        return 'monthly';
      case RecurrenceRule.none:
        return 'none';
    }
  }
}

class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final CalendarEventType eventType;
  final DateTime scheduledDate;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isCompleted;
  final bool isMissed;
  final RecurrenceRule recurrenceRule;
  final Map<String, dynamic>? targetMetrics;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.eventType,
    required this.scheduledDate,
    this.startTime,
    this.endTime,
    this.isCompleted = false,
    this.isMissed = false,
    this.recurrenceRule = RecurrenceRule.none,
    this.targetMetrics,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'pending',
  });

  bool get isPast {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scheduled = DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day);
    return scheduled.isBefore(today);
  }

  bool get isToday {
    final now = DateTime.now();
    return scheduledDate.year == now.year &&
        scheduledDate.month == now.month &&
        scheduledDate.day == now.day;
  }

  String get statusDisplay {
    if (isCompleted) return 'Completed';
    if (isMissed || (isPast && !isCompleted)) return 'Missed';
    if (isToday) return 'Today';
    return 'Upcoming';
  }

  Color get statusColor {
    if (isCompleted) return AppColors.limeGreen;
    if (isMissed || (isPast && !isCompleted)) return const Color(0xFFFF5252);
    if (isToday) return AppColors.electricBlue;
    return const Color(0xFF9E9E9E);
  }

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    CalendarEventType? eventType,
    DateTime? scheduledDate,
    DateTime? startTime,
    DateTime? endTime,
    bool? isCompleted,
    bool? isMissed,
    RecurrenceRule? recurrenceRule,
    Map<String, dynamic>? targetMetrics,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      eventType: eventType ?? this.eventType,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isCompleted: isCompleted ?? this.isCompleted,
      isMissed: isMissed ?? this.isMissed,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      targetMetrics: targetMetrics ?? this.targetMetrics,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  factory CalendarEvent.fromDb(db.CalendarEvent data) {
    Map<String, dynamic>? metrics;
    if (data.targetMetrics != null && data.targetMetrics!.isNotEmpty) {
      try {
        metrics = jsonDecode(data.targetMetrics!) as Map<String, dynamic>;
      } catch (_) {}
    }

    return CalendarEvent(
      id: data.id,
      title: data.title,
      description: data.description,
      eventType: CalendarEventType.fromString(data.eventType),
      scheduledDate: data.scheduledDate,
      startTime: data.startTime,
      endTime: data.endTime,
      isCompleted: data.isCompleted,
      isMissed: data.isMissed,
      recurrenceRule: RecurrenceRule.fromString(data.recurrenceRule),
      targetMetrics: metrics,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      syncStatus: data.syncStatus,
    );
  }

  db.CalendarEventsCompanion toCompanion() {
    return db.CalendarEventsCompanion(
      id: drift.Value(id),
      title: drift.Value(title),
      description: drift.Value(description),
      eventType: drift.Value(eventType.dbValue),
      scheduledDate: drift.Value(scheduledDate),
      startTime: drift.Value(startTime),
      endTime: drift.Value(endTime),
      isCompleted: drift.Value(isCompleted),
      isMissed: drift.Value(isMissed),
      recurrenceRule: drift.Value(recurrenceRule.dbValue),
      targetMetrics: drift.Value(targetMetrics != null ? jsonEncode(targetMetrics) : null),
      createdAt: drift.Value(createdAt),
      updatedAt: drift.Value(updatedAt),
      syncStatus: drift.Value(syncStatus),
    );
  }
}
