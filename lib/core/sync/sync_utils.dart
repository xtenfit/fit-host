/// Validation utilities for Supabase UUID foreign keys and sync payloads.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

final _uuidRegex = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// Returns true if [id] is a valid non-guest RFC 4122 UUID.
bool isValidUuid(String? id) {
  if (id == null || id.isEmpty || id.trim().toLowerCase() == 'guest') {
    return false;
  }
  return _uuidRegex.hasMatch(id.trim());
}

/// Exhaustive canonical resolution from client entity type to Supabase table.
String resolveSupabaseTable(String entityType) {
  switch (entityType.trim().toLowerCase()) {
    case 'workout':
    case 'workouts':
      return 'workouts';
    case 'workout_exercise':
    case 'workoutexercise':
    case 'workoutexercises':
    case 'workout_exercises':
      return 'workout_exercises';
    case 'workout_set':
    case 'workoutset':
    case 'workoutsets':
    case 'workout_sets':
      return 'workout_sets';
    case 'body_measurement':
    case 'body_measurements':
    case 'bodymeasurement':
    case 'bodymeasurements':
      return 'body_measurements';
    case 'progress_photo':
    case 'progress_photos':
    case 'progressphoto':
    case 'progressphotos':
      return 'progress_photos';
    case 'routine':
    case 'routines':
      return 'routines';
    case 'routine_exercise':
    case 'routine_exercises':
      return 'routine_exercises';
    case 'routine_set':
    case 'routine_sets':
      return 'routine_sets';
    case 'personal_record':
    case 'personal_records':
      return 'personal_records';
    case 'progression_setting':
    case 'progression_settings':
      return 'progression_settings';
    case 'nutrition':
    case 'nutrition_log':
    case 'nutrition_logs':
      return 'nutrition_logs';
    case 'diary_entry':
    case 'daily_diary_entries':
    case 'daily_diary_entry':
    case 'diary_entries':
      return 'daily_diary_entries';
    case 'calorie_adjustment':
    case 'calorie_adjustments':
      return 'calorie_adjustments';
    case 'hydration':
    case 'hydration_log':
    case 'hydration_logs':
      return 'hydration_logs';
    case 'step_daily':
    case 'step_daily_logs':
    case 'steps':
      return 'step_daily_logs';
    case 'event':
    case 'events':
    case 'calendar_event':
    case 'calendar_events':
      return 'calendar_events';
    case 'reminder':
    case 'reminders':
    case 'reminder_schedule':
    case 'reminder_schedules':
      return 'reminder_schedules';
    case 'profile':
    case 'profiles':
      return 'profiles';
    case 'food_item':
    case 'food_items':
      return 'food_items';
    case 'exercise_submission':
    case 'exercise_submissions':
      return 'exercise_submissions';
    case 'exercise_id_mappings':
    case 'exercise_mappings':
      return 'exercise_id_mappings';
    case 'notification':
    case 'notification_inbox':
    case 'notifications':
      return 'notification_inbox';
    default:
      final lower = entityType.trim().toLowerCase();
      // Defensive fallback: pluralize common singulars if unmapped
      if (lower == 'body_measurement') return 'body_measurements';
      if (lower == 'progress_photo') return 'progress_photos';
      return lower;
  }
}

/// Returns the primary conflict target column for Supabase upserts.
String? resolveConflictTarget(String table) {
  switch (table.toLowerCase()) {
    case 'profiles':
      return 'id';
    case 'progression_settings':
      return 'user_id';
    case 'nutrition_logs':
      return 'user_id,log_date';
    case 'step_daily_logs':
      return 'user_id,step_date';
    case 'hydration_logs':
      return 'user_id,log_date';
    case 'reminder_schedules':
    case 'reminders':
      return 'id';
    case 'workouts':
    case 'workout_exercises':
    case 'workout_sets':
    case 'body_measurements':
    case 'progress_photos':
    case 'routines':
    case 'routine_exercises':
    case 'routine_sets':
    case 'personal_records':
    case 'food_items':
    case 'calendar_events':
    case 'exercise_submissions':
    case 'notification_inbox':
    case 'daily_diary_entries':
    case 'calorie_adjustments':
      return 'id';
    default:
      return 'id';
  }
}

