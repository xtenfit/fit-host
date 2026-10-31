import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/core/services/supabase_service.dart';
import 'package:fit_host/core/connectivity/connectivity_state_machine.dart';
import 'package:fit_host/features/nutrition/data/services/gemini_nutrition_service.dart';
import 'package:fit_host/features/profile/presentation/widgets/sync_status_indicator.dart';
import 'package:fit_host/features/workouts/data/repositories/workout_repository_impl.dart';
import 'package:fit_host/features/workouts/domain/models/workout_models.dart';

class _MockAuthNotifier extends AuthService {
  final AuthStatus _status;
  _MockAuthNotifier([this._status = AuthStatus.authenticated]);

  @override
  AuthState build() => AuthState(
    status: _status,
    email: _status == AuthStatus.authenticated ? 'test@fithost.com' : null,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Master Bug Fixes Verification Tests', () {
    test(
      '1 litre Maja parses accurately with 1.05 density and correct macros',
      () async {
        final service = GeminiNutritionService();
        final draft = await service.analyzeMealText('1 litre Maja');

        expect(draft.estimatedIngredients.isNotEmpty, isTrue);
        final ing = draft.estimatedIngredients.first;
        expect(ing.name.toLowerCase(), contains('maja'));
        // 1 litre * 1000 * 1.05 = 1050g
        expect(ing.estimatedGrams, equals(1050.0));
        // per 100g: 0.1g P, 13.5g C, 0.1g F, 54 kcal
        expect(ing.carbsPer100g, equals(13.5));
        expect(ing.caloriesPer100g, equals(54.0));
        // Total calories for 1050g = 1050 * 54 / 100 = 567 kcal
        expect(ing.calories.round(), equals(567));
      },
    );

    test('1 kg chicken parses as 1000g with high protein', () async {
      final service = GeminiNutritionService();
      final draft = await service.analyzeMealText('1 kg chicken');

      expect(draft.estimatedIngredients.isNotEmpty, isTrue);
      final ing = draft.estimatedIngredients.first;
      expect(ing.name.toLowerCase(), contains('chicken'));
      expect(ing.estimatedGrams, equals(1000.0));
      expect(ing.proteinPer100g, equals(31.0));
    });

    test(
      'SyncStatusNotifier reflects Pending Sync when outbox has pending items',
      () async {
        final container = ProviderContainer(
          overrides: [
            authProvider.overrideWith(
              () => _MockAuthNotifier(AuthStatus.authenticated),
            ),
            connectivityProvider.overrideWith(
              (ref) => Stream.value(ConnectivityStatus.online),
            ),
            pendingSyncCountProvider.overrideWith((ref) => Stream.value(1)),
            failedSyncCountProvider.overrideWith((ref) => Stream.value(0)),
          ],
        );

        addTearDown(container.dispose);

        final sub = container.listen(syncStatusStateProvider, (prev, next) {});
        addTearDown(sub.close);

        await Future<void>.delayed(const Duration(milliseconds: 20));

        final stateWithPending = container.read(syncStatusStateProvider);
        expect(stateWithPending.label, equals('Pending Sync (1 change)'));
        expect(stateWithPending.compactLabel, equals('Pending (1)'));
      },
    );

    test(
      'SyncStatusNotifier reflects Sync Error when outbox has failed items',
      () async {
        final container = ProviderContainer(
          overrides: [
            authProvider.overrideWith(
              () => _MockAuthNotifier(AuthStatus.authenticated),
            ),
            connectivityProvider.overrideWith(
              (ref) => Stream.value(ConnectivityStatus.online),
            ),
            pendingSyncCountProvider.overrideWith((ref) => Stream.value(0)),
            failedSyncCountProvider.overrideWith((ref) => Stream.value(1)),
          ],
        );

        addTearDown(container.dispose);

        final sub = container.listen(syncStatusStateProvider, (prev, next) {});
        addTearDown(sub.close);

        await Future<void>.delayed(const Duration(milliseconds: 20));

        final stateWithFailed = container.read(syncStatusStateProvider);
        expect(stateWithFailed.label, contains('Sync Error (1 item)'));
      },
    );

    test(
      'Drift syncQueue query correctly filters pending and failed counts',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(() => db.close().ignore());

        await db
            .into(db.syncQueue)
            .insert(
              SyncQueueCompanion.insert(
                id: 'test-sync-1',
                userId: const Value('00000000-0000-0000-0000-000000000001'),
                entityType: 'workout',
                entityId: 'w-1',
                operation: 'upsert',
                payload: jsonEncode({'id': 'w-1'}),
                createdAt: DateTime.now().toUtc(),
                status: const Value('queued'),
              ),
            );

        final pendingList = await (db.select(
          db.syncQueue,
        )..where((t) => t.status.isIn(['queued', 'failed', 'pending']))).get();
        expect(pendingList.length, equals(1));
      },
    );

    test(
      'Guest workout deletion does not create un-drainable remote sync delete entries',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final guestRepo = WorkoutRepositoryImpl(db, userId: 'guest');

        final now = DateTime.now().toUtc();
        final workout = WorkoutEntity(
          id: 'guest-workout-1',
          title: 'Guest Morning Run',
          startedAt: now,
          status: 'completed',
          durationSeconds: 1200,
          updatedAt: now,
        );

        await guestRepo.saveWorkout(workout);

        // Verify guest workout was created locally
        final retrieved = await guestRepo.getWorkoutById('guest-workout-1');
        expect(retrieved, isNotNull);

        // Delete the guest workout
        await guestRepo.deleteWorkout('guest-workout-1');

        // Verify it was deleted from local Drift workouts
        final afterDelete = await guestRepo.getWorkoutById('guest-workout-1');
        expect(afterDelete == null, isTrue);

        // Verify NO delete mutation was added to sync_queue for this guest workout
        final deleteItems =
            await (db.select(db.syncQueue)..where(
                  (t) =>
                      t.entityId.equals('guest-workout-1') &
                      t.operation.equals('delete'),
                ))
                .get();
        expect(deleteItems, isEmpty);

        // Verify any pending insert was also cleaned up
        final anyItems = await (db.select(
          db.syncQueue,
        )..where((t) => t.entityId.equals('guest-workout-1'))).get();
        expect(anyItems, isEmpty);

        await db.close();
      },
    );
  });
}
