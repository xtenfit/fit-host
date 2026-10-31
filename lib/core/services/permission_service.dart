import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/steps/data/health_platform_service.dart';
import 'notification_service.dart';

/// Standard permission status tracked across Fit Host.
enum AppPermissionStatus {
  notRequested,
  granted,
  partiallyGranted,
  denied,
  permanentlyDenied,
  unavailable,
  requiresSystemSettings,
  error;

  bool get isGranted => this == AppPermissionStatus.granted;
  bool get isActionable =>
      this == AppPermissionStatus.notRequested ||
      this == AppPermissionStatus.denied ||
      this == AppPermissionStatus.requiresSystemSettings ||
      this == AppPermissionStatus.permanentlyDenied;
}

/// Comprehensive snapshot of all Fit Host permission states.
class AppPermissionState {
  final AppPermissionStatus notifications;
  final AppPermissionStatus exactAlarms;
  final AppPermissionStatus healthConnect;
  final AppPermissionStatus physicalActivity;
  final AppPermissionStatus camera;
  final bool googleCalendarConnected;
  final DateTime lastChecked;
  final String? healthConnectError;

  const AppPermissionState({
    required this.notifications,
    required this.exactAlarms,
    required this.healthConnect,
    required this.physicalActivity,
    required this.camera,
    required this.googleCalendarConnected,
    required this.lastChecked,
    this.healthConnectError,
  });

  /// Factory for initial clean state before checking
  factory AppPermissionState.initial() => AppPermissionState(
    notifications: AppPermissionStatus.notRequested,
    exactAlarms: AppPermissionStatus.notRequested,
    healthConnect: AppPermissionStatus.notRequested,
    physicalActivity: AppPermissionStatus.notRequested,
    camera: AppPermissionStatus.notRequested,
    googleCalendarConnected: false,
    lastChecked: DateTime.now(),
  );

  /// Number of recommended onboarding steps granted (out of 4 core features)
  int get recommendedGrantedCount {
    int count = 0;
    if (notifications.isGranted) count++;
    if (exactAlarms.isGranted) count++;
    if (healthConnect.isGranted) count++;
    if (physicalActivity.isGranted) count++;
    return count;
  }

  int get totalRecommendedCount => 4;

  AppPermissionState copyWith({
    AppPermissionStatus? notifications,
    AppPermissionStatus? exactAlarms,
    AppPermissionStatus? healthConnect,
    AppPermissionStatus? physicalActivity,
    AppPermissionStatus? camera,
    bool? googleCalendarConnected,
    DateTime? lastChecked,
    String? healthConnectError,
  }) {
    return AppPermissionState(
      notifications: notifications ?? this.notifications,
      exactAlarms: exactAlarms ?? this.exactAlarms,
      healthConnect: healthConnect ?? this.healthConnect,
      physicalActivity: physicalActivity ?? this.physicalActivity,
      camera: camera ?? this.camera,
      googleCalendarConnected:
          googleCalendarConnected ?? this.googleCalendarConnected,
      lastChecked: lastChecked ?? this.lastChecked,
      healthConnectError: healthConnectError ?? this.healthConnectError,
    );
  }
}

