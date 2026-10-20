import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthStatus {
  guest,
  authenticating,
  authenticated,
  tokenRefreshing,
  offlineGrace,
  signedOut,
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final String? errorMessage;
  final bool otpSent;

  const AuthState({
    this.status = AuthStatus.guest,
    this.user,
    this.email,
    this.displayName,
    this.avatarUrl,
    this.errorMessage,
    this.otpSent = false,
  });

  bool get isGuest => status == AuthStatus.guest;
  bool get isAuthenticated =>
      status == AuthStatus.authenticated || status == AuthStatus.offlineGrace;
  bool get isOfflineGrace => status == AuthStatus.offlineGrace;
  bool get isAuthenticating => status == AuthStatus.authenticating;
  User? get supabaseUser => user;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? email,
    String? displayName,
    String? avatarUrl,
    String? errorMessage,
    bool? otpSent,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      otpSent: otpSent ?? this.otpSent,
    );
  }
}

extension AuthStateAsyncValueX on AsyncValue<AuthState> {
  AuthStatus get status => value?.status ?? AuthStatus.guest;
  User? get user => value?.user;
  bool get isGuest => status == AuthStatus.guest;
  bool get isAuthenticated =>
      status == AuthStatus.authenticated || status == AuthStatus.offlineGrace;
  bool get isOfflineGrace => status == AuthStatus.offlineGrace;
}

class AuthStateMachineNotifier extends AsyncNotifier<AuthState> {
  static const String guestModeKey = 'fit_host_guest_mode';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<AuthState> build() async {
    // Check if user explicitly persisted guest mode
    String? guestFlag;
    try {
      guestFlag = await _storage.read(key: guestModeKey);
    } catch (_) {}

    // Check existing Supabase session
    User? currentUser;
    try {
      if (Supabase.instance.client.auth.currentSession != null) {
        currentUser = Supabase.instance.client.auth.currentUser;
      }
    } catch (_) {}

    if (guestFlag == 'true' || currentUser == null) {
      return const AuthState(status: AuthStatus.guest);
    }

    return AuthState(
      status: AuthStatus.authenticated,
      user: currentUser,
      email: currentUser.email,
      displayName: currentUser.userMetadata?['name'] as String? ??
          currentUser.email?.split('@').first,
    );
  }

  /// Sets state to authenticating
  void startAuthenticating() {
    final current = state.value ?? const AuthState();
    state = AsyncData(current.copyWith(status: AuthStatus.authenticating));
  }

  /// Sets state to authenticated
  Future<void> setAuthenticated(User user) async {
    try {
      await _storage.write(key: guestModeKey, value: 'false');
    } catch (_) {}

    state = AsyncData(
      AuthState(
        status: AuthStatus.authenticated,
        user: user,
        email: user.email,
        displayName: user.userMetadata?['name'] as String? ??
            user.email?.split('@').first,
      ),
    );
  }

  /// Initiates token refresh. If refresh fails due to network outage,
  /// enters `offlineGrace` instead of downgrading to `guest`.
  Future<void> refreshToken({required Future<bool> Function() refreshAction}) async {
    final current = state.value ?? const AuthState();
    if (current.status == AuthStatus.guest) return;

    state = AsyncData(current.copyWith(status: AuthStatus.tokenRefreshing));

    try {
      final success = await refreshAction();
      if (success) {
        state = AsyncData(current.copyWith(status: AuthStatus.authenticated));
      } else {
        // Network or offline failure: enter offlineGrace, never downgrade to guest!
        state = AsyncData(current.copyWith(status: AuthStatus.offlineGrace));
      }
    } on SocketException catch (_) {
      // Network/socket error -> offlineGrace, KEEP the cached user!
      state = AsyncData(current.copyWith(status: AuthStatus.offlineGrace));
    } on AuthException catch (e) {
      final code = e.statusCode?.toString() ?? '';
      final msg = e.message.toLowerCase();
      if (code == '401' ||
          code == '403' ||
          msg.contains('invalid') ||
          msg.contains('revoked') ||
          msg.contains('not found') ||
          msg.contains('expired')) {
        // Token revoked/invalid -> signedOut
        state = AsyncData(current.copyWith(
          status: AuthStatus.signedOut,
          errorMessage: e.message,
        ));
      } else {
        state = AsyncData(current.copyWith(status: AuthStatus.offlineGrace));
      }
    } catch (e) {
      final str = e.toString().toLowerCase();
      if (str.contains('socketexception') ||
          str.contains('network') ||
          str.contains('connection') ||
          str.contains('failed host lookup')) {
        state = AsyncData(current.copyWith(status: AuthStatus.offlineGrace));
      } else {
        state = AsyncData(current.copyWith(
          status: AuthStatus.signedOut,
          errorMessage: e.toString(),
        ));
      }
    }
  }

  /// Called when connectivity recovers and token is valid
  void restoreFromOfflineGrace() {
    final current = state.value;
    if (current != null && current.status == AuthStatus.offlineGrace) {
      state = AsyncData(current.copyWith(status: AuthStatus.authenticated));
    }
  }

  /// Explicit user sign out
  Future<void> signOut() async {
    state = AsyncData((state.value ?? const AuthState())
        .copyWith(status: AuthStatus.signedOut));

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}

    try {
      await _storage.write(key: guestModeKey, value: 'true');
    } catch (_) {}

    state = const AsyncData(AuthState(status: AuthStatus.guest));
  }

  /// Explicitly choose guest mode
  Future<void> continueAsGuest() async {
    try {
      await _storage.write(key: guestModeKey, value: 'true');
    } catch (_) {}
    state = const AsyncData(AuthState(status: AuthStatus.guest));
  }
}

final authStateMachineProvider =
    AsyncNotifierProvider<AuthStateMachineNotifier, AuthState>(
  AuthStateMachineNotifier.new,
);
