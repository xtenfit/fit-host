import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/core/data/profile_repository.dart';
import 'package:fit_host/features/profile/presentation/controllers/user_profile_controller.dart';
import 'package:fit_host/features/profile/presentation/screens/profile_setup_screen.dart';

class _FakeProfileRepository implements UserProfileRepository {
  UserProfile? storedProfile;

  @override
  Future<UserProfile> loadProfile() async {
    return storedProfile ??
        UserProfile.calculateSuggestedTargets(
          name: 'Sam Athlete',
          age: 26,
          gender: 'female',
          heightCm: 165.0,
          weightKg: 60.0,
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
  testWidgets('ProfileSetupScreen(isInitialSetup: true) displays only display name and avatar picker, with NO gender selection', (tester) async {
    final inMemoryDb = AppDatabase(NativeDatabase.memory());
    final fakeRepo = _FakeProfileRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(inMemoryDb),
          userProfileRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: ProfileSetupScreen(isInitialSetup: true),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial setup headers
    expect(find.text('Complete Your Profile'), findsWidgets);
    expect(find.text('What should we call you?'), findsOneWidget);
    expect(find.text('Athlete Name'), findsOneWidget);
    expect(find.text('Change Avatar'), findsOneWidget);
    expect(find.text('Complete Setup & Start'), findsOneWidget);

    // Verify ABSOLUTELY NO gender selector widget or biological sex form input
    expect(find.text('Biological Sex'), findsNothing);
    expect(find.text('Select Gender'), findsNothing);
    expect(find.text('Non-binary'), findsNothing);
    expect(find.byType(Radio), findsNothing);

    await inMemoryDb.close();
  });
}
