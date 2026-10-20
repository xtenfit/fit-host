import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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

  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  FlutterLocalNotificationsPlugin get plugin => _notificationsPlugin;

  bool _initialized = false;
  bool _notificationsAllowed = true;
  String _quietHoursStart = '22:00';
  String _quietHoursEnd = '07:00';
  bool _quietHoursEnabled = true;
  final List<ScheduledNotificationItem> _scheduledItems = [];
  final _tapController = StreamController<String>.broadcast();

  Stream<String> get onNotificationTap => _tapController.stream;
  List<ScheduledNotificationItem> get scheduledNotifications =>
      List.unmodifiable(_scheduledItems);
  bool get isPermissionGranted => _notificationsAllowed;
  bool get isQuietHoursEnabled => _quietHoursEnabled;
  String get quietHoursStart => _quietHoursStart;
  String get quietHoursEnd => _quietHoursEnd;

  void configureQuietHours({
    required String start,
    required String end,
    bool enabled = true,
  }) {
    _quietHoursStart = start;
    _quietHoursEnd = end;
    _quietHoursEnabled = enabled;
    debugPrint(
      '🔔 [NotificationService] Configured quiet hours: $start - $end (enabled: $enabled)',
    );
  }

  bool isWithinQuietHours(DateTime time) {
    if (!_quietHoursEnabled) return false;
    try {
      final startParts = _parseTimeString(_quietHoursStart);
      final endParts = _parseTimeString(_quietHoursEnd);

      final startMinutes = startParts[0] * 60 + startParts[1];
      final endMinutes = endParts[0] * 60 + endParts[1];
      final timeMinutes = time.hour * 60 + time.minute;

      if (startMinutes <= endMinutes) {
        return timeMinutes >= startMinutes && timeMinutes < endMinutes;
      } else {
        // Overnight interval, e.g. 10:00 PM (22:00) to 7:00 AM (07:00)
        return timeMinutes >= startMinutes || timeMinutes < endMinutes;
      }
    } catch (_) {
      return false;
    }
  }

  List<int> _parseTimeString(String timeStr) {
    final clean = timeStr.trim().toUpperCase();
    final isPm = clean.contains('PM');
    final isAm = clean.contains('AM');
    final parts = clean.replaceAll(RegExp(r'[^\d:]'), '').split(':');
    var hour = int.parse(parts[0]);
    final minute = parts.length > 1 ? int.parse(parts[1]) : 0;
    if (isPm && hour < 12) hour += 12;
    if (isAm && hour == 12) hour = 0;
    return [hour, minute];
  }

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
    } catch (e) {
      debugPrint('[NotificationService] Timezone init info: $e');
    }

    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      try {
        const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
        const darwinInit = DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
        const initSettings = InitializationSettings(
          android: androidInit,
          iOS: darwinInit,
          macOS: darwinInit,
        );

        await _notificationsPlugin.initialize(
          settings: initSettings,
          onDidReceiveNotificationResponse: (NotificationResponse response) {
            if (response.payload != null) {
              handleNotificationTap(response.payload!);
            }
          },
        );

        // Standard Android Notification Channel
        const androidChannel = AndroidNotificationChannel(
          'fit_host_reminders',
          'Fit Host Reminders',
          description:
              'Notifications and alarms for workouts, meals, hydration, and sleep',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );

        // High-Priority Android Alarm Channel with fullScreenIntent support
        const alarmChannel = AndroidNotificationChannel(
          'fit_host_alarms',
          'Fit Host Alarms',
          description:
              'Continuous alarms and reminders with lock-screen alerts',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );

        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidImpl?.createNotificationChannel(androidChannel);
        await androidImpl?.createNotificationChannel(alarmChannel);
      } catch (e) {
        debugPrint('[NotificationService] Native plugin init error: $e');
      }
    }

    _initialized = true;
    debugPrint('🔔 [NotificationService] Initialized Flutter Local Notifications & timezone');
  }

  Future<bool> requestPermissions() async {
    _notificationsAllowed = true;
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      try {
        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);

        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } catch (_) {}
    }
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

    final inQuiet = isWithinQuietHours(scheduledTime);
    final effectiveSound = sound && !inQuiet;
    final effectiveVibration = vibration && !inQuiet;

    if (inQuiet) {
      debugPrint(
        '🌙 [NotificationService] Scheduled "$title" falls in quiet hours. Sound and vibration suppressed.',
      );
    }

    final item = ScheduledNotificationItem(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      channel: channel,
      payload: payload,
      sound: effectiveSound,
      vibration: effectiveVibration,
    );

    _scheduledItems.add(item);

    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      try {
        final notifId = id.hashCode.abs() % 2147483647;
        var targetTime = scheduledTime;
        if (targetTime.isBefore(DateTime.now())) {
          targetTime = DateTime.now().add(const Duration(seconds: 5));
        }
        final scheduledTz = tz.TZDateTime.from(targetTime, tz.local);

        await _notificationsPlugin.zonedSchedule(
          id: notifId,
          title: title,
          body: body,
          scheduledDate: scheduledTz,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              'fit_host_reminders',
              'Fit Host Reminders',
              channelDescription:
                  'Notifications and alarms for workouts, meals, hydration, and sleep',
              importance: Importance.max,
              priority: Priority.high,
              playSound: effectiveSound,
              enableVibration: effectiveVibration,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: effectiveSound,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: payload,
        );
      } catch (e) {
        debugPrint('[NotificationService] zonedSchedule error: $e');
      }
    }

    debugPrint(
      '🔔 [NotificationService] Scheduled "$title" for ${scheduledTime.toLocal()} on channel ${channel.name}',
    );
  }

  /// High-priority full-screen alarm with continuous alert attributes
  Future<void> scheduleAlarm({
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
      debugPrint('🔔 [NotificationService] Notifications disabled; skipping alarm: $id');
      return;
    }

    _scheduledItems.removeWhere((item) => item.id == id);

    final inQuiet = isWithinQuietHours(scheduledTime);
    final effectiveSound = sound && !inQuiet;
    final effectiveVibration = vibration && !inQuiet;

    final alarmPayload = payload ??
        '/alarm?id=${Uri.encodeComponent(id)}&title=${Uri.encodeComponent(title)}&body=${Uri.encodeComponent(body)}&channel=${channel.name}';

    final item = ScheduledNotificationItem(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      channel: channel,
      payload: alarmPayload,
      sound: effectiveSound,
      vibration: effectiveVibration,
    );

    _scheduledItems.add(item);

    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      try {
        final notifId = id.hashCode.abs() % 2147483647;
        var targetTime = scheduledTime;
        if (targetTime.isBefore(DateTime.now())) {
          targetTime = DateTime.now().add(const Duration(seconds: 5));
        }
        final scheduledTz = tz.TZDateTime.from(targetTime, tz.local);

        await _notificationsPlugin.zonedSchedule(
          id: notifId,
          title: title,
          body: body,
          scheduledDate: scheduledTz,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              'fit_host_alarms',
              'Fit Host Alarms',
              channelDescription:
                  'Continuous alarms and reminders with lock-screen alerts',
              importance: Importance.max,
              priority: Priority.max,
              fullScreenIntent: true,
              category: AndroidNotificationCategory.alarm,
              audioAttributesUsage: AudioAttributesUsage.alarm,
              playSound: effectiveSound,
              enableVibration: effectiveVibration,
              visibility: NotificationVisibility.public,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: effectiveSound,
              interruptionLevel: InterruptionLevel.critical,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: alarmPayload,
        );
      } catch (e) {
        debugPrint('[NotificationService] zonedSchedule alarm error: $e');
      }
    }

    debugPrint(
      '🚨 [NotificationService] Scheduled FULLSCREEN ALARM "$title" for ${scheduledTime.toLocal()} on channel ${channel.name}',
    );
  }

  Future<void> cancelNotification(String id) async {
    _scheduledItems.removeWhere((item) => item.id == id);
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      try {
        final notifId = id.hashCode.abs() % 2147483647;
        await _notificationsPlugin.cancel(id: notifId);
      } catch (_) {}
    }
    debugPrint('🔔 [NotificationService] Cancelled notification: $id');
  }

  Future<void> cancelAllNotifications() async {
    _scheduledItems.clear();
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      try {
        await _notificationsPlugin.cancelAll();
      } catch (_) {}
    }
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

      await scheduleAlarm(
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
        '🔔 [NotificationService] Snoozed "$id" for $snoozeMinutes minutes to $newTime with full alarm popup',
      );
    } else {
      final newTime = DateTime.now().add(Duration(minutes: snoozeMinutes));
      await scheduleAlarm(
        id: id,
        title: 'Fit Host Reminder (Snoozed)',
        body: 'Snoozed health reminder',
        scheduledTime: newTime,
        channel: NotificationChannelType.habits,
      );
      debugPrint(
        '🔔 [NotificationService] Fallback Snoozed "$id" for $snoozeMinutes minutes to $newTime',
      );
    }
  }

  /// Helper to test 1-minute background notification execution with ringing popup
  Future<void> testOneMinuteTimer() async {
    final fireTime = DateTime.now().add(const Duration(minutes: 1));
    await scheduleAlarm(
      id: 'test_1_min_timer',
      title: 'Fit Host 1-Min Alarm Test',
      body: 'Your 1-minute reminder test completed successfully! Ringing alarm active.',
      scheduledTime: fireTime,
      channel: NotificationChannelType.habits,
      payload:
          '/alarm?id=test_1_min_timer&title=${Uri.encodeComponent('Fit Host 1-Min Test')}&body=${Uri.encodeComponent('1-minute alarm test fired')}&channel=habits',
    );
  }

  /// Checks if the app was launched by tapping an alarm/notification when closed
  Future<String?> getInitialPayload() async {
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      try {
        final details = await _notificationsPlugin.getNotificationAppLaunchDetails();
        if (details != null &&
            details.didNotificationLaunchApp &&
            details.notificationResponse?.payload != null) {
          return details.notificationResponse!.payload;
        }
      } catch (e) {
        debugPrint('[NotificationService] getInitialPayload error: $e');
      }
    }
    return null;
  }

  void handleNotificationTap(String payload) {
    _tapController.add(payload);
  }

  void dispose() {
    _tapController.close();
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService.instance;
  service.initialize();
  return service;
});
