import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fit_host/core/services/startup_gate_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Auth Screen Repetition Fix Verification Suite', () {
    test(
      'Authenticated user with profile setup completed never sees /auth-decision',
      () async {
        final service = StartupGateService();
        const userId = 'auth-user-123';

        final route = await service.determineInitialRoute(
          isAuthenticated: true,
          isProfileSetupCompleted: true,
          userId: userId,
        );

        expect(route, equals('/home'));
        expect(await service.isAccountOnboardingCompleted(userId), isTrue);
        expect(await service.isAuthDecisionMade(), isTrue);
        expect(await service.isFirstLaunchCompleted(), isTrue);
      },
    );

    test(
      'Authenticated user with account onboarding flag completed routes directly to /home',
      () async {
        final service = StartupGateService();
        const userId = 'auth-user-456';

        await service.setAccountOnboardingCompleted(userId, true);

        final route = await service.determineInitialRoute(
          isAuthenticated: true,
          isProfileSetupCompleted: false, // In memory profile not loaded yet
          userId: userId,
        );

        expect(route, equals('/home'));
      },
    );

    test(
      'Authenticated new account user without profile setup routes to /setup-wizard, never /auth-decision',
      () async {
        final service = StartupGateService();
        const userId = 'new-user-789';

        final route = await service.determineInitialRoute(
          isAuthenticated: true,
          isProfileSetupCompleted: false,
          userId: userId,
        );

        expect(route, equals('/setup-wizard'));
        expect(route, isNot(equals('/auth-decision')));
      },
    );

    test(
      'Post-auth setup flags persist across restart so user is never asked for auth decision again',
      () async {
        final service = StartupGateService();
        const userId = 'verified-user-101';

        // Simulate what AuthNavigationHelper / EmailVerificationScreen / SignInScreen does
        await service.setFirstLaunchCompleted(true);
        await service.setAuthDecisionMade(true);
        await service.setAccountOnboardingCompleted(userId, true);

        expect(await service.isFirstLaunchCompleted(), isTrue);
        expect(await service.isAuthDecisionMade(), isTrue);
        expect(await service.isAccountOnboardingCompleted(userId), isTrue);

        // On next app launch when authenticated:
        final nextRoute = await service.determineInitialRoute(
          isAuthenticated: true,
          isProfileSetupCompleted: false,
          userId: userId,
        );
        expect(nextRoute, equals('/home'));
      },
    );
  });
}
