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

  group('Session Duration & Custom Duration Tests', () {
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

    test('Sets standard duration from slider properly', () {
      final notifier = container.read(onboardingProvider.notifier);

      notifier.setSessionDuration(45);
      expect(container.read(onboardingProvider).sessionDurationMinutes, equals(45));

      notifier.setSessionDuration(60);
      expect(container.read(onboardingProvider).sessionDurationMinutes, equals(60));
    });

    test('Sets custom minute value accurately within allowed range (5 to 180 min)', () {
      final notifier = container.read(onboardingProvider.notifier);

      notifier.setSessionDuration(75);
      expect(container.read(onboardingProvider).sessionDurationMinutes, equals(75));

      notifier.setSessionDuration(105);
      expect(container.read(onboardingProvider).sessionDurationMinutes, equals(105));

      notifier.setSessionDuration(5);
      expect(container.read(onboardingProvider).sessionDurationMinutes, equals(5));

      notifier.setSessionDuration(180);
      expect(container.read(onboardingProvider).sessionDurationMinutes, equals(180));
    });
  });
}
