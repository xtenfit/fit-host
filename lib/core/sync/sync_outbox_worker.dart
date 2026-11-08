import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart';
import '../services/connectivity_service.dart';
import '../connectivity/connectivity_state_machine.dart';
import '../services/supabase_service.dart';
import '../services/profile_avatar_service.dart';
import 'sync_utils.dart';

class SyncOutboxWorker {
  final AppDatabase db;
  final SupabaseClient? supabase;
  final ConnectivityService? connectivity;
  final Ref? ref;
  final Future<void> Function(SyncQueueData item)? mockItemProcessor;
  final Random _random = Random();

  bool _isDraining = false;
  Timer? _periodicTimer;

  static const int maxRetries = 8;
  static const Duration baseDelay = Duration(milliseconds: 1500);
  static const Duration maxDelay = Duration(minutes: 5);

  SyncOutboxWorker({
    required this.db,
    required this.supabase,
    this.connectivity,
    this.ref,
    this.mockItemProcessor,
  });

  void startPeriodicDrain({Duration interval = const Duration(seconds: 30)}) {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(interval, (_) {
      drainQueue().ignore();
    });
  }

  void stopPeriodicDrain() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  /// Calculates exponential backoff with ±20% jitter:
  /// delay = min(300s, 2^attempts * 1.5s) ± 20%
  Duration calculateBackoff(int attempts, {bool withJitter = true}) {
    if (attempts <= 0) return Duration.zero;
    final exp = min(attempts, 8);
    final baseSeconds = pow(2, exp) * 1.5;
    final capped = min(300.0, baseSeconds.toDouble());
    if (!withJitter) {
      return Duration(milliseconds: (capped * 1000).toInt());
    }
    // ±20% jitter (factor between 0.8 and 1.2)
    final jitterFactor = 0.8 + (_random.nextDouble() * 0.4);
    final finalSeconds = capped * jitterFactor;
    return Duration(milliseconds: (finalSeconds * 1000).toInt());
  }

  /// Adds a mutation to the local Drift sync_queue outbox.
  /// user_id is passed and stored explicitly.
  Future<void> enqueueMutation({
    required String userId,
    required String entityType,
    required String entityId,
    required String operation, // 'INSERT', 'UPDATE', 'DELETE'
    required Map<String, dynamic> payload,
  }) async {
    // Explicitly enforce that userId is present in the mutation payload
    final payloadWithUserId = Map<String, dynamic>.from(payload);
    payloadWithUserId['user_id'] = userId;
    final now = DateTime.now().toUtc();

    await db
        .into(db.syncQueue)
        .insertOnConflictUpdate(
          SyncQueueCompanion.insert(
            id: const Uuid().v4(),
            userId: Value(userId),
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            payload: jsonEncode(payloadWithUserId),
            createdAt: now,
            clientTimestamp: Value(now),
            attempts: const Value(0),
            attemptCount: const Value(0),
            status: const Value('pending'),
          ),
        );

    // Trigger immediate drain if online
    drainQueue().ignore();
  }

