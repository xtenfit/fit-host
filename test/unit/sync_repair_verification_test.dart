import 'dart:convert';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/core/sync/sync_utils.dart';
import 'package:fit_host/core/sync/sync_outbox_worker.dart';
import 'package:fit_host/core/connectivity/connectivity_state_machine.dart';
import 'package:fit_host/core/services/supabase_service.dart';

void main() {
  group('Phase 1 & 2: Schema Reconciliation & Table Mapping Unit Tests', () {
    test(
      'resolveSupabaseTable maps singular and plural entity types canonically',
      () {
        expect(
          resolveSupabaseTable('body_measurement'),
          equals('body_measurements'),
        );
        expect(
          resolveSupabaseTable('body_measurements'),
          equals('body_measurements'),
        );
        expect(
          resolveSupabaseTable('bodymeasurement'),
          equals('body_measurements'),
        );
        expect(resolveSupabaseTable('profile'), equals('profiles'));
        expect(resolveSupabaseTable('profiles'), equals('profiles'));
        expect(resolveSupabaseTable('workout'), equals('workouts'));
        expect(resolveSupabaseTable('workouts'), equals('workouts'));
        expect(
          resolveSupabaseTable('progress_photo'),
          equals('progress_photos'),
        );
        expect(resolveSupabaseTable('routine'), equals('routines'));
        expect(resolveSupabaseTable('step_daily'), equals('step_daily_logs'));
        expect(resolveSupabaseTable('steps'), equals('step_daily_logs'));
        expect(resolveSupabaseTable('nutrition'), equals('nutrition_logs'));
        expect(resolveSupabaseTable('hydration'), equals('hydration_logs'));
        expect(
          resolveSupabaseTable('progression_setting'),
          equals('progression_settings'),
        );
      },
    );

    test(
      'resolveConflictTarget returns appropriate unique constraint columns',
      () {
        expect(resolveConflictTarget('profiles'), equals('id'));
        expect(
          resolveConflictTarget('progression_settings'),
          equals('user_id'),
        );
        expect(resolveConflictTarget('body_measurements'), equals('id'));
        expect(resolveConflictTarget('workouts'), equals('id'));
        expect(resolveConflictTarget('routines'), equals('id'));
        expect(
          resolveConflictTarget('nutrition_logs'),
          equals('user_id, log_date'),
        );
        expect(
          resolveConflictTarget('step_daily_logs'),
          equals('user_id, step_date'),
        );
        expect(resolveConflictTarget('reminder_schedules'), equals('id'));
      },
    );

    test(
      'sanitizeOutboxPayload strips local Drift metadata and validates user ownership',
      () {
        final raw = {
          'id': 'guest_meas_123',
          'weight_kg': 75.5,
          'sync_status': 'pending',
          'syncStatus': 'pending',
          'is_synced': false,
          'local_id': 'local_99',
        };

        const testUserId = '11111111-2222-3333-4444-555555555555';
        final sanitized = sanitizeOutboxPayload(
          'body_measurements',
          raw,
          testUserId,
        );

        expect(sanitized.containsKey('sync_status'), isFalse);
        expect(sanitized.containsKey('syncStatus'), isFalse);
        expect(sanitized.containsKey('is_synced'), isFalse);
        expect(sanitized.containsKey('local_id'), isFalse);
        expect(sanitized['user_id'], equals(testUserId));
        expect(sanitized['id'], equals('${testUserId}_meas_123'));
      },
    );

    test('sanitizeOutboxPayload handles profiles with both id and user_id', () {
      const testUserId = '4540d387-5125-4145-bf69-26927497ca8d';
      final raw = {
        'activity_level': 'moderately_active',
        'display_name': 'Amit Rana',
        'sync_status': 'synced',
      };

      final sanitized = sanitizeOutboxPayload('profiles', raw, testUserId);
      expect(sanitized['id'], equals(testUserId));
      expect(sanitized['user_id'], equals(testUserId));
      expect(sanitized['activity_level'], equals('moderately_active'));
      expect(sanitized.containsKey('sync_status'), isFalse);
    });
  });

  group('Phase 3 & 7: Error Classification and Diagnostics Unit Tests', () {
    test(
      'classifySyncError categorizes PostgREST missing column / schema cache errors',
      () {
        final error = PostgrestException(
          message:
              "Could not find the 'activity_level' column of 'profiles' in the schema cache",
          code: 'PGRST204',
        );

        final classified = classifySyncError(error);
        expect(classified.category, equals('Missing Database Schema'));
        expect(classified.isRetryable, isTrue);
        expect(classified.isPermanent, isFalse);
        expect(classified.userFriendlyMessage, contains('schema'));
      },
    );

    test('classifySyncError categorizes PostgREST missing table errors', () {
      final error = PostgrestException(
        message:
            "Could not find the table 'public.body_measurement' in the schema cache",
        code: 'PGRST205',
      );

      final classified = classifySyncError(error);
      expect(classified.category, equals('Missing Database Schema'));
      expect(classified.isRetryable, isTrue);
      expect(classified.isPermanent, isFalse);
    });

    test(
      'classifySyncError categorizes RLS permission denied as non-retryable permanent error',
      () {
        final error = PostgrestException(
          message:
              'new row violates row-level security policy for table "body_measurements"',
          code: '42501',
        );

        final classified = classifySyncError(error);
        expect(classified.category, equals('Permission Denied (RLS)'));
        expect(classified.isPermanent, isTrue);
        expect(classified.isRetryable, isFalse);
      },
    );

    test('classifySyncError redacts bearer tokens and api keys', () {
      final error = Exception(
        'Failed request with Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.secret and apikey: super_secret_key',
      );
      final classified = classifySyncError(error);
      expect(classified.diagnosticDetail.contains('Bearer [REDACTED]'), isTrue);
      expect(
        classified.diagnosticDetail.contains('apikey: [REDACTED]'),
        isTrue,
      );
      expect(classified.diagnosticDetail.contains('super_secret_key'), isFalse);
    });

    test(
      'classifySyncError identifies network timeouts and socket failures as retryable',
      () {
        final error = Exception(
          'SocketException: Failed host lookup: eedubttdylyqrhyeikwb.supabase.co',
        );
        final classified = classifySyncError(error);
        expect(classified.category, equals('Network Unavailable'));
        expect(classified.isRetryable, isTrue);
        expect(classified.isPermanent, isFalse);
      },
    );
  });

  group('Phase 4: Account Isolation and Cache Cleansing Unit Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'clearAccountCache removes private user measurements while preserving guest measurements',
      () async {
        const userA = '11111111-1111-1111-1111-111111111111';
        const guestId = 'guest';

        // Insert User A measurements
        await db
            .into(db.bodyMeasurements)
            .insert(
              BodyMeasurementsCompanion.insert(
                id: 'meas_user_a',
                userId: const Value(userA),
                measuredAt: DateTime.now().toUtc(),
                weightKg: const Value(80.0),
                createdAt: Value(DateTime.now().toUtc()),
                updatedAt: Value(DateTime.now().toUtc()),
              ),
            );

        // Insert Guest measurement
        await db
            .into(db.bodyMeasurements)
            .insert(
              BodyMeasurementsCompanion.insert(
                id: 'meas_guest',
                userId: const Value(guestId),
                measuredAt: DateTime.now().toUtc(),
                weightKg: const Value(70.0),
                createdAt: Value(DateTime.now().toUtc()),
                updatedAt: Value(DateTime.now().toUtc()),
              ),
            );

        // Clear User A account cache on logout
        await db.clearAccountCache(userA);

        final remaining = await db.select(db.bodyMeasurements).get();
        expect(remaining.length, equals(1));
        expect(remaining.first.id, equals('meas_guest'));
        expect(remaining.first.userId, equals(guestId));
      },
    );
  });

  group('Phase 3 & 6: Outbox Drain and Manual Sync Now Unit Tests', () {
    late AppDatabase db;
    late SyncOutboxWorker worker;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'SyncOutboxWorker successfully processes body_measurement and profiles via mock processor',
      () async {
        final processedItems = <SyncQueueData>[];
        worker = SyncOutboxWorker(
          db: db,
          supabase: null,
          mockItemProcessor: (item) async {
            processedItems.add(item);
          },
        );

        const userId = '4540d387-5125-4145-bf69-26927497ca8d';
        final now = DateTime.now().toUtc();

        // Enqueue body_measurement
        await db
            .into(db.syncQueue)
            .insert(
              SyncQueueCompanion.insert(
                id: 'queue_1',
                userId: const Value(userId),
                entityType: 'body_measurement',
                entityId: 'meas_999',
                operation: 'upsert',
                payload: jsonEncode({'id': 'meas_999', 'weight_kg': 72.5}),
                createdAt: now,
                clientTimestamp: Value(now),
                status: const Value('queued'),
              ),
            );

        // Enqueue profile
        await db
            .into(db.syncQueue)
            .insert(
              SyncQueueCompanion.insert(
                id: 'queue_2',
                userId: const Value(userId),
                entityType: 'profile',
                entityId: userId,
                operation: 'upsert',
                payload: jsonEncode({
                  'id': userId,
                  'activity_level': 'moderately_active',
                }),
                createdAt: now,
                clientTimestamp: Value(now),
                status: const Value('queued'),
              ),
            );

        final count = await worker.drainQueue(
          overrideConnectivity: ConnectivityStatus.online,
          overrideAuth: AuthStatus.authenticated,
        );

        expect(count, equals(2));
        expect(processedItems.length, equals(2));
        expect(processedItems[0].entityType, equals('body_measurement'));
        expect(processedItems[1].entityType, equals('profile'));

        // Verify syncQueue is now empty
        final remaining = await db.select(db.syncQueue).get();
        expect(remaining.isEmpty, isTrue);
      },
    );

    test(
      'forceRetry bypasses exponential backoff and retries failed operations immediately',
      () async {
        int attemptsCount = 0;
        worker = SyncOutboxWorker(
          db: db,
          supabase: null,
          mockItemProcessor: (item) async {
            attemptsCount++;
          },
        );

        const userId = '4540d387-5125-4145-bf69-26927497ca8d';
        final now = DateTime.now().toUtc();

        // Item that recently failed and has backoff requirement
        await db
            .into(db.syncQueue)
            .insert(
              SyncQueueCompanion.insert(
                id: 'queue_failed_1',
                userId: const Value(userId),
                entityType: 'body_measurement',
                entityId: 'meas_failed',
                operation: 'upsert',
                payload: jsonEncode({'id': 'meas_failed', 'weight_kg': 65.0}),
                createdAt: now,
                clientTimestamp: Value(now),
                status: const Value('failed'),
                attempts: const Value(4),
                attemptCount: const Value(4),
                lastAttemptAt: Value(
                  now,
                ), // Just attempted 0s ago, normally needs >24s delay
              ),
            );

        // Drain without forceRetry -> skips because of backoff
        final countWithoutForce = await worker.drainQueue(
          overrideConnectivity: ConnectivityStatus.online,
          overrideAuth: AuthStatus.authenticated,
          forceRetry: false,
        );
        expect(countWithoutForce, equals(0));
        expect(attemptsCount, equals(0));

        // Drain with forceRetry (Manual Sync Now) -> processes immediately!
        final countWithForce = await worker.drainQueue(
          overrideConnectivity: ConnectivityStatus.online,
          overrideAuth: AuthStatus.authenticated,
          forceRetry: true,
        );
        expect(countWithForce, equals(1));
        expect(attemptsCount, equals(1));
      },
    );
  });
}
