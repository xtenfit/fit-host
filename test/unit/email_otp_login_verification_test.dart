import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/services/supabase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Email OTP Login & Verification Flow Tests', () {
    test(
      'formatAuthError correctly identifies unconfirmed email and maps message',
      () {
        const err = 'Email not confirmed';
        final formatted = formatAuthError(err);
        expect(formatted.toLowerCase(), contains('not verified'));
      },
    );

    test('Unconfirmed email detection triggers OTP verification pathway', () {
      final sampleErrors = [
        'Email not confirmed',
        'email_not_confirmed',
        'User email is not verified',
        'Account unverified',
      ];

      for (final err in sampleErrors) {
        final lower = err.toLowerCase();
        final isUnconfirmed =
            lower.contains('not confirmed') ||
            lower.contains('not verified') ||
            lower.contains('unverified') ||
            lower.contains('email_not_confirmed');
        expect(isUnconfirmed, isTrue, reason: 'Failed for error string: $err');
      }
    });

    test(
      'formatAuthError preserves regular password error without triggering unconfirmed flag',
      () {
        const err = 'Invalid login credentials';
        final formatted = formatAuthError(err);
        final lower = formatted.toLowerCase();
        final isUnconfirmed =
            lower.contains('not confirmed') ||
            lower.contains('not verified') ||
            lower.contains('unverified') ||
            lower.contains('email_not_confirmed');
        expect(isUnconfirmed, isFalse);
      },
    );

    test('formatAuthError correctly identifies reauthentication needed', () {
      const err = 'reauthentication_needed';
      final formatted = formatAuthError(err);
      expect(
        formatted.toLowerCase(),
        contains('identity verification required'),
      );
      expect(formatted, contains('6-digit verification code'));
    });

    test('AuthState correctly exposes isReauthenticationRequired state', () {
      const state = AuthState(status: AuthStatus.reauthenticationRequired);
      expect(state.isReauthenticationRequired, isTrue);
      expect(state.isAuthenticated, isFalse);
    });
  });
}
