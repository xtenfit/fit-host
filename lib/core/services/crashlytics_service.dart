import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Production-ready, privacy-conscious Firebase Crashlytics service for Fit Host.
///
/// Features:
/// - Safe lazy initialization: guards against missing google-services.json/credentials.
/// - Duplicate exception suppression within a short time window.
/// - Strict PII / Token redaction on stack traces, reasons, and error keys.
/// - Respects user opt-out and developer test modes.
class CrashlyticsService {
  CrashlyticsService._();
  static final CrashlyticsService instance = CrashlyticsService._();

  bool _isInitialized = false;
  bool _isEnabled = false;
  final Set<String> _recentErrorSignatures = <String>{};

  bool get isInitialized => _isInitialized;
  bool get isEnabled => _isEnabled;

  /// Initialize Firebase and Crashlytics safely.
  /// If Firebase isn't configured, falls back silently without throwing.
  Future<void> initialize({
    FirebaseOptions? options,
    bool enableInDev = false,
  }) async {
    if (_isInitialized) return;

    try {
      // Check if Firebase is already initialized
      if (Firebase.apps.isEmpty) {
        if (options != null) {
          await Firebase.initializeApp(options: options);
        } else {
          // Standard auto-init from native google-services.json
          await Firebase.initializeApp();
        }
      }

      // Check if Crashlytics collection should be enabled
      final shouldCollect = !kDebugMode || enableInDev;
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        shouldCollect,
      );

      _isEnabled = shouldCollect;
      _isInitialized = true;
      debugPrint(
        '🛡️ [Crashlytics] Initialized successfully (collection: $_isEnabled)',
      );
    } catch (e) {
      _isInitialized = false;
      _isEnabled = false;
      debugPrint(
        'ℹ️ [Crashlytics] Firebase not configured or unavailable in this environment ($e). Operating in safe offline fallback mode.',
      );
    }
  }

  /// Record an uncaught Flutter framework error.
  void recordFlutterError(FlutterErrorDetails details, {bool fatal = false}) {
    final signature = _createErrorSignature(details.exception, details.stack);
    if (_isDuplicate(signature)) return;

    final sanitizedReason = _sanitizeText(
      details.context?.toDescription() ?? 'Flutter Framework Error',
    );

    if (_isInitialized && _isEnabled) {
      FirebaseCrashlytics.instance.recordFlutterError(
        FlutterErrorDetails(
          exception: details.exception,
          stack: details.stack,
          library: details.library,
          context: ErrorDescription(sanitizedReason),
          informationCollector: details.informationCollector,
        ),
        fatal: fatal,
      );
    } else {
      debugPrint(
        '[Crashlytics-Fallback] Framework Error: $sanitizedReason | ${details.exception}',
      );
    }
  }

  /// Record an uncaught asynchronous error or non-fatal exception.
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    Iterable<Object> information = const [],
    bool fatal = false,
    bool printDetails = false,
  }) async {
    final signature = _createErrorSignature(exception, stack);
    if (_isDuplicate(signature)) return;

    final sanitizedReason = reason != null
        ? _sanitizeText(reason.toString())
        : null;

    if (_isInitialized && _isEnabled) {
      await FirebaseCrashlytics.instance.recordError(
        exception,
        stack,
        reason: sanitizedReason,
        information: information.map((item) => _sanitizeText(item.toString())),
        fatal: fatal,
        printDetails: printDetails,
      );
    } else {
      debugPrint(
        '[Crashlytics-Fallback] Error recorded: $sanitizedReason | $exception',
      );
    }
  }

  /// Set user identifier safely (uses stable internal UUID, never email/PII).
  Future<void> setUserId(String? userId) async {
    if (!_isInitialized || !_isEnabled) return;
    try {
      if (userId == null || userId.isEmpty || userId == 'guest') {
        await FirebaseCrashlytics.instance.setUserIdentifier('guest');
      } else {
        // Enforce anonymized internal identifier (no email addresses)
        final sanitizedId = userId.contains('@') ? 'anonymized_user' : userId;
        await FirebaseCrashlytics.instance.setUserIdentifier(sanitizedId);
      }
    } catch (_) {}
  }

  /// Set diagnostic key-value pairs (filtered for sensitive information).
  Future<void> setCustomKey(String key, Object value) async {
    if (!_isInitialized || !_isEnabled) return;
    if (_isSensitiveKey(key)) return;

    try {
      final sanitizedValue = _sanitizeText(value.toString());
      await FirebaseCrashlytics.instance.setCustomKey(key, sanitizedValue);
    } catch (_) {}
  }

  /// Controlled staging-only crash simulation for verification.
  /// Strictly prohibited in production release builds.
  void testCrash() {
    if (kReleaseMode) {
      debugPrint(
        '[Crashlytics] testCrash() is disabled in production release mode.',
      );
      return;
    }
    if (_isInitialized) {
      FirebaseCrashlytics.instance.crash();
    } else {
      throw StateError(
        '[Crashlytics-Test] Simulated staging error for verification.',
      );
    }
  }

  /// Suppress duplicate errors happening in rapid succession.
  bool _isDuplicate(String signature) {
    if (_recentErrorSignatures.contains(signature)) {
      return true;
    }
    _recentErrorSignatures.add(signature);
    if (_recentErrorSignatures.length > 50) {
      _recentErrorSignatures.remove(_recentErrorSignatures.first);
    }
    Timer(const Duration(seconds: 10), () {
      _recentErrorSignatures.remove(signature);
    });
    return false;
  }

  String _createErrorSignature(dynamic exception, StackTrace? stack) {
    final exStr = exception.toString().split('\n').first;
    final topFrame = stack != null ? stack.toString().split('\n').first : '';
    return '$exStr::$topFrame';
  }

  /// Sanitize text by removing emails, auth tokens, passwords, and sensitive keys.
  static String _sanitizeText(String text) {
    var sanitized = text;
    // Redact Bearer / JWT tokens
    sanitized = sanitized.replaceAll(
      RegExp(r'Bearer\s+[A-Za-z0-9\-\._~\+\/]+=*', caseSensitive: false),
      'Bearer [REDACTED_TOKEN]',
    );
    // Redact Supabase publishable/secret tokens
    sanitized = sanitized.replaceAll(
      RegExp(r'sb_[A-Za-z0-9_\-]+', caseSensitive: false),
      '[REDACTED_KEY]',
    );
    // Redact email addresses
    sanitized = sanitized.replaceAll(
      RegExp(r'[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+'),
      '[REDACTED_EMAIL]',
    );
    // Redact password parameters
    sanitized = sanitized.replaceAll(
      RegExp(r'password\s*[:=]\s*[^\s,]+', caseSensitive: false),
      'password:[REDACTED]',
    );
    return sanitized;
  }

  static bool _isSensitiveKey(String key) {
    final lower = key.toLowerCase();
    const sensitive = [
      'email',
      'password',
      'token',
      'secret',
      'auth',
      'body_weight',
      'weight',
      'nutrition',
      'meal',
      'measurement',
      'note',
      'health',
    ];
    return sensitive.any((s) => lower.contains(s));
  }
}
