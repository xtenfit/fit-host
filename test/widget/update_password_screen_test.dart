import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/auth/presentation/screens/update_password_screen.dart';

void main() {
  group('UpdatePasswordScreen Widget Tests', () {
    testWidgets('Shows expired session view when no active recovery session exists', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: UpdatePasswordScreen(forceActiveSessionForTesting: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recovery Link Expired'), findsOneWidget);
      expect(find.text('Request New Reset Link'), findsOneWidget);
      expect(find.byIcon(Icons.link_off_rounded), findsOneWidget);
    });

    testWidgets('Renders update password form with security inputs and button when active session exists', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: UpdatePasswordScreen(forceActiveSessionForTesting: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check title and description
      expect(find.text('Set New Password'), findsOneWidget);
      expect(
        find.text('Choose a strong password with at least 8 characters, including numbers and letters.'),
        findsOneWidget,
      );

      // Check text fields
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);

      // Check update password button
      expect(find.text('Update Password'), findsOneWidget);
    });

    testWidgets('Shows error if password is less than 8 characters', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: UpdatePasswordScreen(forceActiveSessionForTesting: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), '12345');
      await tester.enterText(textFields.at(1), '12345');

      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    });

    testWidgets('Shows error if passwords do not match', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: UpdatePasswordScreen(forceActiveSessionForTesting: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Secret123');
      await tester.enterText(textFields.at(1), 'Different123');

      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('Password visibility toggle toggles obscureText property', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: UpdatePasswordScreen(forceActiveSessionForTesting: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find visibility icon buttons (initially visibility_outlined)
      final visibilityIcons = find.byIcon(Icons.visibility_outlined);
      expect(visibilityIcons, findsNWidgets(2));

      // Tap first visibility toggle
      await tester.tap(visibilityIcons.first);
      await tester.pumpAndSettle();

      // Now one should be visibility_off_outlined
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });
  });
}