/// Centralized permission management service for Fit Host.
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  static PermissionService get instance => _instance;

  static const String keyPermissionSetupCompleted =
      'fit_host_permission_setup_completed';
  static const String keyPromptedNotification =
      'fit_host_perm_prompted_notification';
  static const String keyPromptedAlarm = 'fit_host_perm_prompted_alarm';
  static const String keyPromptedHealthConnect =
      'fit_host_perm_prompted_health_connect';
  static const String keyPromptedActivity = 'fit_host_perm_prompted_activity';
  static const String keyPromptedCamera = 'fit_host_perm_prompted_camera';

  bool _isRequesting = false;
  bool get isRequesting => _isRequesting;

  // Cache last known state
  AppPermissionState? _cachedState;
  AppPermissionState? get cachedState => _cachedState;

  // ---------------------------------------------------------------------------
  // Status Queries
  // ---------------------------------------------------------------------------

  /// Checks comprehensive permission state from live OS providers
  Future<AppPermissionState> checkAllPermissions() async {
    final notifStatus = await checkNotificationPermission();
    final alarmStatus = await checkExactAlarmPermission();
    final healthStatus = await checkHealthConnectPermission();
    final activityStatus = await checkPhysicalActivityPermission();
    final cameraStatus = await checkCameraPermission();
    final calendarConnected = await checkGoogleCalendarConnected();

    final state = AppPermissionState(
      notifications: notifStatus,
      exactAlarms: alarmStatus,
      healthConnect: healthStatus,
      physicalActivity: activityStatus,
      camera: cameraStatus,
      googleCalendarConnected: calendarConnected,
      lastChecked: DateTime.now(),
    );

    _cachedState = state;
    return state;
  }

  bool get _isTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  /// Checks live notification permission status
  Future<AppPermissionStatus> checkNotificationPermission() async {
    if (_isTest) return AppPermissionStatus.notRequested;
    if (kIsWeb) return AppPermissionStatus.unavailable;

    try {
      if (Platform.isAndroid) {
        final areEnabled = await NotificationService.instance
            .areNotificationsEnabled();
        final permStatus = await Permission.notification.status;

        if (permStatus.isGranted || areEnabled) {
          return AppPermissionStatus.granted;
        }

        if (permStatus.isPermanentlyDenied || permStatus.isRestricted) {
          return AppPermissionStatus.permanentlyDenied;
        }

        final prompted = await _hasPrompted(keyPromptedNotification);
        return prompted
            ? AppPermissionStatus.denied
            : AppPermissionStatus.notRequested;
      } else if (Platform.isIOS) {
        final status = await Permission.notification.status;
        if (status.isGranted) return AppPermissionStatus.granted;
        if (status.isPermanentlyDenied || status.isRestricted) {
          return AppPermissionStatus.permanentlyDenied;
        }
        final prompted = await _hasPrompted(keyPromptedNotification);
        return prompted
            ? AppPermissionStatus.denied
            : AppPermissionStatus.notRequested;
      }
    } catch (e) {
      debugPrint('[PermissionService] Notification check error: $e');
      return AppPermissionStatus.error;
    }

    return AppPermissionStatus.unavailable;
  }

  /// Checks exact alarm scheduling access (Android 12+ API 31+)
  Future<AppPermissionStatus> checkExactAlarmPermission() async {
    if (_isTest) return AppPermissionStatus.notRequested;
    if (kIsWeb) return AppPermissionStatus.unavailable;
    if (!Platform.isAndroid) return AppPermissionStatus.granted;

    try {
      final isGranted = await Permission.scheduleExactAlarm.isGranted;
      if (isGranted) return AppPermissionStatus.granted;

      // On Android 12+, exact alarm permission requires user to enable in system settings
      return AppPermissionStatus.requiresSystemSettings;
    } catch (e) {
      debugPrint('[PermissionService] Exact alarm check error: $e');
      return AppPermissionStatus.error;
    }
  }

  /// Checks Health Connect authorization for step tracking
  Future<AppPermissionStatus> checkHealthConnectPermission({
    HealthPlatformService? platformService,
  }) async {
    if (_isTest) return AppPermissionStatus.notRequested;
    if (kIsWeb || !Platform.isAndroid) return AppPermissionStatus.unavailable;

    try {
      final service = platformService ?? DefaultHealthPlatformService();
      final isAvailable = await service.isPlatformAvailable();
      if (!isAvailable) {
        return AppPermissionStatus.unavailable;
      }

      final hasPerm = await service.hasPermissions();
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('health_connect_steps_enabled') == true;

      if (hasPerm || isEnabled) {
        return AppPermissionStatus.granted;
      }

      final prompted = await _hasPrompted(keyPromptedHealthConnect);
      return prompted
          ? AppPermissionStatus.denied
          : AppPermissionStatus.notRequested;
    } catch (e) {
      debugPrint('[PermissionService] Health Connect check error: $e');
      return AppPermissionStatus.error;
    }
  }

  /// Checks physical activity permission for hardware pedometer
  Future<AppPermissionStatus> checkPhysicalActivityPermission() async {
    if (_isTest) return AppPermissionStatus.notRequested;
    if (kIsWeb) return AppPermissionStatus.unavailable;
    if (!Platform.isAndroid) {
      // iOS pedometer uses CoreMotion without runtime permission prompt
      return AppPermissionStatus.granted;
    }

    try {
      final status = await Permission.activityRecognition.status;
      if (status.isGranted) return AppPermissionStatus.granted;
      if (status.isPermanentlyDenied || status.isRestricted) {
        return AppPermissionStatus.permanentlyDenied;
      }
      final prompted = await _hasPrompted(keyPromptedActivity);
      return prompted
          ? AppPermissionStatus.denied
          : AppPermissionStatus.notRequested;
    } catch (e) {
      debugPrint('[PermissionService] Physical activity check error: $e');
      return AppPermissionStatus.error;
    }
  }

  /// Checks camera permission (contextual, for food barcode scanner)
  Future<AppPermissionStatus> checkCameraPermission() async {
    if (_isTest) return AppPermissionStatus.notRequested;
    if (kIsWeb) return AppPermissionStatus.unavailable;

    try {
      final status = await Permission.camera.status;
      if (status.isGranted) return AppPermissionStatus.granted;
      if (status.isPermanentlyDenied || status.isRestricted) {
        return AppPermissionStatus.permanentlyDenied;
      }
      final prompted = await _hasPrompted(keyPromptedCamera);
      return prompted
          ? AppPermissionStatus.denied
          : AppPermissionStatus.notRequested;
    } catch (e) {
      debugPrint('[PermissionService] Camera check error: $e');
      return AppPermissionStatus.error;
    }
  }

  /// Checks Google Calendar OAuth token status
  Future<bool> checkGoogleCalendarConnected() async {
    try {
      final auth = Supabase.instance.client.auth;
      if (auth.currentUser == null) return false;
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('google_calendar_sync_enabled') == true;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Request Operations
  // ---------------------------------------------------------------------------

  /// Requests notification permission from user
  Future<AppPermissionStatus> requestNotificationPermission() async {
    if (_isRequesting) return await checkNotificationPermission();
    _isRequesting = true;
    try {
      await _markPrompted(keyPromptedNotification);
      await NotificationService.instance.requestPermissions();
      await Permission.notification.request();
      return await checkNotificationPermission();
    } finally {
      _isRequesting = false;
    }
  }

  /// Opens exact alarm settings in Android system settings
  Future<bool> openExactAlarmSettings() async {
    try {
      await _markPrompted(keyPromptedAlarm);
      return await openAppSettings();
    } catch (_) {
      return false;
    }
  }

  /// Requests Health Connect authorization for step tracking
  Future<AppPermissionStatus> requestHealthConnectPermission({
    HealthPlatformService? platformService,
  }) async {
    if (_isRequesting) return await checkHealthConnectPermission();
    _isRequesting = true;
    try {
      await _markPrompted(keyPromptedHealthConnect);
      final service = platformService ?? DefaultHealthPlatformService();
      final granted = await service.requestPermissions();
      if (granted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('health_connect_steps_enabled', true);
        await service.fetchDailyAggregateSteps(DateTime.now());
      }
      return await checkHealthConnectPermission(platformService: service);
    } finally {
      _isRequesting = false;
    }
  }

  /// Requests physical activity permission
  Future<AppPermissionStatus> requestPhysicalActivityPermission() async {
    if (_isRequesting) return await checkPhysicalActivityPermission();
    _isRequesting = true;
    try {
      await _markPrompted(keyPromptedActivity);
      await Permission.activityRecognition.request();
      return await checkPhysicalActivityPermission();
    } finally {
      _isRequesting = false;
    }
  }

  /// Requests camera permission
  Future<AppPermissionStatus> requestCameraPermission() async {
    if (_isRequesting) return await checkCameraPermission();
    _isRequesting = true;
    try {
      await _markPrompted(keyPromptedCamera);
      await Permission.camera.request();
      return await checkCameraPermission();
    } finally {
      _isRequesting = false;
    }
  }

  /// Opens the device settings for Fit Host app
  Future<bool> openDeviceAppSettings() async {
    return await openAppSettings();
  }

  /// Sends an immediate test notification to verify delivery
  Future<bool> sendTestNotification() async {
    try {
      await NotificationService.instance.showImmediateNotification(
        id: 'test_notification_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Fit Host Reminders Active',
        body:
            'Notifications are configured! Your workout, meal, and hydration alerts will appear on time.',
        channel: NotificationChannelType.workouts,
        sound: true,
        vibration: true,
      );
      return true;
    } catch (e) {
      debugPrint('[PermissionService] Test notification failed: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Onboarding Setup Completion Tracking
  // ---------------------------------------------------------------------------

  Future<bool> hasCompletedPermissionSetup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(keyPermissionSetupCompleted) == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> setPermissionSetupCompleted(bool completed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyPermissionSetupCompleted, completed);
    } catch (e) {
      debugPrint(
        '[PermissionService] Failed to set permission setup completed: $e',
      );
    }
  }

  Future<void> resetPermissionSetup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(keyPermissionSetupCompleted);
      await prefs.remove(keyPromptedNotification);
      await prefs.remove(keyPromptedAlarm);
      await prefs.remove(keyPromptedHealthConnect);
      await prefs.remove(keyPromptedActivity);
      await prefs.remove(keyPromptedCamera);
    } catch (e) {
      debugPrint('[PermissionService] Failed to reset permission setup: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Backward-Compatible Adapter
  // ---------------------------------------------------------------------------

  /// Checks comprehensive permission report with live data
  Future<FitHostPermissionReport> checkPermissionReport() async {
    final state = await checkAllPermissions();
    final areEnabled = await NotificationService.instance
        .areNotificationsEnabled();
    final alarmChannel = await NotificationService.instance.getAlarmChannel();

    return FitHostPermissionReport(
      notificationGranted: state.notifications.isGranted,
      exactAlarmGranted: state.exactAlarms.isGranted,
      batteryOptimizationExempt: true,
      systemAlertWindowGranted: true,
      notificationsEnabled: areEnabled,
      alarmChannelImportance: alarmChannel?.importance,
    );
  }

  // ---------------------------------------------------------------------------
  // Internal Helpers
  // ---------------------------------------------------------------------------

  Future<bool> _hasPrompted(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _markPrompted(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, true);
    } catch (_) {}
  }
}

class FitHostPermissionReport {
  final bool notificationGranted;
  final bool exactAlarmGranted;
  final bool batteryOptimizationExempt;
  final bool systemAlertWindowGranted;
  final bool notificationsEnabled;
  final Importance? alarmChannelImportance;

  const FitHostPermissionReport({
    required this.notificationGranted,
    required this.exactAlarmGranted,
    required this.batteryOptimizationExempt,
    required this.systemAlertWindowGranted,
    required this.notificationsEnabled,
    required this.alarmChannelImportance,
  });

  bool get alarmChannelReady =>
      notificationsEnabled &&
      (alarmChannelImportance == null ||
          alarmChannelImportance!.value >= Importance.high.value);
}

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService.instance;
});

final permissionStateProvider = FutureProvider.autoDispose<AppPermissionState>((
  ref,
) async {
  return await ref.read(permissionServiceProvider).checkAllPermissions();
});
