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
          userProfileProvider.overrideWith(
            () => MockProfileNotifier(
              UserProfile.defaultGuest().copyWith(gender: 'male'),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final filter = container.read(exercisesFilterProvider);
      expect(filter.genderFilter, equals('male'));
    });

    test('default filter in ProviderContainer matches female user gender', () {
      final container = ProviderContainer(
        overrides: [
          userProfileProvider.overrideWith(
            () => MockProfileNotifier(
              UserProfile.defaultGuest().copyWith(gender: 'female'),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final filter = container.read(exercisesFilterProvider);
      expect(filter.genderFilter, equals('female'));
    });

    test(
      'female filter includes universal exercises (universal exercises are never hidden)',
      () async {
        final exercises = await repo.getExercises(genderFilter: 'female');
        final names = exercises.map((e) => e.name).toList();

        // Universal compound & mobility exercises must NEVER be hidden for female audience
        expect(names, contains('Barbell Bench Press'));
        expect(names, contains('Barbell Incline Bench Press'));
        expect(names, contains('Barbell Glute Bridge'));
        expect(names, contains('Air Bike'));
        expect(exercises.length, greaterThan(1000));
      },
    );

    test(
      'male filter includes universal exercises (universal exercises are never hidden)',
      () async {
        final exercises = await repo.getExercises(genderFilter: 'male');
        final names = exercises.map((e) => e.name).toList();

        // Universal compound & glute/leg exercises must NEVER be hidden for male audience
        expect(names, contains('Barbell Bench Press'));
        expect(names, contains('Barbell Incline Bench Press'));
        expect(names, contains('Barbell Glute Bridge'));
        expect(names, contains('Air Bike'));
        expect(exercises.length, greaterThan(1000));
      },
    );

    test('universal filter returns all universal exercises', () async {
      final exercises = await repo.getExercises(genderFilter: 'universal');
      expect(exercises.length, equals(1324));
      expect(
        exercises.every((e) => e.audienceSuitability == 'universal'),
        isTrue,
      );
    });

    test(
      'Show all reset returns all exercises regardless of gender focus',
      () async {
        final container = ProviderContainer(
          overrides: [
            userProfileProvider.overrideWith(
              () => MockProfileNotifier(
                UserProfile.defaultGuest().copyWith(gender: 'male'),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Initially male
        expect(
          container.read(exercisesFilterProvider).genderFilter,
          equals('male'),
        );

        // Reset to all
        container.read(exercisesFilterProvider.notifier).resetToAll();
        expect(
          container.read(exercisesFilterProvider).genderFilter,
          equals('All'),
        );

        final allExercises = await repo.getExercises(genderFilter: 'All');
        final allNames = allExercises.map((e) => e.name).toList();

        // Contains both universal lifts
        expect(allNames, contains('Barbell Bench Press'));
        expect(allNames, contains('Barbell Glute Bridge'));
        expect(allNames, contains('Air Bike'));
        expect(allExercises.length, equals(1324));
      },
    );
  });
}
