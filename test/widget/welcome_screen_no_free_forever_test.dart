import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/onboarding/presentation/screens/steps/welcome_step.dart';

void main() {
  testWidgets('Welcome screen renders premium branding and contains NO "Free Core Forever" text', (tester) async {
    bool started = false;
    bool guest = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WelcomeStep(
            onStart: () => started = true,
            onContinueAsGuest: () => guest = true,
          ),
        ),
      ),
    );

    // Assert "Free Core Forever" is strictly absent
    expect(find.textContaining('Free Core Forever'), findsNothing);
    expect(find.textContaining('free core forever'), findsNothing);

    // Assert branding & feature cards
    expect(find.text('FIT HOST'), findsOneWidget);
    expect(find.text('Sync Across Devices'), findsOneWidget);
    expect(find.text('Progressive Overload Tracking'), findsOneWidget);
    expect(find.text('Private by Default'), findsOneWidget);

    // Assert CTA buttons
    expect(find.text('Start Personalization →'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);

    // Tap CTA
    await tester.ensureVisible(find.text('Start Personalization →'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Personalization →'));
    expect(started, isTrue);

    await tester.ensureVisible(find.text('Continue as Guest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue as Guest'));
    expect(guest, isTrue);
  });
}
