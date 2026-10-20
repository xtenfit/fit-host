import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StartupGateService {
  final FlutterSecureStorage _storage;

  static const String keyFirstLaunch = 'fit_host_first_launch_completed';
  static const String keyAuthDecision = 'fit_host_auth_decision_made';

  StartupGateService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<bool> isFirstLaunchCompleted() async {
    try {
      final val = await _storage.read(key: keyFirstLaunch).timeout(
            const Duration(milliseconds: 600),
            onTimeout: () => null,
          );
      return val == 'true';
    } catch (e) {
      debugPrint('StartupGateService read firstLaunch error: $e');
      return false;
    }
  }

  Future<bool> isAuthDecisionMade() async {
    try {
      final val = await _storage.read(key: keyAuthDecision).timeout(
            const Duration(milliseconds: 600),
            onTimeout: () => null,
          );
      return val == 'true';
    } catch (e) {
      debugPrint('StartupGateService read authDecision error: $e');
      return false;
    }
  }

  Future<void> setFirstLaunchCompleted(bool completed) async {
    try {
      await _storage.write(
        key: keyFirstLaunch,
        value: completed ? 'true' : 'false',
      );
    } catch (e) {
      debugPrint('StartupGateService write firstLaunch error: $e');
    }
  }

  Future<void> setAuthDecisionMade(bool made) async {
    try {
      await _storage.write(
        key: keyAuthDecision,
        value: made ? 'true' : 'false',
      );
    } catch (e) {
      debugPrint('StartupGateService write authDecision error: $e');
    }
  }

  Future<void> resetOnboarding() async {
    try {
      await _storage.delete(key: keyFirstLaunch);
      await _storage.delete(key: keyAuthDecision);
    } catch (e) {
      debugPrint('StartupGateService reset error: $e');
    }
  }

  Future<String> determineInitialRoute({
    bool isAuthenticated = false,
    bool isProfileSetupCompleted = true,
  }) async {
    final firstLaunchDone = await isFirstLaunchCompleted();
    if (!firstLaunchDone) {
      return '/setup-wizard';
    }
    final authDecisionDone = await isAuthDecisionMade();
    if (!authDecisionDone) {
      return '/auth-decision';
    }
    if (isAuthenticated && !isProfileSetupCompleted) {
      return '/setup-wizard';
    }
    return '/home';
  }
}

final startupGateServiceProvider = Provider<StartupGateService>((ref) {
  return StartupGateService();
});
