import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

void main() {
  group('AuthStatus and AuthState Extended Lifecycle Tests', () {
    test('AuthStatus covers all required production authentication states', () {
      expect(AuthStatus.values, contains(AuthStatus.initialLoading));
      expect(AuthStatus.values, contains(AuthStatus.guest));
      expect(AuthStatus.values, contains(AuthStatus.signedOut));
      expect(AuthStatus.values, contains(AuthStatus.emailVerificationRequired));
      expect(AuthStatus.values, contains(AuthStatus.authenticating));
      expect(AuthStatus.values, contains(AuthStatus.authenticated));
      expect(AuthStatus.values, contains(AuthStatus.tokenRefreshing));
      expect(AuthStatus.values, contains(AuthStatus.offlineGrace));
      expect(AuthStatus.values, contains(AuthStatus.passwordRecovery));
      expect(AuthStatus.values, contains(AuthStatus.reauthenticationRequired));
    });

    test('AuthState reauthenticationRequired state flags', () {
      const state = AuthState(status: AuthStatus.reauthenticationRequired);
      expect(state.isReauthenticationRequired, isTrue);
      expect(state.isAuthenticated, isFalse);
      expect(state.isGuest, isFalse);
    });

    test('AuthState initialLoading state correctly reports flags', () {
      const state = AuthState(status: AuthStatus.initialLoading);
      expect(state.isInitialLoading, isTrue);
      expect(state.isAuthenticated, isFalse);
      expect(state.isGuest, isFalse);
      expect(state.isEmailVerificationRequired, isFalse);
      expect(state.isPasswordRecovery, isFalse);
    });

    test('AuthState emailVerificationRequired reports flags and preserves email', () {
      const state = AuthState(
        status: AuthStatus.emailVerificationRequired,
        email: 'athlete@example.com',
      );
      expect(state.isEmailVerificationRequired, isTrue);
      expect(state.email, equals('athlete@example.com'));
      expect(state.isAuthenticated, isFalse);
    });

    test('AuthState passwordRecovery state flags', () {
      const state = AuthState(status: AuthStatus.passwordRecovery);
      expect(state.isPasswordRecovery, isTrue);
      expect(state.isAuthenticated, isFalse);
    });

    test('AuthState offlineGrace retains authenticated status without downgrade', () {
      final mockUser = User(
        id: 'test-user-offline-1',
        appMetadata: {},
        userMetadata: {'name': 'Offline Athlete'},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );

      final state = AuthState(
        status: AuthStatus.offlineGrace,
        user: mockUser,
      );
      expect(state.isOfflineGrace, isTrue);
      expect(state.isAuthenticated, isTrue);
      expect(state.isGuest, isFalse);
      expect(state.user?.id, equals('test-user-offline-1'));
    });

    test('AuthState copyWith preserves existing values unless explicitly overwritten', () {
      final mockUser = User(
        id: 'test-user-2',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );

      final state = AuthState(
        status: AuthStatus.authenticated,
        user: mockUser,
        email: 'athlete@fithost.app',
      );

      final updated = state.copyWith(status: AuthStatus.passwordRecovery);
      expect(updated.status, equals(AuthStatus.passwordRecovery));
      expect(updated.user?.id, equals('test-user-2'));
      expect(updated.email, equals('athlete@fithost.app'));
    });
  });
}
