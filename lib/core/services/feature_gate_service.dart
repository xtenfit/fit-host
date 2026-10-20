import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_service.dart';
import '../../features/auth/presentation/dialogs/feature_upsell_sheet.dart';

enum GuestFeature {
  basicWorkouts,
  localTracking,
  offlineHydration,
  stepsToday,
  calendarTodayAndWeek,
}

enum AppGatedFeature {
  stepHistoryAndTrends,
  calendarMonthAndCustomRanges,
  crossDeviceSync,
  dataExport,
  advancedProgressCharts,
  cloudBackup,
}

typedef AccountFeature = AppGatedFeature;

class FeatureGateService {
  final AuthStatus authStatus;

  const FeatureGateService(this.authStatus);

  bool get isAuthenticated => authStatus == AuthStatus.authenticated;
  bool get isGuest => authStatus == AuthStatus.guest;

  bool isFeatureUnlocked(AppGatedFeature feature) {
    return isAuthenticated;
  }

  bool isAccountFeatureUnlocked(AppGatedFeature feature) {
    return isAuthenticated;
  }

  bool isGuestFeatureUnlocked(GuestFeature feature) {
    return true; // All guest features are accessible
  }
}

final featureGateProvider = Provider<FeatureGateService>((ref) {
  final auth = ref.watch(authProvider);
  return FeatureGateService(auth.status);
});

/// Displays a sleek bottom sheet prompting the guest to sign in or create an account to unlock
/// the feature, deep-linking directly into authentication.
Future<bool?> showAccountGateBottomSheet(
  BuildContext context, {
  required String featureTitle,
  required String featureDescription,
  IconData icon = Icons.lock_outline_rounded,
}) {
  return FeatureUpsellSheet.show(
    context,
    title: featureTitle,
    description: featureDescription,
    icon: icon,
  );
}
