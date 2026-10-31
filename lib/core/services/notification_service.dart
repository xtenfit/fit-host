import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  ),
  reminders(
    id: 'fit_host_reminders',
    name: 'Fit Host Reminders',
    description: 'General fitness alarms, workouts, and reminders',
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

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint(
    '🚨 [NotificationService] Background action: ${response.actionId}, id: ${response.id}, payload: ${response.payload}',
  );

  if (response.actionId == 'snooze_action') {
    final payload = response.payload;
    if (payload != null) {
      final uri = Uri.tryParse(payload);
      final id = uri?.queryParameters['id'] ?? 'snooze_${response.id}';
      final snoozeMins =
          int.tryParse(uri?.queryParameters['snoozeMinutes'] ?? '') ?? 10;
      final title = uri?.queryParameters['title'] ?? 'Fit Host Alarm';
      final channelName = uri?.queryParameters['channel'] ?? 'workouts';

      await NotificationService.instance.snoozeAlarmDirect(
        id: id,
        title: title,
        body: 'Snoozed alarm ($snoozeMins mins)',
        snoozeMinutes: snoozeMins,
        channelName: channelName,
      );
    }
  } else if (response.actionId == 'complete_action') {
    if (response.id != null) {
      await FlutterLocalNotificationsPlugin().cancel(id: response.id!);
    }
    final payload = response.payload;
    if (payload != null) {
      final uri = Uri.tryParse(payload);
      final id = uri?.queryParameters['id'] ?? payload;
      NotificationService.instance.handleNotificationAction('complete', id);
    }
  } else if (response.actionId == 'dismiss_action') {
    if (response.id != null) {
      await FlutterLocalNotificationsPlugin().cancel(id: response.id!);
    }
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static NotificationService get instance => _instance;

  static const String keyWizardSkipReminderId = 'setup_wizard_skip_reminder';
  static const String keyWizardFollowupReminderId =
      'setup_wizard_reminder_followup';

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  FlutterLocalNotificationsPlugin get plugin => _notificationsPlugin;

  bool _initialized = false;
  Future<void>? _initializationFuture;
  bool _notificationsAllowed = true;
  bool _fullScreenPermissionRequested = false;
  String _quietHoursStart = '22:00';
  String _quietHoursEnd = '07:00';
  bool _quietHoursEnabled = true;
  final List<ScheduledNotificationItem> _scheduledItems = [];
  final _tapController = StreamController<String>.broadcast();
  final _alarmActionController =
      StreamController<Map<String, String>>.broadcast();

  Stream<String> get onNotificationTap => _tapController.stream;
  Stream<Map<String, String>> get onAlarmAction =>
      _alarmActionController.stream;
  List<ScheduledNotificationItem> get scheduledNotifications =>
      List.unmodifiable(_scheduledItems);
  bool get isPermissionGranted => _notificationsAllowed;
  bool get isQuietHoursEnabled => _quietHoursEnabled;
  String get quietHoursStart => _quietHoursStart;
  String get quietHoursEnd => _quietHoursEnd;

  void handleNotificationAction(String action, String id) {
    _alarmActionController.add({'action': action, 'id': id});
  }

  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await androidImpl?.areNotificationsEnabled() ?? true;
    } catch (e) {
      debugPrint('[NotificationService] Notification state check failed: $e');
      return false;
    }
  }

  Future<AndroidNotificationChannel?> getAlarmChannel() async {
    if (kIsWeb || !Platform.isAndroid) return null;
    try {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final channels = await androidImpl?.getNotificationChannels() ?? const [];
      for (final channel in channels) {
        if (channel.id == 'fit_host_alarms_v4' ||
            channel.id == 'fit_host_alarms_v3' ||
            channel.id == 'fit_host_alarms_v2' ||
            channel.id == 'fit_host_alarms') {
          return channel;
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] Alarm channel check failed: $e');
    }
    return null;
  }

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

  Future<void> initialize() {
    if (_initialized) return Future<void>.value();
    final pending = _initializationFuture;
    if (pending != null) return pending;
    final future = _initializeInternal();
    _initializationFuture = future;
    return future;
  }

  Future<void> _initializeInternal() async {
    try {
      tz.initializeTimeZones();
    } catch (e) {
      debugPrint('[NotificationService] Timezone init info: $e');
    }

    final isTest = WidgetsBinding.instance.runtimeType.toString().contains(
      'Test',
    );
    if (!isTest) {
      try {
        const androidInit = AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        );
        const darwinInit = DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );
        const initSettings = InitializationSettings(
          android: androidInit,
          iOS: darwinInit,
          macOS: darwinInit,
        );

        await _notificationsPlugin.initialize(
          settings: initSettings,
          onDidReceiveNotificationResponse: (NotificationResponse response) {
            if (response.actionId == 'snooze_action') {
              final payload = response.payload;
              if (payload != null) {
                final uri = Uri.tryParse(payload);
                final id = uri?.queryParameters['id'] ?? payload;
                final snoozeMins =
                    int.tryParse(uri?.queryParameters['snoozeMinutes'] ?? '') ??
                    10;
                snoozeNotification(id, snoozeMins);
              }
            } else if (response.actionId == 'complete_action') {
              final payload = response.payload;
              if (payload != null) {
                final uri = Uri.tryParse(payload);
                final id = uri?.queryParameters['id'] ?? payload;
                cancelNotification(id);
                handleNotificationAction('complete', id);
              }
            } else if (response.actionId == 'dismiss_action') {
              if (response.payload != null) {
                final uri = Uri.tryParse(response.payload!);
                final id = uri?.queryParameters['id'] ?? response.payload!;
                cancelNotification(id);
              }
            } else if (response.payload != null) {
              handleNotificationTap(response.payload!);
            }
          },
          onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
        );

        // Standard Android Activity Notification Channel v2
        const standardChannelV2 = AndroidNotificationChannel(
          'fit_host_notifications_v3',
          'Fit Host Activity Reminders',
          description:
              'Notifications for workouts, meals, hydration, and sleep',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        );

        // High-Priority Android Alarm Channel v4 with raw alarm ringtone, looping sound & vibration
        final alarmChannelV4 = AndroidNotificationChannel(
          'fit_host_alarms_v4',
          'Fit Host Alarms & Reminders',
          description:
              'High-priority alarms and reminders with continuous ringing, vibration, and lock-screen alerts',
          importance: Importance.max,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('fit_host_alarm'),
          enableVibration: true,
          vibrationPattern: Int64List.fromList(<int>[
            0,
            1000,
            500,
            1000,
            500,
            1000,
            500,
          ]),
          audioAttributesUsage: AudioAttributesUsage.alarm,
        );

        // Legacy channels for seamless backward compatibility
        const alarmChannelV2 = AndroidNotificationChannel(
          'fit_host_alarms_v3',
          'Fit Host Alarms & Reminders (v3)',
          description: 'Legacy alarm channel',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        );
        const legacyReminderChannel = AndroidNotificationChannel(
          'fit_host_reminders',
          'Fit Host Reminders (Legacy)',
          description: 'Legacy notification channel',
          importance: Importance.high,
        );
        const legacyAlarmChannel = AndroidNotificationChannel(
          'fit_host_alarms',
          'Fit Host Alarms (Legacy)',
          description: 'Legacy alarm channel',
          importance: Importance.max,
        );

        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        await androidImpl?.createNotificationChannel(alarmChannelV4);
        await androidImpl?.createNotificationChannel(standardChannelV2);
        await androidImpl?.createNotificationChannel(alarmChannelV2);
        await androidImpl?.createNotificationChannel(legacyReminderChannel);
        await androidImpl?.createNotificationChannel(legacyAlarmChannel);
      } catch (e) {
        debugPrint('[NotificationService] Native plugin init error: $e');
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationsAllowed =
          prefs.getBool('notification_master_enabled') ?? true;
    } catch (_) {}

    _initialized = true;
    debugPrint(
      '🔔 [NotificationService] Initialized Flutter Local Notifications & timezone (allowed: $_notificationsAllowed)',
    );
  }

  /// 32-bit FNV-1a hash to guarantee 100% deterministic integer ID across process restarts and VM reboots
  static int toNotificationId(String id) {
    var hash = 0x811c9dc5;
    for (var i = 0; i < id.length; i++) {
      hash ^= id.codeUnitAt(i);
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash & 0x7FFFFFFF;
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  Future<bool> requestPermissions() async {
    _notificationsAllowed = true;
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains(
      'Test',
    );
    if (!isTest) {
      try {
        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);

        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();

        if (Platform.isAndroid) {
          final fullScreenGranted = await _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestFullScreenIntentPermission();
          debugPrint(
            '[NotificationService] Full-screen alarm permission: '
            '${fullScreenGranted == true ? 'granted' : 'not granted'}',
          );
          _fullScreenPermissionRequested = true;
        }
      } catch (_) {}
    }
    return true;
  }

  Future<bool> canScheduleExactAlarms() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      return await Permission.scheduleExactAlarm.isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<void> setPermissionsAllowed(bool allowed) async {
    _notificationsAllowed = allowed;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notification_master_enabled', allowed);
    } catch (_) {}
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
    int snoozeMinutes = 10,
    bool sound = true,
    bool vibration = true,
  }) async {
    await _ensureInitialized();
    if (!_notificationsAllowed) {
      debugPrint(
        '🔔 [NotificationService] Notifications disabled; skipping id: $id',
      );
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

    final effectivePayload =
        payload ??
        '/notifications?id=${Uri.encodeComponent(id)}&title=${Uri.encodeComponent(title)}&channel=${channel.name}&snoozeMinutes=$snoozeMinutes';

    final item = ScheduledNotificationItem(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      channel: channel,
      payload: effectivePayload,
      sound: effectiveSound,
      vibration: effectiveVibration,
    );

    _scheduledItems.add(item);

    final isTest = WidgetsBinding.instance.runtimeType.toString().contains(
      'Test',
    );
    if (!isTest) {
      try {
        final notifId = toNotificationId(id);
        var targetTime = scheduledTime;
        if (targetTime.isBefore(DateTime.now())) {
          targetTime = DateTime.now().add(const Duration(seconds: 5));
        }
        final scheduledTz = tz.TZDateTime.from(targetTime, tz.local);

        final canExact = await canScheduleExactAlarms();
        final scheduleMode = canExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle;

        await _notificationsPlugin.zonedSchedule(
          id: notifId,
          title: title,
          body: body,
          scheduledDate: scheduledTz,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              'fit_host_notifications_v3',
              'Fit Host Activity Reminders',
              channelDescription:
                  'Notifications for workouts, meals, hydration, and sleep',
              importance: Importance.high,
              priority: Priority.high,
              category: AndroidNotificationCategory.reminder,
              audioAttributesUsage: AudioAttributesUsage.notification,
              playSound: effectiveSound,
              enableVibration: effectiveVibration,
              visibility: NotificationVisibility.public,
              actions: <AndroidNotificationAction>[
                AndroidNotificationAction(
                  'snooze_action',
                  'Snooze ${snoozeMinutes}m',
                  showsUserInterface: false,
                  cancelNotification: true,
                ),
                const AndroidNotificationAction(
                  'dismiss_action',
                  'Dismiss',
                  showsUserInterface: false,
                  cancelNotification: true,
                ),
              ],
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: effectiveSound,
              interruptionLevel: InterruptionLevel.timeSensitive,
            ),
          ),
          androidScheduleMode: scheduleMode,
          payload: effectivePayload,
        );
      } catch (e) {
        debugPrint('[NotificationService] zonedSchedule error: $e');
      }
    }

    debugPrint(
      '🔔 [NotificationService] Scheduled "$title" for ${scheduledTime.toLocal()} on channel ${channel.name}',
    );
  }

  /// High-priority full-screen alarm with sound, vibration, and actionable buttons
  Future<void> scheduleAlarm({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required NotificationChannelType channel,
    String? payload,
    int snoozeMinutes = 10,
    bool sound = true,
    bool vibration = true,
  }) async {
    await _ensureInitialized();
    if (!_notificationsAllowed) {
      debugPrint(
        '🔔 [NotificationService] Notifications disabled; skipping alarm: $id',
      );
      return;
    }

    _scheduledItems.removeWhere((item) => item.id == id);

    final inQuiet = isWithinQuietHours(scheduledTime);
    final effectiveSound = sound && !inQuiet;
    final effectiveVibration = vibration && !inQuiet;

    final alarmPayload =
        payload ??
        '/alarm?id=${Uri.encodeComponent(id)}&title=${Uri.encodeComponent(title)}&body=${Uri.encodeComponent(body)}&channel=${channel.name}&snoozeMinutes=$snoozeMinutes';

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

    final isTest = WidgetsBinding.instance.runtimeType.toString().contains(
      'Test',
    );
    if (!isTest) {
      try {
        final notifId = toNotificationId(id);
        var targetTime = scheduledTime;
        if (targetTime.isBefore(DateTime.now())) {
          targetTime = DateTime.now().add(const Duration(seconds: 5));
        }
        final scheduledTz = tz.TZDateTime.from(targetTime, tz.local);

        final canExact = await canScheduleExactAlarms();

        final scheduleMode = canExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle;

        if (!canExact) {
          debugPrint(
            '🔔 [NotificationService] Exact timing unavailable; using standard notification delivery.',
          );
        }

        if (Platform.isAndroid && !_fullScreenPermissionRequested) {
          final fullScreenGranted = await _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestFullScreenIntentPermission();
          _fullScreenPermissionRequested = true;
          if (fullScreenGranted != true) {
            debugPrint(
              '[NotificationService] Full-screen alarm permission is not granted; '
              'Android may show a notification instead of opening the alarm screen.',
            );
          }
        }

        await _notificationsPlugin.zonedSchedule(
          id: notifId,
          title: title,
          body: body,
          scheduledDate: scheduledTz,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              'fit_host_alarms_v4',
              'Fit Host Alarms & Reminders',
              channelDescription:
                  'High-priority alarms and reminders with continuous ringing, vibration, and lock-screen alerts',
              importance: Importance.max,
              priority: Priority.max,
              fullScreenIntent: true,
              category: AndroidNotificationCategory.alarm,
              audioAttributesUsage: AudioAttributesUsage.alarm,
              sound: const RawResourceAndroidNotificationSound(
                'fit_host_alarm',
              ),
              playSound: effectiveSound,
              enableVibration: effectiveVibration,
              vibrationPattern: Int64List.fromList(<int>[
                0,
                1000,
                500,
                1000,
                500,
                1000,
                500,
              ]),
              additionalFlags: Int32List.fromList(
                <int>[4],
              ), // Notification.FLAG_INSISTENT: loops alarm ringing continuously!
              timeoutAfter:
                  60000, // 60s (1 min) timeout: automatically stops ringing if not snoozed or dismissed!
              visibility: NotificationVisibility.public,
              actions: <AndroidNotificationAction>[
                AndroidNotificationAction(
                  'snooze_action',
                  'Snooze ${snoozeMinutes}m',
                  showsUserInterface: false,
                  cancelNotification: true,
                ),
                const AndroidNotificationAction(
                  'complete_action',
                  'Mark Complete ✓',
                  showsUserInterface: false,
                  cancelNotification: true,
                ),
                const AndroidNotificationAction(
                  'dismiss_action',
                  'Dismiss',
                  showsUserInterface: false,
                  cancelNotification: true,
                ),
                const AndroidNotificationAction(
                  'open_action',
                  'Open Alarm',
                  showsUserInterface: true,
                ),
              ],
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: effectiveSound,
              interruptionLevel: InterruptionLevel.timeSensitive,
            ),
          ),
          androidScheduleMode: scheduleMode,
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

  Future<void> showImmediateNotification({
    required String id,
    required String title,
    required String body,
    required NotificationChannelType channel,
    String? payload,
    bool sound = true,
    bool vibration = true,
  }) async {
    await _ensureInitialized();
    if (!_notificationsAllowed) return;

    final inQuiet = isWithinQuietHours(DateTime.now());
    final effectiveSound = sound && !inQuiet;
    final effectiveVibration = vibration && !inQuiet;

    final item = ScheduledNotificationItem(
      id: id,
      title: title,
      body: body,
      scheduledTime: DateTime.now(),
      channel: channel,
      payload: payload,
      sound: effectiveSound,
      vibration: effectiveVibration,
    );

    _scheduledItems.add(item);

    final isTest = WidgetsBinding.instance.runtimeType.toString().contains(
      'Test',
    );
    if (!isTest) {
      try {
        final notifId = toNotificationId(id);
        await _notificationsPlugin.show(
          id: notifId,
          title: title,
          body: body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              'fit_host_reminders',
              'Fit Host Reminders',
              channelDescription:
                  'Notifications and alarms for workouts, meals, hydration, and setup',
              importance: Importance.max,
              priority: Priority.high,
              playSound: effectiveSound,
              enableVibration: effectiveVibration,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: effectiveSound,
              interruptionLevel: InterruptionLevel.timeSensitive,
            ),
          ),
          payload: payload,
        );
      } catch (e) {
        debugPrint('[NotificationService] show error: $e');
      }
    }
    debugPrint(
      '🔔 [NotificationService] Displayed immediate notification "$title"',
    );
  }

  Future<void> cancelNotification(String id) async {
    _scheduledItems.removeWhere((item) => item.id == id);
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains(
      'Test',
    );
    if (!isTest) {
      final deterministicId = toNotificationId(id);
      final legacyHashCodeId = id.hashCode.abs() % 2147483647;
      try {
        await _notificationsPlugin.cancel(id: deterministicId);
      } catch (_) {
        try {
          await (_notificationsPlugin as dynamic).cancel(deterministicId);
        } catch (_) {}
      }
      if (legacyHashCodeId != deterministicId) {
        try {
          await _notificationsPlugin.cancel(id: legacyHashCodeId);
        } catch (_) {
          try {
            await (_notificationsPlugin as dynamic).cancel(legacyHashCodeId);
          } catch (_) {}
        }
      }
    }
    debugPrint('🔔 [NotificationService] Cancelled notification: $id');
  }

  /// Cancels any pending setup wizard reminder notifications for existing accounts or completed setups
  Future<void> cancelWizardSetupNotifications() async {
    try {
      await cancelNotification(keyWizardSkipReminderId);
      await cancelNotification(keyWizardFollowupReminderId);
      debugPrint(
        '🔔 [NotificationService] Cancelled wizard setup reminder notifications',
      );
    } catch (e) {
      debugPrint(
        '[NotificationService] Cancel wizard setup notifications error: $e',
      );
    }
  }

  Future<void> cancelAllNotifications() async {
    _scheduledItems.clear();
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains(
      'Test',
    );
    if (!isTest) {
      try {
        await _notificationsPlugin.cancelAll();
      } catch (_) {}
    }
    debugPrint('🔔 [NotificationService] Cancelled all notifications');
  }

  Future<void> snoozeNotification(String id, int snoozeMinutes) async {
    final existingIndex = _scheduledItems.indexWhere((item) => item.id == id);
    ScheduledNotificationItem? existing;
    if (existingIndex != -1) {
      existing = _scheduledItems[existingIndex];
      _scheduledItems.removeAt(existingIndex);
    }

    final fireTime = DateTime.now().add(Duration(minutes: snoozeMinutes));
    final title = existing?.title ?? 'Fit Host Reminder';
    final body = existing?.body ?? 'Snoozed alert ($snoozeMinutes min)';
    final channel = existing?.channel ?? NotificationChannelType.workouts;
    final sound = existing?.sound ?? true;
    final vibration = existing?.vibration ?? true;

    await cancelNotification(id);

    await scheduleAlarm(
      id: id,
      title: title,
      body: body,
      scheduledTime: fireTime,
      channel: channel,
      snoozeMinutes: snoozeMinutes,
      sound: sound,
      vibration: vibration,
    );

    debugPrint(
      '🚨 [NotificationService] Reminder "$id" snoozed for $snoozeMinutes minutes until ${fireTime.toLocal()}',
    );
  }

  Future<void> snoozeAlarmDirect({
    required String id,
    required String title,
    required String body,
    required int snoozeMinutes,
    String channelName = 'workouts',
  }) async {
    final channel = NotificationChannelType.values.firstWhere(
      (c) => c.name.toLowerCase() == channelName.toLowerCase(),
      orElse: () => NotificationChannelType.workouts,
    );
    final targetTime = DateTime.now().add(Duration(minutes: snoozeMinutes));
    await scheduleAlarm(
      id: id,
      title: title,
      body: body,
      scheduledTime: targetTime,
      channel: channel,
      snoozeMinutes: snoozeMinutes,
    );
  }

  /// Helper to test 10-second background alarm execution with ringing popup
  Future<void> testTenSecondAlarm() async {
    final fireTime = DateTime.now().add(const Duration(seconds: 10));
    await scheduleAlarm(
      id: 'test_10s_alarm_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Fit Host 10-Second Test Alarm',
      body:
          'Verified: Real Android alarm fired on schedule with sound & vibration!',
      scheduledTime: fireTime,
      channel: NotificationChannelType.workouts,
      snoozeMinutes: 5,
    );
  }

  /// Helper to test 1-minute background notification execution with ringing popup
  Future<void> testOneMinuteTimer() async {
    final fireTime = DateTime.now().add(const Duration(minutes: 1));
    await scheduleAlarm(
      id: 'test_1_min_timer',
      title: 'Fit Host 1-Min Alarm Test',
      body:
          'Your 1-minute reminder test completed successfully! Ringing alarm active.',
      scheduledTime: fireTime,
      channel: NotificationChannelType.habits,
      payload:
          '/alarm?id=test_1_min_timer&title=${Uri.encodeComponent('Fit Host 1-Min Test')}&body=${Uri.encodeComponent('1-minute alarm test fired')}&channel=habits',
    );
  }

  /// Checks if the app was launched by tapping an alarm/notification when closed
  Future<String?> getInitialPayload() async {
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains(
      'Test',
    );
    if (!isTest) {
      try {
        final details = await _notificationsPlugin
            .getNotificationAppLaunchDetails();
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
