import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database.dart';
import '../connectivity/connectivity_state_machine.dart';
import '../services/supabase_service.dart';
import 'sync_utils.dart';

enum SyncDrainResult {
  completed,
  skipped,
  partialError,
  offline,
}

class SyncCoordinator {
  final AppDatabase db;
  final SupabaseClient? supabase;
  final Ref? ref;
  final Random _random = Random();

  bool _isDraining = false;
  static const int maxAttempts = 8;
  static const double maxBackoffSeconds = 300.0;

  SyncCoordinator({
    required this.db,
    required this.supabase,
    this.ref,
  });

  /// Exponential backoff formula:
  /// delay = min(300s, 2^attempts × 1.5s) ± 20% jitter
  Duration calculateBackoff(int attempts) {
    if (attempts <= 0) return Duration.zero;
    final exp = min(attempts, 8);
    final baseSeconds = pow(2, exp) * 1.5;
    final capped = min(maxBackoffSeconds, baseSeconds.toDouble());
    // ± 20% jitter
    final jitterFactor = 0.8 + (_random.nextDouble() * 0.4); // 0.8 to 1.2
    final finalSeconds = capped * jitterFactor;
    return Duration(milliseconds: (finalSeconds * 1000).toInt());
  }

  /// Determines if synchronization can proceed:
  /// (auth == authenticated || auth == offlineGrace) && (connectivity == online || connectivity == metered)
  bool canSync({
    required AuthStatus authStatus,
    required ConnectivityStatus connectivityStatus,
  }) {
    final authOk = (authStatus == AuthStatus.authenticated ||
        authStatus == AuthStatus.offlineGrace);
    final netOk = (connectivityStatus == ConnectivityStatus.online ||
        connectivityStatus == ConnectivityStatus.metered);
    return authOk && netOk;
  }

  /// Drains pending outbox mutations from sync_queue
  Future<int> drain({
    AuthStatus? overrideAuth,
    ConnectivityStatus? overrideConnectivity,
  }) async {
    if (_isDraining) return 0;
    _isDraining = true;

    try {
      final auth = overrideAuth ?? _getEffectiveAuth();
      final connectivity =
          overrideConnectivity ?? _getEffectiveConnectivity();

      if (!canSync(authStatus: auth, connectivityStatus: connectivity)) {
        debugPrint(
            '[SyncCoordinator] Skipping sync: auth=$auth, connectivity=$connectivity');
        return 0;
      }

      final now = DateTime.now().toUtc();
      // Select queued items eligible for processing (skip guest mutations until claimed)
      final items = await (db.select(db.syncQueue)
            ..where((t) =>
                t.status.isIn(['queued', 'failed', 'pending']) &
                t.userId.isNotValue('guest'))
            ..orderBy([(t) => OrderingTerm(expression: t.clientTimestamp)]))
          .get();

      int processed = 0;

      for (final item in items) {
        // Check if exceeded max attempts -> move to dead_letter
        if (item.attempts >= maxAttempts) {
          await (db.update(db.syncQueue)..where((t) => t.id.equals(item.id)))
              .write(
            SyncQueueCompanion(
              status: const Value('dead_letter'),
              errorLog: Value('Exceeded max $maxAttempts retry attempts.'),
              lastAttemptAt: Value(now),
            ),
          );
          continue;
        }

        // Apply backoff check for failed attempts
        if (item.attempts > 0 && item.lastAttemptAt != null) {
          final requiredDelay = calculateBackoff(item.attempts);
          if (now.difference(item.lastAttemptAt!) < requiredDelay) {
            continue; // Not yet ready
          }
        }

        // Mark in-flight
        await (db.update(db.syncQueue)..where((t) => t.id.equals(item.id)))
            .write(
          SyncQueueCompanion(
            status: const Value('in_flight'),
            lastAttemptAt: Value(now),
          ),
        );

        try {
          await _processQueueItem(item);

          // Mark completed / delete from sync_queue
          await (db.delete(db.syncQueue)..where((t) => t.id.equals(item.id)))
              .go();
          processed++;
        } catch (e) {
          final nextAttempts = item.attempts + 1;
          final isDeadLetter = nextAttempts >= maxAttempts;
          await (db.update(db.syncQueue)..where((t) => t.id.equals(item.id)))
              .write(
            SyncQueueCompanion(
              attempts: Value(nextAttempts),
              attemptCount: Value(nextAttempts),
              status: Value(isDeadLetter ? 'dead_letter' : 'failed'),
              lastError: Value(e.toString()),
              errorLog: Value(e.toString()),
              lastAttemptAt: Value(DateTime.now().toUtc()),
            ),
          );
        }
      }

      return processed;
    } finally {
      _isDraining = false;
    }
  }

