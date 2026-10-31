import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_host/features/onboarding/presentation/onboarding_screen.dart';
import 'package:fit_host/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:fit_host/core/services/startup_gate_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  Widget createWizardStep12Widget({required ProviderContainer container}) {
    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) =>
              const Scaffold(body: Text('Home Screen')),
        ),
        GoRoute(
          path: '/profile-setup',
          builder: (context, state) =>
              const Scaffold(body: Text('Profile Setup Target')),
        ),
      ],
    );

    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('Wizard terminal step (step 17) renders Finish Setup CTA', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();
    container.read(onboardingProvider.notifier).jumpToStep(17);

    await tester.pumpWidget(createWizardStep12Widget(container: container));
    await tester.pumpAndSettle();

    // Verify terminal setup CTA
    expect(find.text('Finish Setup'), findsOneWidget);

    container.dispose();
  });

  testWidgets(
    'Tapping Finish Setup completes onboarding, sets startup flags and routes to /home',
    (WidgetTester tester) async {
      final container = ProviderContainer();
      container.read(onboardingProvider.notifier).jumpToStep(17);

      await tester.pumpWidget(createWizardStep12Widget(container: container));
      await tester.pumpAndSettle();

      final finishBtn = find.text('Finish Setup');
      expect(finishBtn, findsOneWidget);
      await tester.ensureVisible(finishBtn);
      await tester.tap(finishBtn);
      await tester.pumpAndSettle();

      final startupGate = container.read(startupGateServiceProvider);
      expect(await startupGate.isFirstLaunchCompleted(), isTrue);
      expect(await startupGate.isAuthDecisionMade(), isTrue);
      expect(find.text('Home Screen'), findsOneWidget);

      container.dispose();
    },
  );
}
