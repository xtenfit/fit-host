import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Standard, strictly minimal event names for Fit Host product analytics.
abstract class AnalyticsEvents {
  static const String appOpened = 'app_opened';
  static const String sessionStarted = 'session_started';
  static const String signupStarted = 'signup_started';
  static const String signupCompleted = 'signup_completed';
  static const String loginFailed = 'login_failed';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String workoutCreated = 'workout_created';
  static const String workoutCompleted = 'workout_completed';
  static const String exerciseLibraryOpened = 'exercise_library_opened';
  static const String mealLogged = 'meal_logged';
  static const String hydrationLogged = 'hydration_logged';
  static const String bodyMeasurementLogged = 'body_measurement_logged';
  static const String reminderCreated = 'reminder_created';
  static const String reminderCompleted = 'reminder_completed';
  static const String integrationSetupCompleted = 'integration_setup_completed';
  static const String coreJourneyFailed = 'core_journey_failed';
}

/// Production-grade, privacy-conscious PostHog analytics service for Fit Host.
///
/// Principles:
/// 1. Strict Privacy & Zero PII: Emails, names, weights, exact body measurements,
///    workout notes, and meal descriptions are never sent.
/// 2. Graceful Degrade: If unconfigured, disabled, or offline, never throws or disrupts UX.
/// 3. Respect User Opt-Out: Supports user preference stored in SharedPreferences.
/// 4. Deduplication: Blocks identical rapid-fire events to protect free allowances.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  static const String _prefKeyOptOut = 'fithost_analytics_opt_out';
  static const String _postHogLogLogger = 'fit_host_posthog_exporter';

  bool _isInitialized = false;
  bool _isOptedOut = false;
  bool _isPostHogConfigured = false;
  String _environment = 'development';
  final Map<String, DateTime> _recentEvents = <String, DateTime>{};

  bool get isInitialized => _isInitialized;
  bool get isOptedOut => _isOptedOut;
  String get environment => _environment;

  /// Initialize PostHog safely with runtime environment parameters.
  Future<void> initialize({
    String? apiKey,
    String? host,
    String? environment,
  }) async {
    if (_isInitialized) return;

    _environment = environment ?? (kReleaseMode ? 'production' : 'development');

    try {
      final prefs = await SharedPreferences.getInstance();
      _isOptedOut = prefs.getBool(_prefKeyOptOut) ?? false;

      if (_isOptedOut) {
        debugPrint('📊 [Analytics] User opted out of analytics tracking.');
        _isInitialized = true;
        return;
      }

      if (apiKey == null || apiKey.isEmpty) {
        debugPrint(
          'ℹ️ [Analytics] PostHog API key not provided. Operating in safe logging fallback mode.',
        );
        _isInitialized = true;
        return;
      }

      final config = PostHogConfig(apiKey);
      if (host != null && host.isNotEmpty) {
        config.host = host;
      }
      config.captureApplicationLifecycleEvents = false;
      config.preloadFeatureFlags = false;
      // Let the SDK register and manage each supported uncaught-exception path.
      // This covers Flutter framework, Dart runtime, main-isolate, and native
      // crashes without adding duplicate PostHog listeners in the app entrypoint.
      config.errorTrackingConfig.captureFlutterErrors = true;
      config.errorTrackingConfig.capturePlatformDispatcherErrors = true;
      config.errorTrackingConfig.captureIsolateErrors = true;
      config.errorTrackingConfig.captureNativeExceptions = true;
      config.logsConfig.serviceName = 'fit-host';
      config.logsConfig.environment = _environment;
      // Do not forward existing application output. Only the dedicated logger
      // below may export purpose-written PostHog logs.
      config.logsConfig.beforeSend = [
        (record) =>
            record.attributes?['logger'] == _postHogLogLogger ? record : null,
      ];
      await Posthog().setup(config);

      _isPostHogConfigured = true;
      _isInitialized = true;
      debugPrint(
        '📊 [Analytics] PostHog initialized successfully for environment: $_environment',
      );
      logInfo(
        'PostHog analytics initialized',
        attributes: {'event': 'posthog_analytics_initialized'},
      );
    } catch (e) {
      _isInitialized = true;
      debugPrint(
        '⚠️ [Analytics] Initialization fallback error ($e). Logging only.',
      );
    }
  }

  /// Exports a purpose-written operational log through the dedicated PostHog
  /// logger. Existing debugPrint output is intentionally never forwarded.
  void logInfo(String body, {Map<String, Object> attributes = const {}}) {
    if (_isOptedOut || !_isPostHogConfigured) return;

    try {
      Posthog().logger.info(body, {'logger': _postHogLogLogger, ...attributes});
    } catch (e) {
      debugPrint('[Analytics-Fallback] Log: $body');
    }
  }

  /// Track a core product analytics event with strict PII filtering.
  Future<void> track(
    String eventName, {
    Map<String, dynamic>? properties,
  }) async {
    if (_isOptedOut) return;

    final dedupeKey =
        '$eventName::${properties?['category'] ?? ''}::${properties?['screen'] ?? ''}';
    final now = DateTime.now();
    final lastTime = _recentEvents[dedupeKey];
    if (lastTime != null &&
        now.difference(lastTime) < const Duration(milliseconds: 1500)) {
      return;
    }
    _recentEvents[dedupeKey] = now;
    if (_recentEvents.length > 50) {
      _recentEvents.removeWhere(
        (_, time) => now.difference(time) > const Duration(seconds: 5),
      );
    }

    final sanitizedProps = _sanitizeProperties(
      properties ?? <String, dynamic>{},
    );
    sanitizedProps['environment'] = _environment;
    sanitizedProps['timestamp'] = DateTime.now().toUtc().toIso8601String();

    try {
      await Posthog().capture(eventName: eventName, properties: sanitizedProps);
    } catch (e) {
      debugPrint('[Analytics-Fallback] Track: $eventName -> $sanitizedProps');
    }
  }

  /// Identify an authenticated user using ONLY an anonymous, non-sensitive UUID.
  /// Never accepts email, username, or personal health info.
  Future<void> identify(
    String userId, {
    Map<String, dynamic>? userProperties,
  }) async {
    if (_isOptedOut) return;
    if (userId.isEmpty || userId == 'guest') {
      return;
    }

    // Guard against accidental email passing
    final safeUserId = userId.contains('@') ? 'anonymized_user' : userId;
    final sanitizedUserProps = _sanitizeProperties(
      userProperties ?? <String, dynamic>{},
    );
    sanitizedUserProps['environment'] = _environment;

    try {
      await Posthog().identify(
        userId: safeUserId,
        userProperties: sanitizedUserProps,
      );
      debugPrint('📊 [Analytics] User identified: $safeUserId');
    } catch (e) {
      debugPrint('[Analytics-Fallback] Identify: $safeUserId');
    }
  }

  /// Reset session on user logout to prevent identity or event leakage.
  Future<void> reset() async {
    _recentEvents.clear();
    try {
      await Posthog().reset();
      debugPrint('📊 [Analytics] Session reset on logout.');
    } catch (e) {
      debugPrint('[Analytics-Fallback] Reset');
    }
  }

  /// Opt-out of analytics collection.
  Future<void> optOut() async {
    _isOptedOut = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyOptOut, true);
      await Posthog().optOut();
      debugPrint('📊 [Analytics] Disabled by user request.');
    } catch (_) {}
  }

  /// Opt-in to analytics collection.
  Future<void> optIn() async {
    _isOptedOut = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyOptOut, false);
      await Posthog().optIn();
      debugPrint('📊 [Analytics] Enabled by user request.');
    } catch (_) {}
  }

  /// Sanitize all properties to prevent personal data or health records from escaping.
  Map<String, Object> _sanitizeProperties(Map<String, dynamic> raw) {
    final cleaned = <String, Object>{};
    for (final entry in raw.entries) {
      final key = entry.key;
      final val = entry.value;

      if (_isBlockedKey(key)) {
        continue;
      }

      if (val is String) {
        cleaned[key] = _sanitizeString(val);
      } else if (val is num || val is bool) {
        cleaned[key] = val;
      } else if (val is List) {
        cleaned[key] =
            val.length; // Convert lists to count to avoid leaking contents
      } else if (val != null) {
        cleaned[key] = _sanitizeString(val.toString());
      }
    }
    return cleaned;
  }

  bool _isBlockedKey(String key) {
    final lower = key.toLowerCase();
    const blockedKeywords = [
      'email',
      'name',
      'password',
      'token',
      'secret',
      'weight',
      'body_fat',
      'measurement',
      'note',
      'notes',
      'meal_name',
      'food',
      'ingredients',
      'address',
      'phone',
      'heart_rate',
      'blood_pressure',
      'auth',
      'credential',
    ];
    return blockedKeywords.any((b) => lower == b || lower.contains(b));
  }

  String _sanitizeString(String input) {
    var out = input;
    // Strip emails
    out = out.replaceAll(
      RegExp(r'[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+'),
      '[REDACTED_EMAIL]',
    );
    // Strip tokens
    out = out.replaceAll(
      RegExp(r'sb_[A-Za-z0-9_\-]+', caseSensitive: false),
      '[REDACTED_KEY]',
    );
    out = out.replaceAll(
      RegExp(r'Bearer\s+[A-Za-z0-9\-\._~\+\/]+=*', caseSensitive: false),
      'Bearer [REDACTED_TOKEN]',
    );
    return out;
  }
}