/// Cleans client payload of local Drift-only metadata and ensures valid ownership fields.
Map<String, dynamic> sanitizeOutboxPayload(
  String table,
  Map<String, dynamic> rawPayload,
  String userId,
) {
  final payload = Map<String, dynamic>.from(rawPayload);

  // Strip local SQLite / Drift cache fields that do not exist on PostgreSQL
  payload.remove('sync_status');
  payload.remove('syncStatus');
  payload.remove('is_synced');
  payload.remove('local_id');

  // Remap any lingering guest id prefixes
  if (payload['id'] != null &&
      payload['id'] is String &&
      (payload['id'] as String).contains('guest')) {
    payload['id'] = (payload['id'] as String).replaceAll('guest', userId);
  }

  // Set ownership and enforce table-specific schema invariants
  if (table == 'profiles') {
    payload['id'] = userId;
    payload['user_id'] = userId;

    // Sanitize non-positive values to prevent constraint checks on fresh/draft profiles
    if (payload['age'] != null && (payload['age'] as num) <= 0) {
      payload['age'] = null;
    }
    if (payload['height_cm'] != null && (payload['height_cm'] as num) <= 0) {
      payload['height_cm'] = null;
    }
    if (payload['weight_kg'] != null && (payload['weight_kg'] as num) <= 0) {
      payload['weight_kg'] = null;
    }
    if (payload['gender'] == null ||
        (payload['gender'] is String && (payload['gender'] as String).trim().isEmpty)) {
      payload['gender'] = 'other';
    }

    if (payload['email'] == null ||
        (payload['email'] as String).trim().isEmpty) {
      try {
        final email = Supabase.instance.client.auth.currentUser?.email;
        payload['email'] = (email != null && email.isNotEmpty)
            ? email
            : 'athlete@fithost.app';
      } catch (_) {
        payload['email'] = 'athlete@fithost.app';
      }
    }
  } else if (table == 'reminder_schedules' || table == 'reminders') {
    // Only schedule time records are stored in cloud DB; alarm engine details stay local on device
    payload['user_id'] = userId;
    payload.remove('sound_enabled');
    payload.remove('vibration_enabled');
    payload.remove('snooze_duration_minutes');
    payload.remove('last_triggered_at');
    payload.remove('last_completed_at');
    payload.remove('is_dismissed');
    payload.remove('delivery_mode');
    payload.remove('alarm_tone');
    payload.remove('tts_announcement');
  } else if (table == 'step_daily_logs') {
    payload['user_id'] = userId;
    if (payload.containsKey('step_count') && !payload.containsKey('steps')) {
      payload['steps'] = payload.remove('step_count');
    } else {
      payload.remove('step_count');
    }
    if (payload.containsKey('target_step_count') &&
        !payload.containsKey('target_steps')) {
      payload['target_steps'] = payload.remove('target_step_count');
    } else {
      payload.remove('target_step_count');
    }
  } else if (table != 'routine_exercises' && table != 'routine_sets') {
    // Child routine exercises/sets are keyed by parent foreign key, others have user_id
    payload['user_id'] = userId;
  }

  return payload;
}

class ClassifiedSyncError {
  final String category;
  final String userFriendlyMessage;
  final String diagnosticDetail;
  final bool isPermanent;
  final bool isRetryable;

  const ClassifiedSyncError({
    required this.category,
    required this.userFriendlyMessage,
    required this.diagnosticDetail,
    required this.isPermanent,
    required this.isRetryable,
  });
}

