import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fit_host/core/services/startup_gate_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StartupGateService 4-way routing tests', () {
    test('Case 1: routes to /setup-wizard when first_launch_completed is false/unset',
        () async {
      FlutterSecureStorage.setMockInitialValues({});
      final service = StartupGateService();

      expect(await service.isFirstLaunchCompleted(), isFalse);
      expect(await service.isAuthDecisionMade(), isFalse);

      final route = await service.determineInitialRoute();
      expect(route, equals('/setup-wizard'));
    });

    test(
        'Case 2: routes to /auth-decision when first_launch_completed is true but auth_decision_made is false',
        () async {
      FlutterSecureStorage.setMockInitialValues({
        StartupGateService.keyFirstLaunch: 'true',
      });
      final service = StartupGateService();

      expect(await service.isFirstLaunchCompleted(), isTrue);
      expect(await service.isAuthDecisionMade(), isFalse);

      final route = await service.determineInitialRoute();
      expect(route, equals('/auth-decision'));
    });

    test(
        'Case 3: routes to /setup-wizard when auth == authenticated && profile.isProfileSetupCompleted == false',
        () async {
      FlutterSecureStorage.setMockInitialValues({
        StartupGateService.keyFirstLaunch: 'true',
        StartupGateService.keyAuthDecision: 'true',
      });
      final service = StartupGateService();

      final route = await service.determineInitialRoute(
        isAuthenticated: true,
        isProfileSetupCompleted: false,
      );
      expect(route, equals('/setup-wizard'));
    });

    test(
        'Case 4: routes to /home when both flags true and profile setup completed',
        () async {
      FlutterSecureStorage.setMockInitialValues({
        StartupGateService.keyFirstLaunch: 'true',
        StartupGateService.keyAuthDecision: 'true',
      });
      final service = StartupGateService();

      expect(await service.isFirstLaunchCompleted(), isTrue);
      expect(await service.isAuthDecisionMade(), isTrue);

      final route = await service.determineInitialRoute(
        isAuthenticated: true,
        isProfileSetupCompleted: true,
      );
      expect(route, equals('/home'));
    });

    test('resetOnboarding clears both flags and routes back to /setup-wizard',
        () async {
      FlutterSecureStorage.setMockInitialValues({
        StartupGateService.keyFirstLaunch: 'true',
        StartupGateService.keyAuthDecision: 'true',
      });
      final service = StartupGateService();

      await service.resetOnboarding();

      expect(await service.isFirstLaunchCompleted(), isFalse);
      expect(await service.isAuthDecisionMade(), isFalse);
      expect(await service.determineInitialRoute(), equals('/setup-wizard'));
    });
  });
}
