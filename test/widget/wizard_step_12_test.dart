import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_host/features/onboarding/presentation/onboarding_screen.dart';
import 'package:fit_host/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:fit_host/core/services/startup_gate_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
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
          path: '/profile-setup',
          builder: (context, state) => const Scaffold(body: Text('Profile Setup Target')),
        ),
        GoRoute(
          path: '/auth/sign-up',
          builder: (context, state) => const Scaffold(body: Text('Sign Up Screen')),
        ),
        GoRoute(
          path: '/auth/sign-in',
          builder: (context, state) => const Scaffold(body: Text('Sign In Screen')),
        ),
      ],
    );

    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('Wizard step 12 renders all 3 account decision CTAs', (WidgetTester tester) async {
    final container = ProviderContainer();
    container.read(onboardingProvider.notifier).jumpToStep(17);

    await tester.pumpWidget(createWizardStep12Widget(container: container));
    await tester.pumpAndSettle();

    // Verify all 3 decision options
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);

    container.dispose();
  });

  testWidgets('Continue as Guest displays confirmation dialog with Cancel and Continue', (WidgetTester tester) async {
    final container = ProviderContainer();
    container.read(onboardingProvider.notifier).jumpToStep(17);

    await tester.pumpWidget(createWizardStep12Widget(container: container));
    await tester.pumpAndSettle();

    // Tap Continue as Guest
    final guestBtn = find.text('Continue as Guest');
    expect(guestBtn, findsOneWidget);
    await tester.ensureVisible(guestBtn);
    await tester.tap(guestBtn);
    await tester.pumpAndSettle();

    // Verify dialog content
    expect(find.text('Continue as Guest?'), findsOneWidget);
    expect(
      find.text('Guest data stays on this device only. You can create an account later to sync.'),
      findsOneWidget,
    );
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    // Tap Continue
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    final startupGate = container.read(startupGateServiceProvider);
    expect(await startupGate.isFirstLaunchCompleted(), isTrue);
    expect(await startupGate.isAuthDecisionMade(), isTrue);
    expect(find.text('Profile Setup Target'), findsOneWidget);

    container.dispose();
  });

  testWidgets('Create Account CTA routes to sign-up', (WidgetTester tester) async {
    final container = ProviderContainer();
    container.read(onboardingProvider.notifier).jumpToStep(17);

    await tester.pumpWidget(createWizardStep12Widget(container: container));
    await tester.pumpAndSettle();

    final createBtn = find.text('Create Account');
    expect(createBtn, findsOneWidget);
    await tester.ensureVisible(createBtn);
    await tester.tap(createBtn);
    await tester.pumpAndSettle();

    expect(find.text('Sign Up Screen'), findsOneWidget);
    container.dispose();
  });

  testWidgets('Sign In CTA routes to sign-in', (WidgetTester tester) async {
    final container = ProviderContainer();
    container.read(onboardingProvider.notifier).jumpToStep(17);

    await tester.pumpWidget(createWizardStep12Widget(container: container));
    await tester.pumpAndSettle();

    final signInBtn = find.text('Sign In');
    expect(signInBtn, findsOneWidget);
    await tester.ensureVisible(signInBtn);
    await tester.tap(signInBtn);
    await tester.pumpAndSettle();

    expect(find.text('Sign In Screen'), findsOneWidget);
    container.dispose();
  });
}
