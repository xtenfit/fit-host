import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/onboarding/presentation/onboarding_screen.dart';

void main() {
  testWidgets('OnboardingScreen renders official branding, value pillars, and continue offline action',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingScreen(),
      ),
    );

    // Verify presence of Value Pillars
    expect(find.text('Free Core Forever'), findsOneWidget);
    expect(find.text('100% Offline SQLite'), findsOneWidget);
    expect(find.text('Progressive Overload'), findsOneWidget);

    // Verify Primary CTA
    expect(find.text('Continue Offline'), findsOneWidget);

    // Verify Secondary CTA
    expect(find.text('Cloud Account (Optional)'), findsOneWidget);

    // Tap Optional Cloud Account to verify explanation dialog
    await tester.ensureVisible(find.text('Cloud Account (Optional)'));
    await tester.tap(find.text('Cloud Account (Optional)'));
    await tester.pumpAndSettle();
    expect(find.text('Optional Cloud Sync'), findsOneWidget);
    expect(find.text('Start Offline Now'), findsOneWidget);
  });
}
