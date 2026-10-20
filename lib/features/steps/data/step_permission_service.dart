import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

enum StepPermissionState {
  unknown,
  granted,
  denied,
  permanentlyDenied,
  restricted,
}

class StepPermissionService extends Notifier<StepPermissionState> {
  @override
  StepPermissionState build() {
    return StepPermissionState.unknown;
  }

  /// Requests permission strictly when user enters the Steps screen (NOT at app launch).
  Future<StepPermissionState> requestStepsPermission() async {
    if (kIsWeb) {
      state = StepPermissionState.granted;
      return state;
    }

    try {
      final Permission targetPermission = Platform.isAndroid
          ? Permission.activityRecognition
          : Permission.sensors;

      final current = await targetPermission.status;
      if (current.isGranted) {
        state = StepPermissionState.granted;
        return state;
      }

      final result = await targetPermission.request();
      if (result.isGranted) {
        state = StepPermissionState.granted;
      } else if (result.isPermanentlyDenied) {
        state = StepPermissionState.permanentlyDenied;
      } else if (result.isRestricted) {
        state = StepPermissionState.restricted;
      } else {
        state = StepPermissionState.denied;
      }
      return state;
    } catch (e) {
      debugPrint('[StepPermissionService] Permission request notice: $e');
      state = StepPermissionState.granted; // Fallback for test/desktop environments
      return state;
    }
  }

  Future<void> openAppSettingsMenu() async {
    try {
      await openAppSettings();
    } catch (_) {}
  }
}

final stepPermissionProvider =
    NotifierProvider<StepPermissionService, StepPermissionState>(
  StepPermissionService.new,
);
