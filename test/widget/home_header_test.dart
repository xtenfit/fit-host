import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/home/presentation/widgets/home_header.dart';
import 'package:fit_host/features/profile/presentation/widgets/avatar_picker_sheet.dart';
import 'package:fit_host/features/profile/presentation/controllers/user_profile_controller.dart';
import 'package:fit_host/features/profile/domain/models/user_profile.dart';

class _FakeUserProfileNotifier extends UserProfileNotifier {
  final UserProfile _profile;
  _FakeUserProfileNotifier(this._profile);

  @override
  UserProfile build() => _profile;
}

void main() {
  testWidgets('HomeHeader renders AppAvatar connected to user profile avatarId',
      (WidgetTester tester) async {
    final testProfile = UserProfile(
      id: 'test_user',
      name: 'Ammu Athlete',
      age: 26,
      gender: 'female',
      heightCm: 165,
      weightKg: 58,
      fitnessGoal: 'lose_weight',
      dietType: 'balanced',
      targetMode: 'suggested',
      dailyCaloriesTarget: 1800,
      targetProteinGrams: 120,
      targetCarbsGrams: 180,
      targetFatsGrams: 50,
      targetWaterMl: 2500,
      weeklyWorkoutDays: 4,
      dailyWorkoutMinutes: 45,
      dailyCaloriesBurnTarget: 400,
      activityLevel: 'moderate',
      experienceLevel: 'intermediate',
      targetPaceKgPerWeek: 0.5,
      fastingProtocol: 'none',
      dailyStepsGoal: 10000,
      targetSleepHours: 8.0,
      avatarId: 'female_1',
      focusAreas: const ['Abs', 'Leg'],
      isProfileSetupCompleted: true,
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith(() => _FakeUserProfileNotifier(testProfile)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: HomeHeader(isDark: true),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // AppAvatar should be present and configured
    expect(find.byType(AppAvatar), findsOneWidget);
    final appAvatarFinder = find.byType(AppAvatar);
    final appAvatar = tester.widget<AppAvatar>(appAvatarFinder);
    expect(appAvatar.avatarId, equals('female_1'));
    expect(appAvatar.name, equals('Ammu Athlete'));
    expect(appAvatar.radius, equals(22));

    // Verify greeting and user display name rendered
    expect(find.text('Ammu Athlete'), findsOneWidget);
  });
}
