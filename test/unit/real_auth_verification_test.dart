import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fit_host/core/services/supabase_service.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Part D: Real Supabase Auth & Anti-Mock Verification Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'Initial state defaults to guest status with no mock athlete user',
      () {
        final authState = container.read(authProvider);
        expect(authState.status, equals(AuthStatus.guest));
        expect(authState.isAuthenticated, isFalse);
        expect(authState.isGuest, isTrue);
        expect(authState.user, isNull);
        expect(authState.email, isNull);
      },
    );

    test(
      'signInWithGoogle does NOT inject athlete.google@fit-host.app when unconfigured',
      () async {
        final authNotifier = container.read(authProvider.notifier);

        // Attempt Google sign-in without a configured Supabase backend
        final result = await authNotifier.signInWithGoogle();

        // Must return false
        expect(result, isFalse);

        final state = container.read(authProvider);
        // User must remain guest (not silently authenticated)
        expect(state.status, equals(AuthStatus.guest));
        expect(state.isAuthenticated, isFalse);
        expect(state.user, isNull);
        expect(state.email, isNot(equals('athlete.google@fit-host.app')));
        expect(state.displayName, isNot(equals('Google Athlete')));

        // Must have an informative, honest error message
        expect(state.errorMessage, isNotNull);
        expect(state.errorMessage, contains('not configured'));
      },
    );

    test(
      'signInWithPassword rejects simulated authentication without real backend',
      () async {
        final authNotifier = container.read(authProvider.notifier);

        expect(
          () => authNotifier.signInWithPassword(
            email: 'athlete@example.com',
            password: 'password123',
          ),
          throwsA(isA<Exception>()),
        );

        final state = container.read(authProvider);
        expect(state.isAuthenticated, isFalse);
        expect(state.status, equals(AuthStatus.guest));
        expect(state.user, isNull);
      },
    );

    test(
      'signUpWithPassword rejects simulated registration without real backend',
      () async {
        final authNotifier = container.read(authProvider.notifier);

        expect(
          () => authNotifier.signUpWithPassword(
            email: 'newathlete@example.com',
            password: 'securePassword123!',
            displayName: 'Real Athlete',
          ),
          throwsA(isA<Exception>()),
        );

        final state = container.read(authProvider);
        expect(state.isAuthenticated, isFalse);
        expect(state.status, equals(AuthStatus.guest));
        expect(state.user, isNull);
      },
    );

    test(
      'verifyOtp does not grant authenticated access on unconfigured backend',
      () async {
        final authNotifier = container.read(authProvider.notifier);

        final verified = await authNotifier.verifyOtp(
          '123456',
          email: 'test@example.com',
        );
        expect(verified, isFalse);

        final state = container.read(authProvider);
        expect(state.isAuthenticated, isFalse);
        expect(state.status, equals(AuthStatus.guest));
        expect(state.user, isNull);
        expect(state.errorMessage, isNotNull);
      },
    );

    test('deleteAccount throws when no authenticated session exists', () async {
      final authNotifier = container.read(authProvider.notifier);

      expect(
        () => authNotifier.deleteAccount(passwordConfirm: 'anyPassword'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
