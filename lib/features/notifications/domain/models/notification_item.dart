import 'dart:convert';

enum NotificationCategory {
  workout,
  nutrition,
  hydration,
  stepGoal,
  reminder,
  system,
  general;

  static NotificationCategory fromString(String val) {
    switch (val.toLowerCase()) {
      case 'workout':
        return NotificationCategory.workout;
      case 'nutrition':
        return NotificationCategory.nutrition;
      case 'hydration':
        return NotificationCategory.hydration;
      case 'step_goal':
      case 'stepgoal':
      case 'steps':
        return NotificationCategory.stepGoal;
      case 'reminder':
        return NotificationCategory.reminder;
      case 'system':
        return NotificationCategory.system;
      default:
        return NotificationCategory.general;
    }
  }

  String get dbValue {
    switch (this) {
      case NotificationCategory.workout:
        return 'workout';
      case NotificationCategory.nutrition:
        return 'nutrition';
      case NotificationCategory.hydration:
        return 'hydration';
      case NotificationCategory.stepGoal:
        return 'step_goal';
      case NotificationCategory.reminder:
        return 'reminder';
      case NotificationCategory.system:
        return 'system';
      case NotificationCategory.general:
        return 'general';
    }
  }

  String get label {
    switch (this) {
      case NotificationCategory.workout:
        return 'Workouts';
      case NotificationCategory.nutrition:
        return 'Nutrition';
      case NotificationCategory.hydration:
        return 'Hydration';
      case NotificationCategory.stepGoal:
        return 'Step Goals';
      case NotificationCategory.reminder:
        return 'Reminders';
      case NotificationCategory.system:
        return 'System';
      case NotificationCategory.general:
        return 'General';
    }
  }
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent;

  static NotificationPriority fromString(String val) {
    switch (val.toLowerCase()) {
      case 'urgent':
        return NotificationPriority.urgent;
      case 'high':
        return NotificationPriority.high;
      case 'low':
        return NotificationPriority.low;
      default:
        return NotificationPriority.normal;
    }
  }

  String get dbValue {
    switch (this) {
      case NotificationPriority.urgent:
        return 'urgent';
      case NotificationPriority.high:
        return 'high';
      case NotificationPriority.low:
        return 'low';
      case NotificationPriority.normal:
        return 'normal';
    }
  }
}

class NotificationItem {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationCategory category;
  final String? actionRoute;
  final Map<String, dynamic>? actionPayload;
  final bool isRead;
  final bool isArchived;
  final NotificationPriority priority;
  final DateTime createdAt;
  final DateTime? readAt;

  const NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.category = NotificationCategory.general,
    this.actionRoute,
    this.actionPayload,
    this.isRead = false,
    this.isArchived = false,
    this.priority = NotificationPriority.normal,
    required this.createdAt,
    this.readAt,
  });

  NotificationItem copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationCategory? category,
    String? actionRoute,
    Map<String, dynamic>? actionPayload,
    bool? isRead,
    bool? isArchived,
    NotificationPriority? priority,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      actionRoute: actionRoute ?? this.actionRoute,
      actionPayload: actionPayload ?? this.actionPayload,
      isRead: isRead ?? this.isRead,
      isArchived: isArchived ?? this.isArchived,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'category': category.dbValue,
      'action_route': actionRoute,
      'action_payload': actionPayload != null
          ? jsonEncode(actionPayload)
          : null,
      'is_read': isRead,
      'is_archived': isArchived,
      'priority': priority.dbValue,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? payload;
    if (map['action_payload'] != null) {
      if (map['action_payload'] is Map<String, dynamic>) {
        payload = map['action_payload'] as Map<String, dynamic>;
      } else if (map['action_payload'] is String) {
        try {
          payload =
              jsonDecode(map['action_payload'] as String)
                  as Map<String, dynamic>;
        } catch (_) {}
      }
    }

    return NotificationItem(
      id: map['id'] as String,
      userId: (map['user_id'] ?? 'guest') as String,
      title: map['title'] as String? ?? 'Notification',
      body: map['body'] as String? ?? '',
      category: NotificationCategory.fromString(
        map['category'] as String? ?? 'general',
      ),
      actionRoute: map['action_route'] as String?,
      actionPayload: payload,
      isRead: map['is_read'] as bool? ?? false,
      isArchived: map['is_archived'] as bool? ?? false,
      priority: NotificationPriority.fromString(
        map['priority'] as String? ?? 'normal',
      ),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      readAt: map['read_at'] != null
          ? DateTime.tryParse(map['read_at'].toString())
          : null,
    );
  }
}