  Future<void> _processQueueItem(SyncQueueData item) async {
    if (supabase == null) {
      throw Exception('Supabase client is not configured.');
    }

    // Never sync non-UUID / guest items to Supabase
    if (!isValidUuid(item.userId)) {
      debugPrint('[SyncCoordinator] Skipping remote sync for non-UUID / guest item: ${item.id}');
      return;
    }

    final Map<String, dynamic> payload =
        jsonDecode(item.payload) as Map<String, dynamic>;

    // Confirm user_id is sent explicitly by client on every insert
    payload['user_id'] = item.userId;

    if (payload['id'] != null && (payload['id'] as String).contains('guest')) {
      payload['id'] = (payload['id'] as String).replaceAll('guest', item.userId);
    }

    final table = _mapTable(item.entityType);

    if (item.operation.toUpperCase() == 'DELETE') {
      if (item.entityId.contains('guest')) {
        return;
      }
      await supabase!.from(table).update({
        'is_deleted': true,
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).match({
        'id': item.entityId,
        'user_id': item.userId,
      });
      return;
    }

    // Idempotent upsert via Supabase with onConflict: 'id'
    await supabase!.from(table).upsert(payload, onConflict: 'id');
  }

  String _mapTable(String entityType) {
    switch (entityType.toLowerCase()) {
      case 'workout':
      case 'workouts':
        return 'workouts';
      case 'workout_exercise':
      case 'workoutexercises':
        return 'workout_exercises';
      case 'workout_set':
      case 'workoutsets':
        return 'workout_sets';
      case 'nutrition':
      case 'nutrition_log':
      case 'nutrition_logs':
        return 'nutrition_logs';
      case 'hydration':
      case 'hydration_log':
      case 'hydration_logs':
        return 'hydration_logs';
      case 'step_daily':
      case 'steps':
        return 'step_daily';
      case 'event':
      case 'calendar_event':
      case 'calendar_events':
      case 'events':
        return 'calendar_events';
      case 'reminder':
      case 'reminders':
        return 'reminders';
      case 'profile':
      case 'profiles':
        return 'profiles';
      default:
        return entityType.toLowerCase();
    }
  }

  AuthStatus _getEffectiveAuth() {
    if (ref == null) return AuthStatus.guest;
    try {
      return ref!.read(authProvider).status;
    } catch (_) {
      return AuthStatus.guest;
    }
  }

  ConnectivityStatus _getEffectiveConnectivity() {
    if (ref == null) return ConnectivityStatus.online;
    try {
      return ref!.read(connectivityStateMachineProvider).currentStatus;
    } catch (_) {
      return ConnectivityStatus.online;
    }
  }
}

final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  final db = ref.watch(databaseProvider);
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (_) {}

  final coordinator = SyncCoordinator(
    db: db,
    supabase: client,
    ref: ref,
  );

  // Auto-listen to connectivity and auth changes to trigger drain
  ref.listen(connectivityProvider, (prev, next) {
    if (next.value == ConnectivityStatus.online ||
        next.value == ConnectivityStatus.metered) {
      coordinator.drain().ignore();
    }
  });

  ref.listen(authProvider, (prev, next) {
    if (next.status == AuthStatus.authenticated) {
      coordinator.drain().ignore();
    }
  });

  return coordinator;
});
