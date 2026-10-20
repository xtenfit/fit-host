import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/core/data/profile_repository.dart';
import 'package:fit_host/features/profile/domain/models/profile_constants.dart';
import 'package:fit_host/features/profile/presentation/controllers/user_profile_controller.dart';
import 'package:fit_host/features/profile/presentation/screens/edit_profile_screen.dart';

class _FakeProfileRepository implements UserProfileRepository {
  UserProfile? storedProfile;

  @override
  Future<UserProfile> loadProfile() async {
    return storedProfile ??
        UserProfile.calculateSuggestedTargets(
          name: 'Taylor Athlete',
          age: 27,
          gender: 'female',
          heightCm: 168.0,
          weightKg: 62.0,
          targetWeightKg: 58.0,
          fitnessGoal: 'Lose Weight',
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
  testWidgets('EditProfileScreen renders all chip labels from shared kFocusAreas and kFitnessGoals', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final inMemoryDb = AppDatabase(NativeDatabase.memory());
    final fakeRepo = _FakeProfileRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(inMemoryDb),
          userProfileRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: EditProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify all fitness goals from kFitnessGoals are rendered in ChoiceChips
    for (final goal in kFitnessGoals) {
      expect(find.widgetWithText(ChoiceChip, goal), findsOneWidget);
    }

    // Verify all focus area chips from kFocusAreas are rendered in FilterChips
    for (final area in kFocusAreas) {
      expect(find.widgetWithText(FilterChip, area), findsOneWidget);
    }

    await inMemoryDb.close();
  });
}
