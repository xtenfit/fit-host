import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/core/data/workout_repository.dart';
import 'package:fit_host/core/data/nutrition_repository.dart';
import 'package:fit_host/core/data/hydration_repository.dart';
import 'package:fit_host/core/data/steps_repository.dart';
import 'package:fit_host/core/services/supabase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Part 2: Hybrid Backend Selection & Hot-Swap Tests', () {
    late AppDatabase memoryDb;

    setUp(() {
      memoryDb = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await memoryDb.close();
    });

    test('Guest mode resolves to Local Drift-only repositories for all domains', () {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(memoryDb),
        ],
      );
      addTearDown(container.dispose);

      // Verify default auth is guest
      final authState = container.read(authProvider);
      expect(authState.status, equals(AuthStatus.guest));
      expect(authState.isGuest, isTrue);
      expect(authState.isAuthenticated, isFalse);

      // Verify all factory providers resolve to Local* implementations
      final workoutRepo = container.read(workoutRepositoryProvider);
      expect(workoutRepo, isA<LocalWorkoutRepository>());

      final nutritionRepo = container.read(nutritionRepositoryProvider);
      expect(nutritionRepo, isA<LocalNutritionRepository>());

      final hydrationRepo = container.read(hydrationRepositoryProvider);
      expect(hydrationRepo, isA<LocalHydrationRepository>());

      final stepsRepo = container.read(stepsRepositoryProvider);
      expect(stepsRepo, isA<LocalStepsRepository>());
    });

    test('Authenticated mode hot-swaps repositories to Cloud implementations', () {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(memoryDb),
        ],
      );
      addTearDown(container.dispose);

      // Initially in guest mode
      expect(container.read(workoutRepositoryProvider), isA<LocalWorkoutRepository>());

      // Create a mock authenticated user
      final mockUser = User(
        id: 'user-auth-uuid-999',
        appMetadata: {},
        userMetadata: {'name': 'Cloud Athlete'},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );

      // Authenticate
      container.read(authProvider.notifier).setManualAuthenticatedUser(mockUser);

      final authState = container.read(authProvider);
      expect(authState.status, equals(AuthStatus.authenticated));
      expect(authState.user?.id, equals('user-auth-uuid-999'));

      // Verify all repositories automatically hot-swap to Cloud* implementations
      final workoutRepo = container.read(workoutRepositoryProvider);
      expect(workoutRepo, isA<CloudWorkoutRepository>());
      expect((workoutRepo as CloudWorkoutRepository).userId, equals('user-auth-uuid-999'));

      final nutritionRepo = container.read(nutritionRepositoryProvider);
      expect(nutritionRepo, isA<CloudNutritionRepository>());
      expect((nutritionRepo as CloudNutritionRepository).userId, equals('user-auth-uuid-999'));

      final hydrationRepo = container.read(hydrationRepositoryProvider);
      expect(hydrationRepo, isA<CloudHydrationRepository>());
      expect((hydrationRepo as CloudHydrationRepository).userId, equals('user-auth-uuid-999'));

      final stepsRepo = container.read(stepsRepositoryProvider);
      expect(stepsRepo, isA<CloudStepsRepository>());
      expect((stepsRepo as CloudStepsRepository).userId, equals('user-auth-uuid-999'));

      // Sign out back to guest
      container.read(authProvider.notifier).setManualGuest();
      expect(container.read(authProvider).status, equals(AuthStatus.guest));

      // Hot-swaps back to Local implementations seamlessly
      expect(container.read(workoutRepositoryProvider), isA<LocalWorkoutRepository>());
      expect(container.read(nutritionRepositoryProvider), isA<LocalNutritionRepository>());
      expect(container.read(hydrationRepositoryProvider), isA<LocalHydrationRepository>());
      expect(container.read(stepsRepositoryProvider), isA<LocalStepsRepository>());
    });
  });
}