  /// Drains all eligible pending mutations with exponential backoff and server-wins conflict resolution.
  /// Gated strictly on connectivityProvider == online. If not online, returns without incrementing attemptCount.
  Future<int> drainQueue({
    ConnectivityStatus? overrideConnectivity,
    AuthStatus? overrideAuth,
    bool forceRetry = false,
  }) async {
    if (_isDraining) return 0;

    // Connectivity Gate: MUST be online
    final ConnectivityStatus effectiveConnectivity;
    if (overrideConnectivity != null) {
      effectiveConnectivity = overrideConnectivity;
    } else if (ref != null) {
      effectiveConnectivity = ref!
          .read(connectivityStateMachineProvider)
          .currentStatus;
    } else if (connectivity != null) {
      final isOnline = await connectivity!.hasInternetConnection();
      effectiveConnectivity = isOnline
          ? ConnectivityStatus.online
          : ConnectivityStatus.offline;
    } else {
      effectiveConnectivity = ConnectivityStatus.offline;
    }

    if (effectiveConnectivity != ConnectivityStatus.online) {
      debugPrint(
        '[SyncOutboxWorker] Skipping drain: device is not online (status: $effectiveConnectivity). Attempt count remains unchanged.',
      );
      return 0;
    }

    // Auth Gate: guest or unauthenticated cannot drain outbox
    final AuthStatus? effectiveAuth;
    if (overrideAuth != null) {
      effectiveAuth = overrideAuth;
    } else if (ref != null) {
      effectiveAuth = ref!.read(authStatusProvider);
    } else {
      effectiveAuth = null;
    }

    if (effectiveAuth != null &&
        effectiveAuth != AuthStatus.authenticated &&
        effectiveAuth != AuthStatus.offlineGrace) {
      debugPrint(
        '[SyncOutboxWorker] Skipping drain: auth status is $effectiveAuth.',
      );
      return 0;
    }

    if (supabase == null && mockItemProcessor == null) return 0;

    _isDraining = true;
    int processedCount = 0;

    try {
      final now = DateTime.now().toUtc();
      // Fetch pending or failed items that have not exceeded max retries (guest data is held local-only until account claiming)
      final statusList = forceRetry
          ? ['pending', 'failed', 'queued', 'dead_letter']
          : ['pending', 'failed', 'queued'];

      final items =
          await (db.select(db.syncQueue)
                ..where(
                  (t) =>
                      t.status.isIn(statusList) &
                      t.userId.isNotValue('guest') &
                      (forceRetry
                          ? const Constant(true)
                          : t.attempts.isSmallerThanValue(maxRetries)),
                )
                ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
              .get();

      for (final item in items) {
        // Enforce backoff if item previously failed and not forceRetry
        if (!forceRetry && item.attempts > 0 && item.lastAttemptAt != null) {
          final waitDuration = calculateBackoff(item.attempts);
          if (now.difference(item.lastAttemptAt!) < waitDuration) {
            continue; // Not yet eligible for retry
          }
        }

        // Mark item in_flight
        await (db.update(
          db.syncQueue,
        )..where((t) => t.id.equals(item.id))).write(
          SyncQueueCompanion(
            status: const Value('in_flight'),
            lastAttemptAt: Value(now),
          ),
        );

        try {
          await _processMutationItem(item);

          // Mark completed and remove from queue
          await (db.delete(
            db.syncQueue,
          )..where((t) => t.id.equals(item.id))).go();
          processedCount++;
        } catch (e) {
          debugPrint('[SyncOutboxWorker] Mutation failed for ${item.id}: $e');
          final classified = classifySyncError(e);
          final isPermanent = classified.isPermanent;
          final newAttempts = isPermanent ? maxRetries : item.attempts + 1;
          final newStatus = (newAttempts >= maxRetries || isPermanent)
              ? 'dead_letter'
              : 'failed';

          await (db.update(
            db.syncQueue,
          )..where((t) => t.id.equals(item.id))).write(
            SyncQueueCompanion(
              status: Value(newStatus),
              attempts: Value(newAttempts),
              attemptCount: Value(newAttempts),
              lastError: Value(classified.userFriendlyMessage),
              errorLog: Value(
                '${classified.category}: ${classified.userFriendlyMessage}',
              ),
              lastAttemptAt: Value(DateTime.now().toUtc()),
            ),
          );
        }
      }
    } finally {
      _isDraining = false;
    }

    return processedCount;
  }

  Future<void> _processMutationItem(SyncQueueData item) async {
    if (mockItemProcessor != null) {
      await mockItemProcessor!(item);
      return;
    }

    // Never attempt remote sync with non-UUID or guest user_id (causes Postgres invalid input syntax)
    if (!isValidUuid(item.userId)) {
      debugPrint(
        '[SyncOutboxWorker] Skipping remote sync for non-UUID / guest mutation (${item.entityType}:${item.entityId}). Held for account claim.',
      );
      return;
    }

    final client = supabase;
    if (client == null) {
      throw Exception('Supabase client is not available.');
    }

    final Map<String, dynamic> rawPayload =
        jsonDecode(item.payload) as Map<String, dynamic>;

    final tableName = resolveSupabaseTable(item.entityType);
    final sanitizedPayload = sanitizeOutboxPayload(
      tableName,
      rawPayload,
      item.userId,
    );
    final conflictTarget = resolveConflictTarget(tableName) ?? 'id';

    // If syncing a profile mutation, ensure custom device photos are uploaded to cloud storage
    // while asset/default avatars bypass storage upload without logging errors
    if (tableName == 'profiles') {
      final avatarVal = sanitizedPayload['avatar_url'];
      if (avatarVal is String &&
          ProfileAvatarService.isCustomDeviceAvatar(avatarVal)) {
        final uploaded = await ProfileAvatarService.syncAvatarToRemoteStorage(
          userId: item.userId,
          localOrRemotePath: avatarVal,
          client: client,
        );
        if (uploaded != null && uploaded.isNotEmpty) {
          sanitizedPayload['avatar_url'] = uploaded;
        }
      }
    }

    if (item.operation.toUpperCase() == 'DELETE') {
      if (item.entityId.contains('guest')) {
        // Guest item was never created remotely; local deletion is acknowledged
        return;
      }
      final matchMap = <String, Object>{conflictTarget: item.entityId};
      if (conflictTarget == 'id' && tableName != 'profiles') {
        matchMap['user_id'] = item.userId;
      }
      try {
        await client
            .from(tableName)
            .update({
              'is_deleted': true,
              'deleted_at': DateTime.now().toUtc().toIso8601String(),
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .match(matchMap);
      } catch (_) {
        await client.from(tableName).delete().match(matchMap);
      }
      return;
    }

    // Check for server conflict: server updated_at wins
    final matchMap = <String, Object>{};
    if (conflictTarget.contains(',')) {
      final cols = conflictTarget.split(',').map((c) => c.trim()).toList();
      for (final col in cols) {
        if (sanitizedPayload.containsKey(col) && sanitizedPayload[col] != null) {
          matchMap[col] = sanitizedPayload[col] as Object;
        }
      }
      if (!matchMap.containsKey('user_id')) {
        matchMap['user_id'] = item.userId;
      }
    } else if (conflictTarget == 'id') {
      matchMap['id'] = item.entityId;
      if (tableName != 'profiles') {
        matchMap['user_id'] = item.userId;
      }
    } else {
      matchMap[conflictTarget] = item.entityId;
    }

    try {
      final existingResponse = await client
          .from(tableName)
          .select('updated_at')
          .match(matchMap)
          .maybeSingle();

      if (existingResponse != null && existingResponse['updated_at'] != null) {
        final serverUpdatedAt = DateTime.tryParse(
          existingResponse['updated_at'] as String,
        );
        final clientUpdatedAt = sanitizedPayload['updated_at'] != null
            ? DateTime.tryParse(sanitizedPayload['updated_at'] as String)
            : null;

        if (serverUpdatedAt != null &&
            clientUpdatedAt != null &&
            serverUpdatedAt.isAfter(clientUpdatedAt)) {
          // Server record is newer: server updated_at wins!
          debugPrint(
            '[SyncOutboxWorker] Conflict detected on $tableName (${item.entityId}). Server timestamp ($serverUpdatedAt) wins over client ($clientUpdatedAt).',
          );
          // Discard local client overwrite
          return;
        }
      }
    } catch (e) {
      debugPrint('[SyncOutboxWorker] Pre-check conflict query notice: $e');
    }

    // Upsert explicitly with conflict target and resilient composite key resolution
    try {
      await client
          .from(tableName)
          .upsert(sanitizedPayload, onConflict: conflictTarget);
    } on PostgrestException catch (e) {
      if ((e.code == '23505' ||
              e.message.contains('unique constraint') ||
              e.message.contains('duplicate key')) &&
          (tableName == 'nutrition_logs' ||
              tableName == 'step_daily_logs' ||
              tableName == 'hydration_logs')) {
        final uniqueDateCol = tableName == 'step_daily_logs'
            ? 'step_date'
            : 'log_date';
        final dateVal = sanitizedPayload[uniqueDateCol];
        if (dateVal != null) {
          debugPrint(
            '[SyncOutboxWorker] Recovering from 23505 conflict on $tableName. Updating row ($uniqueDateCol: $dateVal)...',
          );
          final updatePayload = Map<String, dynamic>.from(sanitizedPayload);
          updatePayload.remove('id');
          await client.from(tableName).update(updatePayload).match({
            'user_id': item.userId,
            uniqueDateCol: dateVal,
          });
          return;
        }
      }
      rethrow;
    }
  }
}

final syncOutboxWorkerProvider = Provider<SyncOutboxWorker>((ref) {
  final db = ref.watch(databaseProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (_) {}

  final worker = SyncOutboxWorker(
    db: db,
    supabase: client,
    connectivity: connectivity,
    ref: ref,
  );

  worker.startPeriodicDrain();
  ref.onDispose(() => worker.stopPeriodicDrain());
  return worker;
});
