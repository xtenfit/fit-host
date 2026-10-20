import 'dart:convert';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/core/services/supabase_service.dart';
import 'package:fit_host/core/connectivity/connectivity_state_machine.dart';
import 'package:fit_host/core/sync/sync_outbox_worker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Part 2 Blockers Verification: Auth Refresh & Outbox Gate Tests', () {
    late ProviderContainer container;
    late AppDatabase memoryDb;

    setUp(() {
      container = ProviderContainer();
      memoryDb = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      container.dispose();
      await memoryDb.close();
    });

    test('refreshSession() fails with SocketException -> state == offlineGrace, keeps user', () async {
      final authService = container.read(authProvider.notifier);

      final mockUser = User(
        id: 'user-athlete-offline-1',
        appMetadata: {},
        userMetadata: {'name': 'Offline Athlete'},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );

      // Seed authenticated state
      authService.setManualAuthenticatedUser(mockUser);
      expect(container.read(authProvider).status, equals(AuthStatus.authenticated));
      expect(container.read(authProvider).isAuthenticated, isTrue);

      // Trigger refreshSession failing with real SocketException (no network / host unreachable)
      await authService.refreshSession(
        customRefreshAction: () async {
          throw const SocketException('Failed host lookup: eeudbttdtylqrhyeikwb.supabase.co');
        },
      );

      final state = container.read(authProvider);
      // Critical assertion: must be offlineGrace, user preserved, not downgraded to guest
      expect(state.status, equals(AuthStatus.offlineGrace));
      expect(state.isOfflineGrace, isTrue);
      expect(state.isAuthenticated, isTrue);
      expect(state.isGuest, isFalse);
      expect(state.supabaseUser?.id, equals('user-athlete-offline-1'));
    });

    test('refreshSession() fails with AuthException(401) -> state == signedOut', () async {
      final authService = container.read(authProvider.notifier);

      final mockUser = User(
        id: 'user-athlete-revoked-1',
        appMetadata: {},
        userMetadata: {'name': 'Revoked Athlete'},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );

      authService.setManualAuthenticatedUser(mockUser);
      expect(container.read(authProvider).status, equals(AuthStatus.authenticated));

      // Trigger refreshSession failing with real AuthException(401 / revoked token)
      await authService.refreshSession(
        customRefreshAction: () async {
          throw const AuthException(
            'Invalid Refresh Token: Refresh Token Not Found',
            statusCode: '401',
          );
        },
      );

      final state = container.read(authProvider);
      // Critical assertion: revoked token transitions strictly to signedOut
      expect(state.status, equals(AuthStatus.signedOut));
      expect(state.isAuthenticated, isFalse);
      expect(state.errorMessage, contains('Invalid Refresh Token'));
    });

    test('SyncOutboxWorker called while offline -> attemptCount stays 0', () async {
      final now = DateTime.now().toUtc();
      await memoryDb.into(memoryDb.syncQueue).insert(
            SyncQueueCompanion.insert(
              id: 'queue-offline-gate-1',
              userId: const Value('athlete-uid-101'),
              entityType: 'workout',
              entityId: 'workout-101',
              operation: 'INSERT',
              payload: jsonEncode({'id': 'workout-101', 'title': 'Morning Sprints'}),
              createdAt: now,
              clientTimestamp: Value(now),
              status: const Value('pending'),
              attempts: const Value(0),
              attemptCount: const Value(0),
            ),
          );

      final worker = SyncOutboxWorker(
        db: memoryDb,
        supabase: null,
      );

      // Gate: called while offline
      final drainedCount = await worker.drainQueue(
        overrideConnectivity: ConnectivityStatus.offline,
      );

      // Returns 0 without processing
      expect(drainedCount, equals(0));

      // Item in sync_queue MUST retain attempts == 0 and attemptCount == 0
      final queueItem = await memoryDb.select(memoryDb.syncQueue).getSingle();
      expect(queueItem.status, equals('pending'));
      expect(queueItem.attempts, equals(0));
      expect(queueItem.attemptCount, equals(0));
      expect(queueItem.lastAttemptAt, isNull);
    });

    test('SyncOutboxWorker called while connectivity==online and auth==offlineGrace -> drains queue successfully', () async {
      final now = DateTime.now().toUtc();
      await memoryDb.into(memoryDb.syncQueue).insert(
            SyncQueueCompanion.insert(
              id: 'queue-grace-drain-1',
              userId: const Value('athlete-uid-202'),
              entityType: 'nutrition_logs',
              entityId: 'nutrition-202',
              operation: 'upsert',
              payload: jsonEncode({'id': 'nutrition-202', 'water_glasses': 8}),
              createdAt: now,
              clientTimestamp: Value(now),
              status: const Value('pending'),
              attempts: const Value(0),
              attemptCount: const Value(0),
            ),
          );

      bool mutationProcessed = false;
      final worker = SyncOutboxWorker(
        db: memoryDb,
        supabase: null,
        mockItemProcessor: (item) async {
          mutationProcessed = true;
        },
      );

      // Gate: called with connectivity == online AND auth == offlineGrace
      final drainedCount = await worker.drainQueue(
        overrideConnectivity: ConnectivityStatus.online,
        overrideAuth: AuthStatus.offlineGrace,
      );

      // Queue successfully drained
      expect(drainedCount, equals(1));
      expect(mutationProcessed, isTrue);

      final remaining = await memoryDb.select(memoryDb.syncQueue).get();
      expect(remaining.isEmpty, isTrue);
    });
  });
}
