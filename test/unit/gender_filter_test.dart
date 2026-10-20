import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/core/data/workout_repository.dart';
import 'package:fit_host/features/workouts/presentation/controllers/workout_providers.dart';
import 'package:fit_host/features/profile/presentation/controllers/user_profile_controller.dart';
import 'package:fit_host/features/profile/domain/models/user_profile.dart';

class MockProfileNotifier extends UserProfileNotifier {
  final UserProfile _initial;
  MockProfileNotifier(this._initial);

  @override
  UserProfile build() => _initial;
}

void main() {
  group('Gender-specific exercise filtering tests', () {
    late AppDatabase db;
    late LocalWorkoutRepository repo;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = LocalWorkoutRepository(db);
      await repo.seedDefaultExercises();
    });

    tearDown(() async {
      await db.close();
    });

    test('default filter in ProviderContainer matches male user gender', () {
      final container = ProviderContainer(
        overrides: [
          userProfileProvider.overrideWith(() =>
              MockProfileNotifier(UserProfile.defaultGuest().copyWith(gender: 'male'))),
        ],
      );
      addTearDown(container.dispose);

      final filter = container.read(exercisesFilterProvider);
      expect(filter.genderFilter, equals('male'));
    });

    test('default filter in ProviderContainer matches female user gender', () {
      final container = ProviderContainer(
        overrides: [
          userProfileProvider.overrideWith(() =>
              MockProfileNotifier(UserProfile.defaultGuest().copyWith(gender: 'female'))),
        ],
      );
      addTearDown(container.dispose);

      final filter = container.read(exercisesFilterProvider);
      expect(filter.genderFilter, equals('female'));
    });

    test('female filter includes female-focus seeded exercises and all', () async {
      final exercises = await repo.getExercises(genderFilter: 'female');
      final names = exercises.map((e) => e.name).toList();

      // Female focus exercises must be present
      expect(names, contains('Hip Thrust (Barbell)'));
      expect(names, contains('Glute Bridge'));
      expect(names, contains('Bulgarian Split Squat'));
      expect(names, contains('Cable Kickback'));
      expect(names, contains('Hip Abduction (Machine)'));
      expect(names, contains('Step-ups'));

      // Male-only focus exercises must be excluded
      expect(names, isNot(contains('Incline Barbell Press')));
      expect(names, isNot(contains('Arnold Press')));
      expect(names, isNot(contains('Cable Crossover')));
      expect(names, isNot(contains('Dumbbell Pullover')));
    });

    test('male filter includes male-focus seeded exercises and all', () async {
      final exercises = await repo.getExercises(genderFilter: 'male');
      final names = exercises.map((e) => e.name).toList();

      // Male focus exercises must be present
      expect(names, contains('Bench Press (Barbell)'));
      expect(names, contains('Incline Barbell Press'));
      expect(names, contains('Arnold Press'));
      expect(names, contains('Cable Crossover'));
      expect(names, contains('Lateral Raise (Dumbbell)'));
      expect(names, contains('Dumbbell Pullover'));

      // Female-only focus exercises must be excluded
      expect(names, isNot(contains('Hip Thrust (Barbell)')));
      expect(names, isNot(contains('Cable Kickback')));
      expect(names, isNot(contains('Glute Bridge')));
      expect(names, isNot(contains('Hip Abduction (Machine)')));
    });

    test('Show all reset returns all exercises regardless of gender focus', () async {
      final container = ProviderContainer(
        overrides: [
          userProfileProvider.overrideWith(() =>
              MockProfileNotifier(UserProfile.defaultGuest().copyWith(gender: 'male'))),
        ],
      );
      addTearDown(container.dispose);

      // Initially male
      expect(container.read(exercisesFilterProvider).genderFilter, equals('male'));

      // Reset to all
      container.read(exercisesFilterProvider.notifier).resetToAll();
      expect(container.read(exercisesFilterProvider).genderFilter, equals('All'));

      final allExercises = await repo.getExercises(genderFilter: 'All');
      final allNames = allExercises.map((e) => e.name).toList();

      // Contains both female and male focus exercises
      expect(allNames, contains('Hip Thrust (Barbell)'));
      expect(allNames, contains('Bench Press (Barbell)'));
      expect(allNames, contains('Standard Push-Up'));
    });
  });
}
