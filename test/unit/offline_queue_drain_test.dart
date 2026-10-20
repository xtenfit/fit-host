import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/core/sync/sync_outbox_worker.dart';
import 'package:fit_host/core/services/connectivity_service.dart';

class TestConnectivityService implements ConnectivityService {
  bool isOnline;
  TestConnectivityService({this.isOnline = true});

  @override
  Future<bool> hasInternetConnection() async => isOnline;

  @override
  Stream<bool> get onConnectivityChanged => Stream.value(isOnline);
}

void main() {
  group('Part 2: Offline Outbox Queue & Drain Tests', () {
    late AppDatabase memoryDb;
    late TestConnectivityService connectivity;
    late SyncOutboxWorker worker;

    setUp(() {
      memoryDb = AppDatabase(NativeDatabase.memory());
      connectivity = TestConnectivityService(isOnline: false);
      worker = SyncOutboxWorker(
        db: memoryDb,
        supabase: null,
        connectivity: connectivity,
      );
    });

    tearDown(() async {
      await memoryDb.close();
    });

    test('Exponential backoff calculation adheres to exponential curve with upper bound and jitter', () {
      expect(worker.calculateBackoff(0), equals(Duration.zero));
      expect(worker.calculateBackoff(1, withJitter: false), equals(const Duration(milliseconds: 3000)));
      expect(worker.calculateBackoff(2, withJitter: false), equals(const Duration(milliseconds: 6000)));
      expect(worker.calculateBackoff(3, withJitter: false), equals(const Duration(milliseconds: 12000)));

      // With jitter (±20% range)
      final j1 = worker.calculateBackoff(1);
      expect(j1.inMilliseconds, greaterThanOrEqualTo(2400));
      expect(j1.inMilliseconds, lessThanOrEqualTo(3600));

      // High attempts do not exceed maximum backoff ceiling (300s ± 20%)
      final maxBackoff = worker.calculateBackoff(20);
      expect(maxBackoff.inSeconds, lessThanOrEqualTo(360));
    });

    test('Enqueueing mutation stores payload with explicit user_id', () async {
      const userId = 'auth-uid-777';
      const entityId = 'workout-alpha-1';

      await worker.enqueueMutation(
        userId: userId,
        entityType: 'workouts',
        entityId: entityId,
        operation: 'INSERT',
        payload: {
          'id': entityId,
          'title': 'Evening Core & Flexibility',
          'started_at': DateTime.now().toIso8601String(),
        },
      );

      final queue = await memoryDb.select(memoryDb.syncQueue).get();
      expect(queue.length, equals(1));

      final item = queue.first;
      expect(item.userId, equals(userId));
      expect(item.entityType, equals('workouts'));
      expect(item.entityId, equals(entityId));
      expect(item.operation, equals('INSERT'));
      expect(item.status, equals('pending'));
      expect(item.attempts, equals(0));

      final decodedPayload = jsonDecode(item.payload) as Map<String, dynamic>;
      // Condition 6: Confirm user_id is sent explicitly by client on every insert
      expect(decodedPayload['user_id'], equals(userId));
      expect(decodedPayload['title'], equals('Evening Core & Flexibility'));
    });

    test('Offline guard prevents queue draining when connection is unavailable', () async {
      connectivity.isOnline = false;

      await worker.enqueueMutation(
        userId: 'auth-uid-888',
        entityType: 'hydration_logs',
        entityId: 'hydration-log-1',
        operation: 'INSERT',
        payload: {'water_glasses': 8},
      );

      final drainedCount = await worker.drainQueue();
      expect(drainedCount, equals(0));

      // Item remains intact in pending state
      final item = await memoryDb.select(memoryDb.syncQueue).getSingle();
      expect(item.status, equals('pending'));
      expect(item.attempts, equals(0));
    });
  });
}
