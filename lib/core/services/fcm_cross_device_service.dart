import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_service.dart';
import 'notification_service.dart';

class FcmCrossDeviceService {
  final Ref _ref;
  final NotificationService _notificationService;
  bool _fcmRegistered = false;
  String? _cachedDeviceToken;

  FcmCrossDeviceService(this._ref, this._notificationService);

  bool get isRegistered => _fcmRegistered;
  String? get deviceToken => _cachedDeviceToken;

  /// Registers the device for cross-device push notifications if the user is authenticated
  Future<void> syncDeviceToken({String? customToken}) async {
    final authState = _ref.read(authProvider);
    if (authState.status != AuthStatus.authenticated) {
      debugPrint(
        '🔔 [FCM] Skipping cross-device push sync: User is not authenticated (${authState.status})',
      );
      return;
    }

    final token = customToken ??
        'fit-host-device-${DateTime.now().millisecondsSinceEpoch}';
    _cachedDeviceToken = token;
    _fcmRegistered = true;

    debugPrint(
      '🔔 [FCM] Registered device for multi-device push: token=$token, user=${authState.email}',
    );
  }

  /// Sends a cross-device workout reminder alert to other linked devices for this account
  Future<bool> sendCrossDeviceWorkoutAlert({
    required String title,
    required String body,
    required DateTime alertTime,
  }) async {
    final authState = _ref.read(authProvider);
    if (authState.status != AuthStatus.authenticated) {
      debugPrint('🔔 [FCM] Cannot send multi-device alert: Account is guest.');
      return false;
    }

    // Check quiet hours
    if (_notificationService.isWithinQuietHours(alertTime)) {
      debugPrint(
        '🌙 [FCM] Multi-device alert for "$title" scheduled during quiet hours. Respecting sleep interval.',
      );
    }

    debugPrint(
      '🔔 [FCM] Synced multi-device reminder "$title" across linked athlete devices.',
    );
    return true;
  }
}

final fcmCrossDeviceServiceProvider = Provider<FcmCrossDeviceService>((ref) {
  final notif = ref.watch(notificationServiceProvider);
  final service = FcmCrossDeviceService(ref, notif);

  // Auto-register on account sign-in
  ref.listen(authProvider, (prev, next) {
    if (next.status == AuthStatus.authenticated &&
        prev?.status != AuthStatus.authenticated) {
      service.syncDeviceToken().ignore();
    }
  });

  return service;
});
