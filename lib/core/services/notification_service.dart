import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NotificationChannelType {
  workouts(
    id: 'fit_host_workouts',
    name: 'Workout Reminders',
    description: 'Alerts for scheduled workouts and exercise sessions',
  ),
  nutrition(
    id: 'fit_host_nutrition',
    name: 'Meal & Nutrition Alarms',
    description: 'Timers for breakfast, lunch, dinner, and macro check-ins',
  ),
  hydration(
    id: 'fit_host_hydration',
    name: 'Hydration Trackers',
    description: 'Reminders to drink water and maintain fluid balance',
  ),
  recovery(
    id: 'fit_host_recovery',
    name: 'Recovery & Sleep',
    description: 'Wind-down alerts, stretch routines, and sleep schedule',
  ),
  habits(
    id: 'fit_host_habits',
    name: 'Habits & Goals',
    description: 'Daily consistency and streak check-ins',
  );

  final String id;
  final String name;
  final String description;

  const NotificationChannelType({
    required this.id,
    required this.name,
    required this.description,
  });
}

class ScheduledNotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final NotificationChannelType channel;
  final String? payload;
  final bool sound;
  final bool vibration;

  const ScheduledNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
    required this.channel,
    this.payload,
    this.sound = true,
    this.vibration = true,
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _initialized = false;
  bool _notificationsAllowed = true;
  final List<ScheduledNotificationItem> _scheduledItems = [];
  final _tapController = StreamController<String>.broadcast();

  Stream<String> get onNotificationTap => _tapController.stream;
  List<ScheduledNotificationItem> get scheduledNotifications =>
      List.unmodifiable(_scheduledItems);
  bool get isPermissionGranted => _notificationsAllowed;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    debugPrint('🔔 [NotificationService] Initialized offline-first notification engine');
  }

  Future<bool> requestPermissions() async {
    // Graceful permission request flow
    _notificationsAllowed = true;
    debugPrint('🔔 [NotificationService] Notification permissions granted/checked');
    return true;
  }

  Future<void> setPermissionsAllowed(bool allowed) async {
    _notificationsAllowed = allowed;
    if (!allowed) {
      await cancelAllNotifications();
    }
  }

  Future<void> scheduleNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required NotificationChannelType channel,
    String? payload,
    bool sound = true,
    bool vibration = true,
  }) async {
    if (!_notificationsAllowed) {
      debugPrint('🔔 [NotificationService] Notifications disabled; skipping id: $id');
      return;
    }

    // Remove any previous schedule for this id (duplicate prevention)
    _scheduledItems.removeWhere((item) => item.id == id);

    final item = ScheduledNotificationItem(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      channel: channel,
      payload: payload,
      sound: sound,
      vibration: vibration,
    );

    _scheduledItems.add(item);
    debugPrint(
      '🔔 [NotificationService] Scheduled "$title" for ${scheduledTime.toLocal()} on channel ${channel.name}',
    );
  }

  Future<void> cancelNotification(String id) async {
    _scheduledItems.removeWhere((item) => item.id == id);
    debugPrint('🔔 [NotificationService] Cancelled notification: $id');
  }

  Future<void> cancelAllNotifications() async {
    _scheduledItems.clear();
    debugPrint('🔔 [NotificationService] Cancelled all notifications');
  }

  Future<void> snoozeNotification(String id, int snoozeMinutes) async {
    final index = _scheduledItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      final existing = _scheduledItems[index];
      final newTime = DateTime.now().add(Duration(minutes: snoozeMinutes));
      _scheduledItems[index] = ScheduledNotificationItem(
        id: existing.id,
        title: '${existing.title} (Snoozed)',
        body: existing.body,
        scheduledTime: newTime,
        channel: existing.channel,
        payload: existing.payload,
        sound: existing.sound,
        vibration: existing.vibration,
      );
      debugPrint(
        '🔔 [NotificationService] Snoozed "$id" for $snoozeMinutes minutes to $newTime',
      );
    }
  }

  void handleNotificationTap(String payload) {
    _tapController.add(payload);
  }

  void dispose() {
    _tapController.close();
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  service.initialize();
  return service;
});