/// Classifies sync errors into actionable support categories with secrets and raw tokens redacted.
ClassifiedSyncError classifySyncError(dynamic error) {
  if (error == null) {
    return const ClassifiedSyncError(
      category: 'Unknown',
      userFriendlyMessage: 'An unknown synchronization error occurred.',
      diagnosticDetail: 'No details provided.',
      isPermanent: false,
      isRetryable: true,
    );
  }

  final rawStr = error.toString();
  final lower = rawStr.toLowerCase();

  // Redact API keys, bearer tokens, passwords
  final sanitized = rawStr
      .replaceAll(
        RegExp(r'Bearer\s+[A-Za-z0-9\-._~+/]+=*', caseSensitive: false),
        'Bearer [REDACTED]',
      )
      .replaceAll(
        RegExp(r'apikey:\s*[A-Za-z0-9\-._~+/]+', caseSensitive: false),
        'apikey: [REDACTED]',
      )
      .replaceAll(
        RegExp(r'sb_publishable_[A-Za-z0-9_\-]+', caseSensitive: false),
        '[REDACTED_PUBLISHABLE_KEY]',
      )
      .replaceAll(
        RegExp(r'service_role', caseSensitive: false),
        '[REDACTED_ROLE]',
      );

  if (error is PostgrestException) {
    final code = error.code ?? '';
    final msg = error.message;

    // Missing column or missing table in schema cache (e.g. PGRST204, PGRST205)
    if (code == 'PGRST204' ||
        code == 'PGRST205' ||
        msg.contains("Could not find the") ||
        msg.contains("column of") ||
        msg.contains("in the schema cache")) {
      return ClassifiedSyncError(
        category: 'Missing Database Schema',
        userFriendlyMessage:
            'A required cloud database table or column is missing or refreshing. Retry after schema check.',
        diagnosticDetail: 'PostgREST ($code): $sanitized',
        isPermanent: false, // Retryable after schema update/cache reload
        isRetryable: true,
      );
    }

    // Row-level security / Permission denied (42501)
    if (code == '42501' ||
        msg.contains('permission denied') ||
        msg.contains('violates row-level security')) {
      return ClassifiedSyncError(
        category: 'Permission Denied (RLS)',
        userFriendlyMessage:
            'Account authorization policy denied write access to this record.',
        diagnosticDetail: 'PostgreSQL 42501: $sanitized',
        isPermanent: true,
        isRetryable: false,
      );
    }

    // Unique constraint violation (23505)
    if (code == '23505' ||
        msg.contains('duplicate key value') ||
        msg.contains('unique constraint')) {
      return ClassifiedSyncError(
        category: 'Conflict',
        userFriendlyMessage:
            'A conflicting record already exists in the cloud.',
        diagnosticDetail: 'PostgreSQL 23505: $sanitized',
        isPermanent: false,
        isRetryable: true,
      );
    }

    // Foreign key violation (23503)
    if (code == '23503' || msg.contains('violates foreign key constraint')) {
      return ClassifiedSyncError(
        category: 'Payload Validation',
        userFriendlyMessage:
            'Referenced parent record does not exist on the server.',
        diagnosticDetail: 'PostgreSQL 23503: $sanitized',
        isPermanent: true,
        isRetryable: false,
      );
    }

    return ClassifiedSyncError(
      category: 'Database Error',
      userFriendlyMessage: 'Database rejected record: $msg',
      diagnosticDetail: 'PostgrestException: $sanitized',
      isPermanent: false,
      isRetryable: true,
    );
  }

  if (error is AuthException ||
      lower.contains('jwt') ||
      lower.contains('session expired') ||
      lower.contains('token has expired') ||
      lower.contains('invalid claim')) {
    return ClassifiedSyncError(
      category: 'Session Expired',
      userFriendlyMessage:
          'Your cloud session has expired. Sign in again to resume syncing.',
      diagnosticDetail: sanitized,
      isPermanent: false,
      isRetryable: true,
    );
  }

  if (lower.contains('socketexception') ||
      lower.contains('network') ||
      lower.contains('failed host lookup') ||
      lower.contains('clientexception') ||
      lower.contains('connection refused') ||
      lower.contains('connection timed out') ||
      lower.contains('handshake') ||
      lower.contains('no address associated with hostname')) {
    return ClassifiedSyncError(
      category: 'Network Unavailable',
      userFriendlyMessage:
          'Could not connect to Fit Host cloud. Will retry automatically when online.',
      diagnosticDetail: sanitized,
      isPermanent: false,
      isRetryable: true,
    );
  }

  if (lower.contains('rate limit') ||
      lower.contains('429') ||
      lower.contains('too many requests')) {
    return ClassifiedSyncError(
      category: 'Rate Limited',
      userFriendlyMessage:
          'Cloud sync rate limit exceeded. Pausing before next attempt.',
      diagnosticDetail: sanitized,
      isPermanent: false,
      isRetryable: true,
    );
  }

  return ClassifiedSyncError(
    category: 'Server Error',
    userFriendlyMessage: 'Server could not process request: $sanitized',
    diagnosticDetail: sanitized,
    isPermanent: false,
    isRetryable: true,
  );
}
