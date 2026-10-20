import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fit_host/core/auth/auth_state_machine.dart';

void main() {
  group('Part 2: AuthStateMachine Lifecycle & Offline Grace Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state defaults to guest status', () async {
      final state = await container.read(authStateMachineProvider.future);
      expect(state.status, equals(AuthStatus.guest));
      expect(state.isGuest, isTrue);
      expect(state.isAuthenticated, isFalse);
    });

    test('Token refresh failure with no network enters offlineGrace, not guest', () async {
      final notifier = container.read(authStateMachineProvider.notifier);

      // Authenticate user
      final mockUser = User(
        id: 'auth-athlete-1',
        appMetadata: {},
        userMetadata: {'name': 'Test Athlete'},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );

      await notifier.setAuthenticated(mockUser);
      var state = container.read(authStateMachineProvider).value!;
      expect(state.status, equals(AuthStatus.authenticated));
      expect(state.isAuthenticated, isTrue);

      // Trigger token refresh that fails due to network outage
      await notifier.refreshToken(refreshAction: () async {
        // Simulating network exception / timeout
        throw Exception('SocketException: Connection refused (no network)');
      });

      state = container.read(authStateMachineProvider).value!;

      // MUST enter offlineGrace, and MUST NOT downgrade to guest!
      expect(state.status, equals(AuthStatus.offlineGrace));
      expect(state.isOfflineGrace, isTrue);
      expect(state.isGuest, isFalse);
      expect(state.isAuthenticated, isTrue); // In offlineGrace, user remains authenticated!
    });

    test('Reconnect restores status back from offlineGrace to authenticated', () async {
      final notifier = container.read(authStateMachineProvider.notifier);

      final mockUser = User(
        id: 'auth-athlete-2',
        appMetadata: {},
        userMetadata: {'name': 'Athlete Two'},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );

      await notifier.setAuthenticated(mockUser);

      // Force failure to offlineGrace
      await notifier.refreshToken(refreshAction: () async => false);
      expect(container.read(authStateMachineProvider).value!.status,
          equals(AuthStatus.offlineGrace));

      // Network recovers: restore
      notifier.restoreFromOfflineGrace();

      final restored = container.read(authStateMachineProvider).value!;
      expect(restored.status, equals(AuthStatus.authenticated));
      expect(restored.isOfflineGrace, isFalse);
      expect(restored.isAuthenticated, isTrue);
    });

    test('Explicit sign out transitions through signedOut to guest', () async {
      final notifier = container.read(authStateMachineProvider.notifier);

      final mockUser = User(
        id: 'auth-athlete-3',
        appMetadata: {},
        userMetadata: {'name': 'Athlete Three'},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );

      await notifier.setAuthenticated(mockUser);
      expect(container.read(authStateMachineProvider).value!.status,
          equals(AuthStatus.authenticated));

      // Explicit sign out
      await notifier.signOut();

      final state = container.read(authStateMachineProvider).value!;
      expect(state.status, equals(AuthStatus.guest));
      expect(state.isGuest, isTrue);
      expect(state.isAuthenticated, isFalse);
    });

    test('Token refresh failure with 401 AuthException enters signedOut', () async {
      final notifier = container.read(authStateMachineProvider.notifier);

      final mockUser = User(
        id: 'auth-athlete-revoked',
        appMetadata: {},
        userMetadata: {'name': 'Revoked User'},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );

      await notifier.setAuthenticated(mockUser);
      expect(container.read(authStateMachineProvider).value!.status,
          equals(AuthStatus.authenticated));

      await notifier.refreshToken(refreshAction: () async {
        throw const AuthException(
          'Invalid Refresh Token: Refresh Token Not Found',
          statusCode: '401',
        );
      });

      final state = container.read(authStateMachineProvider).value!;
      expect(state.status, equals(AuthStatus.signedOut));
      expect(state.errorMessage, contains('Invalid Refresh Token'));
    });
  });
}
