import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'notification_service.dart';

/// Service that securely coordinates Android Keyguard (lockscreen) display states.
///
/// Ensures that ONLY the dedicated Fullscreen Alarm/Reminder screen can appear
/// over the Android lockscreen when an alarm triggers, and that dismissing or exiting
/// the alarm NEVER opens or exposes the underlying application while the phone is locked.
class LockScreenSecurityService {
  static final LockScreenSecurityService _instance =
      LockScreenSecurityService._internal();
  factory LockScreenSecurityService() => _instance;
  LockScreenSecurityService._internal() {
    _initChannelHandler();
  }

  static LockScreenSecurityService get instance => _instance;

  static const MethodChannel _channel = MethodChannel(
    'com.fithost.fit_host/lockscreen',
  );

  bool get _isTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  void _initChannelHandler() {
    if (_isTest || kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onAlarmIntentPayload') {
        final payload = call.arguments as String?;
        if (payload != null && payload.isNotEmpty) {
          debugPrint(
            '🚨 [LockScreenSecurityService] Received alarm intent payload: $payload',
          );
          NotificationService.instance.handleNotificationTap(payload);
        }
      }
    });
  }

  /// Retrieves any alarm intent payload stored during Android MainActivity.onCreate()
  Future<String?> getInitialAlarmPayload() async {
    if (_isTest || kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }
    try {
      return await _channel.invokeMethod<String>('getInitialAlarmPayload');
    } catch (e) {
      debugPrint(
        '[LockScreenSecurityService] getInitialAlarmPayload error: $e',
      );
      return null;
    }
  }

  /// Check whether the Android keyguard is currently locked.
  Future<bool> isDeviceLocked() async {
    if (_isTest || kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      final bool? isLocked = await _channel.invokeMethod<bool>(
        'isDeviceLocked',
      );
      return isLocked ?? false;
    } catch (e) {
      debugPrint('[LockScreenSecurityService] isDeviceLocked error: $e');
      return false;
    }
  }

  /// Enable lockscreen overlay mode.
  /// MUST ONLY be called when FullscreenAlarmScreen is actively displaying.
  Future<void> enableAlarmLockScreenMode() async {
    if (_isTest || kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      await _channel.invokeMethod('enableLockScreenOverlay');
    } catch (e) {
      debugPrint(
        '[LockScreenSecurityService] enableAlarmLockScreenMode error: $e',
      );
    }
  }

  /// Disable lockscreen overlay mode immediately, returning the app to secure state.
  Future<void> disableAlarmLockScreenMode() async {
    if (_isTest || kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      await _channel.invokeMethod('disableLockScreenOverlay');
    } catch (e) {
      debugPrint(
        '[LockScreenSecurityService] disableAlarmLockScreenMode error: $e',
      );
    }
  }

  /// Closes the alarm overlay back to the Android lockscreen.
  /// If the phone is locked, moves the task to the back so the user remains on their lockscreen.
  Future<void> closeAlarmToLockScreen() async {
    if (_isTest || kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      await _channel.invokeMethod('closeAlarmToLockScreen');
    } catch (e) {
      debugPrint(
        '[LockScreenSecurityService] closeAlarmToLockScreen error: $e',
      );
    }
  }

  /// Requests the Android Keyguard to prompt the user to unlock (PIN/password/biometric)
  /// before navigating to an in-app feature from the alarm screen.
  Future<bool> dismissKeyguardAndProceed() async {
    if (_isTest || kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }
    try {
      final bool? success = await _channel.invokeMethod<bool>(
        'dismissKeyguardAndProceed',
      );
      return success ?? false;
    } catch (e) {
      debugPrint(
        '[LockScreenSecurityService] dismissKeyguardAndProceed error: $e',
      );
      return false;
    }
  }

  /// Safely dismisses the alarm.
  ///
  /// - If running in a test environment:
  ///   Immediately performs navigation to ensure widget tests verify cleanly.
  /// - If the device is LOCKED:
  ///   - If [nextRoute] is provided (user tapped "Open Workout Tracker" etc.),
  ///     prompts for PIN/biometric unlock. If authenticated, navigates to [nextRoute].
  ///     If cancelled or failed, closes the alarm to the lockscreen to prevent unauthorized access.
  ///   - If [nextRoute] is null (dismiss, snooze, or timeout), immediately closes
  ///     the alarm to the lockscreen so the app is NOT opened or accessible.
  /// - If the device is UNLOCKED:
  ///   - Disables lockscreen overlay and navigates to [nextRoute] or pops to previous screen.
  Future<void> dismissAlarmSafely(
    BuildContext context, {
    String? nextRoute,
  }) async {
    if (_isTest) {
      if (context.mounted) {
        _performNavigate(context, nextRoute ?? '/home');
      }
      return;
    }

    final locked = await isDeviceLocked();
    if (locked) {
      if (nextRoute != null) {
        final unlocked = await dismissKeyguardAndProceed();
        if (unlocked) {
          await disableAlarmLockScreenMode();
          if (context.mounted) {
            _performNavigate(context, nextRoute);
          }
        } else {
          // User did not unlock; keep the device locked and close alarm
          await closeAlarmToLockScreen();
        }
      } else {
        // Simple dismissal while locked: return to lockscreen
        await closeAlarmToLockScreen();
      }
    } else {
      // Phone is unlocked
      await disableAlarmLockScreenMode();
      if (context.mounted) {
        _performNavigate(context, nextRoute ?? '/home');
      }
    }
  }

  void _performNavigate(BuildContext context, String route) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      try {
        context.go(route);
      } catch (_) {
        try {
          Navigator.of(context).pushNamed(route);
        } catch (_) {
          Navigator.of(context).maybePop();
        }
      }
    }
  }
}
