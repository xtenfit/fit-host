import 'dart:convert';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/core/sync/sync_coordinator.dart';
import 'package:fit_host/core/connectivity/connectivity_state_machine.dart';
import 'package:fit_host/core/services/supabase_service.dart';

void main() {
  group('Part 2: SyncCoordinator Unit Tests', () {
    late AppDatabase memoryDb;
    late SyncCoordinator coordinator;

    setUp(() {
      memoryDb = AppDatabase(NativeDatabase.memory());
      coordinator = SyncCoordinator(
        db: memoryDb,
        supabase: null,
      );
    });

    tearDown(() async {
      await memoryDb.close();
    });

    test('canSync evaluates auth and connectivity conditions correctly', () {
      // offline -> no drain
      expect(
        coordinator.canSync(
          authStatus: AuthStatus.authenticated,
          connectivityStatus: ConnectivityStatus.offline,
        ),
        isFalse,
      );

      // auth=guest -> no drain
      expect(
        coordinator.canSync(
          authStatus: AuthStatus.guest,
          connectivityStatus: ConnectivityStatus.online,
        ),
        isFalse,
      );

      // auth=authenticating -> no drain
      expect(
        coordinator.canSync(
          authStatus: AuthStatus.authenticating,
          connectivityStatus: ConnectivityStatus.online,
        ),
        isFalse,
      );

      // auth=authenticated + online -> can sync
      expect(
        coordinator.canSync(
          authStatus: AuthStatus.authenticated,
          connectivityStatus: ConnectivityStatus.online,
        ),
        isTrue,
      );

      // auth=offlineGrace + online -> can sync
      expect(
        coordinator.canSync(
          authStatus: AuthStatus.offlineGrace,
          connectivityStatus: ConnectivityStatus.online,
        ),
        isTrue,
      );

      // auth=authenticated + metered -> can sync
      expect(
        coordinator.canSync(
          authStatus: AuthStatus.authenticated,
          connectivityStatus: ConnectivityStatus.metered,
        ),
        isTrue,
      );
    });

    test('offline -> does not drain queued mutations', () async {
      final now = DateTime.now().toUtc();
      await memoryDb.into(memoryDb.syncQueue).insert(
            SyncQueueCompanion.insert(
              id: 'queue-test-1',
              userId: const Value('auth-user-1'),
              entityType: 'workout',
              entityId: 'w-1',
              operation: 'upsert',
              payload: jsonEncode({'id': 'w-1', 'title': 'Chest Day'}),
              createdAt: now,
              clientTimestamp: Value(now),
              status: const Value('queued'),
            ),
          );

      final processed = await coordinator.drain(
        overrideAuth: AuthStatus.authenticated,
        overrideConnectivity: ConnectivityStatus.offline,
      );

      expect(processed, equals(0));

      final item = await memoryDb.select(memoryDb.syncQueue).getSingle();
      expect(item.status, equals('queued'));
      expect(item.attempts, equals(0));
    });

    test('auth=guest -> does not drain queued mutations', () async {
      final now = DateTime.now().toUtc();
      await memoryDb.into(memoryDb.syncQueue).insert(
            SyncQueueCompanion.insert(
              id: 'queue-test-2',
              userId: const Value('guest'),
              entityType: 'workout',
              entityId: 'w-2',
              operation: 'upsert',
              payload: jsonEncode({'id': 'w-2', 'title': 'Leg Day'}),
              createdAt: now,
              clientTimestamp: Value(now),
              status: const Value('queued'),
            ),
          );

      final processed = await coordinator.drain(
        overrideAuth: AuthStatus.guest,
        overrideConnectivity: ConnectivityStatus.online,
      );

      expect(processed, equals(0));

      final item = await memoryDb.select(memoryDb.syncQueue).getSingle();
      expect(item.status, equals('queued'));
    });

    test('exponential backoff increases with attempts and obeys upper bound', () {
      expect(coordinator.calculateBackoff(0), equals(Duration.zero));

      final d1 = coordinator.calculateBackoff(1);
      final d2 = coordinator.calculateBackoff(2);
      final d3 = coordinator.calculateBackoff(3);
      final d4 = coordinator.calculateBackoff(4);

      // Verify exponential progression: 2^1 * 1.5s = 3s (±20%), 2^2 * 1.5s = 6s, 2^3 * 1.5s = 12s, 2^4 * 1.5s = 24s
      expect(d1.inMilliseconds, greaterThan(2000));
      expect(d2.inMilliseconds, greaterThan(d1.inMilliseconds));
      expect(d3.inMilliseconds, greaterThan(d2.inMilliseconds));
      expect(d4.inMilliseconds, greaterThan(d3.inMilliseconds));

      // Ceiling at 300s (5 minutes) ± 20%
      final dHigh = coordinator.calculateBackoff(20);
      expect(dHigh.inSeconds, lessThanOrEqualTo(360));
    });

    test('network failure increases attempts, updates errorLog, and does not loop infinitely', () async {
      final now = DateTime.now().toUtc();
      await memoryDb.into(memoryDb.syncQueue).insert(
            SyncQueueCompanion.insert(
              id: 'queue-test-fail',
              userId: const Value('auth-user-1'),
              entityType: 'workout',
              entityId: 'w-fail',
              operation: 'upsert',
              payload: jsonEncode({'id': 'w-fail', 'title': 'Back Day'}),
              createdAt: now,
              clientTimestamp: Value(now),
              status: const Value('queued'),
            ),
          );

      // Drain will fail since supabase client is null (simulating network / connection failure)
      final processed = await coordinator.drain(
        overrideAuth: AuthStatus.authenticated,
        overrideConnectivity: ConnectivityStatus.online,
      );

      expect(processed, equals(0));

      final item = await memoryDb.select(memoryDb.syncQueue).getSingle();
      expect(item.status, equals('failed'));
      expect(item.attempts, equals(1));
      expect(item.attemptCount, equals(1));
      expect(item.errorLog, isNotNull);
      expect(item.lastAttemptAt, isNotNull);
    });

    test('item exceeding max attempts moves to dead_letter status', () async {
      final now = DateTime.now().toUtc();
      await memoryDb.into(memoryDb.syncQueue).insert(
            SyncQueueCompanion.insert(
              id: 'queue-test-max',
              userId: const Value('auth-user-1'),
              entityType: 'workout',
              entityId: 'w-max',
              operation: 'upsert',
              payload: jsonEncode({'id': 'w-max', 'title': 'Should Die'}),
              createdAt: now,
              clientTimestamp: Value(now),
              status: const Value('failed'),
              attempts: const Value(8), // At max attempts threshold
              attemptCount: const Value(8),
            ),
          );

      await coordinator.drain(
        overrideAuth: AuthStatus.authenticated,
        overrideConnectivity: ConnectivityStatus.online,
      );

      final item = await memoryDb.select(memoryDb.syncQueue).getSingle();
      expect(item.status, equals('dead_letter'));
      expect(item.errorLog, contains('Exceeded max 8 retry attempts.'));
    });
  });
}
