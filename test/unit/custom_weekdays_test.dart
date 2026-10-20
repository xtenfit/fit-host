import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fit_host/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:fit_host/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:fit_host/features/onboarding/domain/models/onboarding_models.dart';

class _FakeOnboardingRepo implements OnboardingRepository {
  OnboardingState? draft;
  bool completed = false;

  @override
  Future<void> saveDraft(OnboardingState state) async => draft = state;

  @override
  Future<OnboardingState?> loadDraft() async => draft;

  @override
  Future<void> clearDraft() async => draft = null;

  @override
  Future<void> completeOnboarding(OnboardingState state) async {
    completed = true;
    draft = state.copyWith(isCompleted: true);
  }

  @override
  Future<bool> isOnboardingCompleted() async => completed;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Custom Weekdays Schedule Tests', () {
    late ProviderContainer container;
    late _FakeOnboardingRepo fakeRepo;

    setUp(() {
      fakeRepo = _FakeOnboardingRepo();
      container = ProviderContainer(
        overrides: [
          onboardingRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Selecting Every Day chooses all 7 weekdays and sets workoutDaysPerWeek to 7', () {
      final notifier = container.read(onboardingProvider.notifier);

      notifier.setWeeklySchedule(days: 7, weekdays: [0, 1, 2, 3, 4, 5, 6], usesEveryDay: true);

      final state = container.read(onboardingProvider);
      expect(state.usesEveryDay, isTrue);
      expect(state.workoutDaysPerWeek, equals(7));
      expect(state.selectedWeekdays.length, equals(7));
      expect(state.selectedWeekdays, containsAll([0, 1, 2, 3, 4, 5, 6]));
    });

    test('Custom days selection correctly syncs count and selected day indexes', () {
      final notifier = container.read(onboardingProvider.notifier);

      // Mon (0), Wed (2), Fri (4)
      notifier.setWeeklySchedule(days: 3, weekdays: [0, 2, 4], usesEveryDay: false);

      final state = container.read(onboardingProvider);
      expect(state.usesEveryDay, isFalse);
      expect(state.workoutDaysPerWeek, equals(3));
      expect(state.selectedWeekdays, equals([0, 2, 4]));
    });

    test('Toggling a day off decreases workoutDaysPerWeek', () {
      final notifier = container.read(onboardingProvider.notifier);

      notifier.setWeeklySchedule(days: 4, weekdays: [0, 1, 2, 3], usesEveryDay: false);
      expect(container.read(onboardingProvider).workoutDaysPerWeek, equals(4));

      // Remove Tuesday (1)
      notifier.setWeeklySchedule(days: 3, weekdays: [0, 2, 3], usesEveryDay: false);
      final updated = container.read(onboardingProvider);
      expect(updated.workoutDaysPerWeek, equals(3));
      expect(updated.selectedWeekdays, equals([0, 2, 3]));
      expect(updated.selectedWeekdays.contains(1), isFalse);
    });
  });
}
