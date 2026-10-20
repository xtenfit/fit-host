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

  group('Gender Branching Navigation Tests', () {
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

    test('Male user branches into step 8b (isGenderBranch: true) then to step 9', () {
      final notifier = container.read(onboardingProvider.notifier);
      
      notifier.setGender('male');
      notifier.jumpToStep(8);

      expect(container.read(onboardingProvider).currentStep, equals(8));
      expect(container.read(onboardingProvider).isGenderBranch, isFalse);

      // Advance from Step 8 -> Step 8b
      notifier.nextStep();
      expect(container.read(onboardingProvider).currentStep, equals(8));
      expect(container.read(onboardingProvider).isGenderBranch, isTrue);

      // Advance from Step 8b -> Step 9
      notifier.nextStep();
      expect(container.read(onboardingProvider).currentStep, equals(9));
      expect(container.read(onboardingProvider).isGenderBranch, isFalse);

      // Back from Step 9 -> Step 8b
      notifier.previousStep();
      expect(container.read(onboardingProvider).currentStep, equals(8));
      expect(container.read(onboardingProvider).isGenderBranch, isTrue);

      // Back from Step 8b -> Step 8
      notifier.previousStep();
      expect(container.read(onboardingProvider).currentStep, equals(8));
      expect(container.read(onboardingProvider).isGenderBranch, isFalse);
    });

    test('Female user branches into step 8b (isGenderBranch: true) then to step 9', () {
      final notifier = container.read(onboardingProvider.notifier);
      
      notifier.setGender('female');
      notifier.jumpToStep(8);

      // Advance to 8b
      notifier.nextStep();
      expect(container.read(onboardingProvider).currentStep, equals(8));
      expect(container.read(onboardingProvider).isGenderBranch, isTrue);

      // Advance to 9
      notifier.nextStep();
      expect(container.read(onboardingProvider).currentStep, equals(9));
      expect(container.read(onboardingProvider).isGenderBranch, isFalse);
    });

    test('Unspecified or other gender skips branch directly to step 9', () {
      final notifier = container.read(onboardingProvider.notifier);
      
      notifier.setGender('other');
      notifier.jumpToStep(8);

      // Advance directly to 9
      notifier.nextStep();
      expect(container.read(onboardingProvider).currentStep, equals(9));
      expect(container.read(onboardingProvider).isGenderBranch, isFalse);

      // Back from 9 directly to 8 (no branch)
      notifier.previousStep();
      expect(container.read(onboardingProvider).currentStep, equals(8));
      expect(container.read(onboardingProvider).isGenderBranch, isFalse);
    });
  });
}
