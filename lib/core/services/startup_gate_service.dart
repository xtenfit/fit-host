import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class StartupGateService {
  final FlutterSecureStorage _storage;

  static const String keyFirstLaunch = 'fit_host_first_launch_completed';
  static const String keyAuthDecision = 'fit_host_auth_decision_made';
  static const String keyGuestOnboarding =
      'fit_host_guest_onboarding_completed';
  static const String keyWizardDraftStep = 'fit_host_wizard_draft_step';
  static const String keyWizardSkipped = 'fit_host_wizard_skipped';

  static String accountOnboardingKey(String userId) =>
      'fit_host_onboarding_completed_$userId';

  StartupGateService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  // --- Wizard Draft Progress & Skip Tracking ---
  Future<bool> hasSkippedWizard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(keyWizardSkipped) == true) {
        return true;
      }
    } catch (_) {}

    try {
      final val = await _storage.read(key: keyWizardSkipped);
      return val == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<void> setWizardSkipped(bool skipped) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyWizardSkipped, skipped);
    } catch (_) {}

    try {
      await _storage.write(
        key: keyWizardSkipped,
        value: skipped ? 'true' : 'false',
      );
    } catch (_) {}
  }

  // --- Wizard Draft Progress ---
  Future<int?> getWizardDraftStep() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(keyWizardDraftStep)) {
        return prefs.getInt(keyWizardDraftStep);
      }
    } catch (e) {
      debugPrint('StartupGateService read draft step prefs error: $e');
    }

    try {
      final val = await _storage.read(key: keyWizardDraftStep);
      if (val != null) {
        return int.tryParse(val);
      }
    } catch (e) {
      debugPrint('StartupGateService read draft step secureStorage error: $e');
    }
    return null;
  }

  Future<void> saveWizardDraftStep(int step) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(keyWizardDraftStep, step);
    } catch (_) {}

    try {
      await _storage.write(key: keyWizardDraftStep, value: step.toString());
    } catch (_) {}
  }

  Future<void> clearWizardDraftStep() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(keyWizardDraftStep);
    } catch (_) {}

    try {
      await _storage.delete(key: keyWizardDraftStep);
    } catch (_) {}
  }

  // --- Guest Onboarding Completion ---
  Future<bool> isGuestOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getBool(keyGuestOnboarding);
      if (val != null) return val;
    } catch (_) {}

    try {
      final val = await _storage
          .read(key: keyGuestOnboarding)
          .timeout(const Duration(milliseconds: 600), onTimeout: () => null);
      if (val != null) return val == 'true';
    } catch (_) {}

    return false;
  }

  Future<void> setGuestOnboardingCompleted(bool completed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyGuestOnboarding, completed);
      await prefs.setBool(keyFirstLaunch, completed);
      await prefs.setBool(keyAuthDecision, completed);
    } catch (_) {}

    try {
      await _storage.write(
        key: keyGuestOnboarding,
        value: completed ? 'true' : 'false',
      );
      await _storage.write(
        key: keyFirstLaunch,
        value: completed ? 'true' : 'false',
      );
      await _storage.write(
        key: keyAuthDecision,
        value: completed ? 'true' : 'false',
      );
    } catch (_) {}
  }

  // --- Account-Scoped Onboarding Completion ---
  Future<bool> isAccountOnboardingCompleted(String userId) async {
    final key = accountOnboardingKey(userId);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(key) == true) {
        return true;
      }
    } catch (_) {}

    try {
      final val = await _storage
          .read(key: key)
          .timeout(const Duration(milliseconds: 600), onTimeout: () => null);
      return val == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<void> setAccountOnboardingCompleted(
    String userId,
    bool completed,
  ) async {
    final key = accountOnboardingKey(userId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, completed);
      await prefs.setBool(keyFirstLaunch, completed);
      await prefs.setBool(keyAuthDecision, completed);
    } catch (_) {}

    try {
      await _storage.write(key: key, value: completed ? 'true' : 'false');
      await _storage.write(
        key: keyFirstLaunch,
        value: completed ? 'true' : 'false',
      );
      await _storage.write(
        key: keyAuthDecision,
        value: completed ? 'true' : 'false',
      );
    } catch (_) {}
  }

  // --- Legacy First Launch & Auth Decision (for backwards compatibility) ---
  Future<bool> isFirstLaunchCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(keyFirstLaunch) == true) {
        return true;
      }
    } catch (e) {
      debugPrint('StartupGateService read prefs firstLaunch error: $e');
    }

    try {
      final val = await _storage
          .read(key: keyFirstLaunch)
          .timeout(const Duration(milliseconds: 600), onTimeout: () => null);
      return val == 'true';
    } catch (e) {
      debugPrint('StartupGateService read secureStorage firstLaunch error: $e');
      return false;
    }
  }

  Future<bool> isAuthDecisionMade() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(keyAuthDecision) == true) {
        return true;
      }
    } catch (e) {
      debugPrint('StartupGateService read prefs authDecision error: $e');
    }

    try {
      final val = await _storage
          .read(key: keyAuthDecision)
          .timeout(const Duration(milliseconds: 600), onTimeout: () => null);
      return val == 'true';
    } catch (e) {
      debugPrint(
        'StartupGateService read secureStorage authDecision error: $e',
      );
      return false;
    }
  }

  Future<void> setFirstLaunchCompleted(bool completed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyFirstLaunch, completed);
    } catch (e) {
      debugPrint('StartupGateService write prefs firstLaunch error: $e');
    }

    try {
      await _storage.write(
        key: keyFirstLaunch,
        value: completed ? 'true' : 'false',
      );
    } catch (e) {
      debugPrint(
        'StartupGateService write secureStorage firstLaunch error: $e',
      );
    }
  }

  Future<void> setAuthDecisionMade(bool made) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyAuthDecision, made);
    } catch (e) {
      debugPrint('StartupGateService write prefs authDecision error: $e');
    }

    try {
      await _storage.write(
        key: keyAuthDecision,
        value: made ? 'true' : 'false',
      );
    } catch (e) {
      debugPrint(
        'StartupGateService write secureStorage authDecision error: $e',
      );
    }
  }

  Future<void> resetOnboarding({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(keyFirstLaunch);
      await prefs.remove(keyAuthDecision);
      await prefs.remove(keyGuestOnboarding);
      await prefs.remove(keyWizardDraftStep);
      await prefs.remove(keyWizardSkipped);
      if (userId != null && userId.isNotEmpty) {
        await prefs.remove(accountOnboardingKey(userId));
      }
    } catch (e) {
      debugPrint('StartupGateService reset prefs error: $e');
    }

    try {
      await _storage.delete(key: keyFirstLaunch);
      await _storage.delete(key: keyAuthDecision);
      await _storage.delete(key: keyGuestOnboarding);
      await _storage.delete(key: keyWizardDraftStep);
      await _storage.delete(key: keyWizardSkipped);
      if (userId != null && userId.isNotEmpty) {
        await _storage.delete(key: accountOnboardingKey(userId));
      }
    } catch (e) {
      debugPrint('StartupGateService reset secureStorage error: $e');
    }
  }

  Future<bool> hasSavedProfile(String userId) async {
    try {
      final key = 'fit_host_user_profile_$userId';
      final val = await _storage.read(key: key);
      if (val != null && val.isNotEmpty) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  // --- Initial Route Resolution ---
  Future<String> determineInitialRoute({
    bool isAuthenticated = false,
    bool isProfileSetupCompleted = false,
    String? userId,
    bool isLegacyUser = false,
  }) async {
    // 1. Authenticated User Flow (Condition 2)
    // For account users: check in DB if existing user (profile setup completed in DB)
    if (isAuthenticated) {
      // Existing user with setup completed in DB -> do NOT show wizard
      if (isProfileSetupCompleted || isLegacyUser) {
        if (userId != null && userId.isNotEmpty && userId != 'guest') {
          await setAccountOnboardingCompleted(userId, true);
        }
        await setFirstLaunchCompleted(true);
        await setAuthDecisionMade(true);
        NotificationService.instance.cancelWizardSetupNotifications().ignore();
        return '/home';
      }

      // Check if user previously completed or skipped account onboarding on this device
      if (userId != null && userId.isNotEmpty && userId != 'guest') {
        final accountDone = await isAccountOnboardingCompleted(userId);
        if (accountDone) {
          NotificationService.instance
              .cancelWizardSetupNotifications()
              .ignore();
          return '/home';
        }

        final hasProfile = await hasSavedProfile(userId);
        if (hasProfile) {
          await setAccountOnboardingCompleted(userId, true);
          await setFirstLaunchCompleted(true);
          await setAuthDecisionMade(true);
          NotificationService.instance
              .cancelWizardSetupNotifications()
              .ignore();
          return '/home';
        }
      }

      // Fresh/new account user whose DB profile is not completed -> show wizard
      return '/setup-wizard';
    }

    // 2. Unauthenticated / Guest Flow (Condition 1 & 1st screen: Auth Screen)
    final guestDone = await isGuestOnboardingCompleted();
    if (guestDone || isProfileSetupCompleted) {
      if (isProfileSetupCompleted && !guestDone) {
        await setGuestOnboardingCompleted(true);
      }
      return '/home';
    }

    // If guest chose "Continue as Guest" (auth decision made) and is a new guest user:
    final authDecisionDone = await isAuthDecisionMade();
    if (authDecisionDone) {
      // Condition 1: Always launch wizard screen for new guest user
      return '/setup-wizard';
    }

    // Fresh user: 1st show Auth Screen!
    return '/auth-decision';
  }
}

final startupGateServiceProvider = Provider<StartupGateService>((ref) {
  return StartupGateService();
});
