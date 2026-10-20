import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

/// Comprehensive permission management service for Fit Host:
/// - Android 13+ (POST_NOTIFICATIONS)
/// - Android 12+ (SCHEDULE_EXACT_ALARM)
/// - Android Battery Optimization Exemption (REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
/// - iOS Notification (Alert, Sound, Badge)
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  static PermissionService get instance => _instance;

  bool _hasPromptedUser = false;
  bool get hasPromptedUser => _hasPromptedUser;

  /// Requests all necessary permissions for reminders & alarms.
  /// When [context] is provided, displays an informative dialog before requesting
  /// the battery optimization exemption on Android devices.
  Future<Map<Permission, PermissionStatus>> requestReminderPermissions([
    BuildContext? context,
  ]) async {
    final results = <Permission, PermissionStatus>{};
    _hasPromptedUser = true;

    if (kIsWeb) return results;

    try {
      if (Platform.isAndroid) {
        // 1. Android 13+ Notification Permission
        final notifStatus = await Permission.notification.request();
        results[Permission.notification] = notifStatus;

        // 2. Android 12+ Schedule Exact Alarm Permission
        final alarmStatus = await Permission.scheduleExactAlarm.request();
        results[Permission.scheduleExactAlarm] = alarmStatus;

        // 3. Android Battery Optimization Exemption
        final isIgnored = await Permission.ignoreBatteryOptimizations.isGranted;
        if (!isIgnored) {
          bool proceed = true;
          if (context != null && context.mounted) {
            proceed = await showBatteryOptimizationDialog(context) ?? false;
          }
          if (proceed) {
            final batteryStatus = await Permission.ignoreBatteryOptimizations.request();
            results[Permission.ignoreBatteryOptimizations] = batteryStatus;
          }
        }
      } else if (Platform.isIOS) {
        // iOS: Requests Alert, Sound, Badge
        final notifStatus = await Permission.notification.request();
        results[Permission.notification] = notifStatus;
      }
    } catch (e) {
      debugPrint('[PermissionService] Error requesting permissions: $e');
    }

    return results;
  }

  /// Informative popup explaining why background optimization exemption is needed.
  Future<bool?> showBatteryOptimizationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF121A16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.bolt_rounded, color: Color(0xFF00E676), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Background Reliability',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'To ensure your reminders work reliably, please allow Fit Host to run in the background.',
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: Color(0xFFB0C4B8),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Later',
              style: TextStyle(color: Color(0xFF8FA396), fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Allow Background',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  /// Returns true if core notification permission is granted
  Future<bool> hasNotificationPermission() async {
    return await Permission.notification.isGranted;
  }

  /// Returns true if exact alarm permission is granted
  Future<bool> hasExactAlarmPermission() async {
    if (!kIsWeb && Platform.isAndroid) {
      return await Permission.scheduleExactAlarm.isGranted;
    }
    return true;
  }

  /// Returns true if battery optimization is ignored
  Future<bool> isIgnoringBatteryOptimizations() async {
    if (!kIsWeb && Platform.isAndroid) {
      return await Permission.ignoreBatteryOptimizations.isGranted;
    }
    return true;
  }

  /// Returns true if overlay / draw over other apps (System Alert Window) is granted
  Future<bool> hasSystemAlertWindowPermission() async {
    if (!kIsWeb && Platform.isAndroid) {
      return await Permission.systemAlertWindow.isGranted;
    }
    return true;
  }

  /// Requests Draw Over Other Apps / System Alert Window permission
  Future<PermissionStatus> requestSystemAlertWindow() async {
    if (!kIsWeb && Platform.isAndroid) {
      return await Permission.systemAlertWindow.request();
    }
    return PermissionStatus.granted;
  }

  /// Opens the device settings for Fit Host app
  Future<bool> openDeviceAppSettings() async {
    return await openAppSettings();
  }

  /// Checks comprehensive permission report
  Future<FitHostPermissionReport> checkPermissionReport() async {
    final notif = await hasNotificationPermission();
    final alarm = await hasExactAlarmPermission();
    final battery = await isIgnoringBatteryOptimizations();
    final overlay = await hasSystemAlertWindowPermission();

    return FitHostPermissionReport(
      notificationGranted: notif,
      exactAlarmGranted: alarm,
      batteryOptimizationExempt: battery,
      systemAlertWindowGranted: overlay,
    );
  }
}

class FitHostPermissionReport {
  final bool notificationGranted;
  final bool exactAlarmGranted;
  final bool batteryOptimizationExempt;
  final bool systemAlertWindowGranted;

  const FitHostPermissionReport({
    required this.notificationGranted,
    required this.exactAlarmGranted,
    required this.batteryOptimizationExempt,
    required this.systemAlertWindowGranted,
  });

  bool get allEssentialGranted =>
      notificationGranted &&
      exactAlarmGranted &&
      batteryOptimizationExempt &&
      systemAlertWindowGranted;
}

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService.instance;
});
