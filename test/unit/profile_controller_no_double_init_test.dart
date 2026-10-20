import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/features/profile/presentation/controllers/user_profile_controller.dart';
import 'package:fit_host/core/data/profile_repository.dart';

class _FakeProfileRepository implements UserProfileRepository {
  UserProfile? storedProfile;

  @override
  Future<UserProfile> loadProfile() async {
    return storedProfile ??
        UserProfile.calculateSuggestedTargets(
          name: 'Fake Athlete',
          age: 25,
          gender: 'female',
          heightCm: 168.0,
          weightKg: 62.0,
          targetWeightKg: 58.0,
          fitnessGoal: 'lose_weight',
          dietType: 'balanced',
          weeklyWorkoutDays: 4,
          dailyWorkoutMinutes: 45,
          isCompleted: true,
        );
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    storedProfile = profile;
  }

  @override
  Future<void> resetProfile() async {
    storedProfile = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserProfileController Initialization Regression Tests', () {
    late ProviderContainer container;
    late _FakeProfileRepository fakeRepo;
    late AppDatabase inMemoryDb;

    setUp(() {
      inMemoryDb = AppDatabase(NativeDatabase.memory());
      fakeRepo = _FakeProfileRepository();
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(inMemoryDb),
          userProfileRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await inMemoryDb.close();
    });

    test('Initializes state without LateInitializationError', () {
      expect(() => container.read(userProfileProvider), returnsNormally);
      final profile = container.read(userProfileProvider);
      expect(profile.name, isNotEmpty);
    });

    test('Multiple sequential updates do not trigger LateInitializationError or crashes', () async {
      final notifier = container.read(userProfileProvider.notifier);
      // Wait for async load to finish
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await expectLater(
        notifier.saveSuggestedPlan(
          name: 'Power Athlete',
          age: 28,
          gender: 'male',
          heightCm: 180,
          weightKg: 80,
          fitnessGoal: 'gain_weight',
          dietType: 'high_protein',
          weeklyWorkoutDays: 5,
          dailyWorkoutMinutes: 60,
        ),
        completes,
      );

      final updated = container.read(userProfileProvider);
      expect(updated.name, equals('Power Athlete'));
      expect(updated.weeklyWorkoutDays, equals(5));

      // Second immediate save
      await expectLater(
        notifier.updateProfile(updated.copyWith(name: 'Updated Athlete')),
        completes,
      );

      expect(container.read(userProfileProvider).name, equals('Updated Athlete'));
    });
  });
}
