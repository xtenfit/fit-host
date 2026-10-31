import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/guest_account_claim_service.dart';
import '../database/database.dart';
import '../router/app_router.dart';
import '../../features/profile/presentation/controllers/user_profile_controller.dart';

String getSupabaseUrl() {
  final envUrl = dotenv.isInitialized ? dotenv.env['SUPABASE_URL'] : null;
  return envUrl ??
      const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: 'https://api.amitrana.tech',
      );
}

String getSupabaseBackendHost() {
  final envHost = dotenv.isInitialized
      ? dotenv.env['SUPABASE_BACKEND_HOST']
      : null;
  if (envHost != null && envHost.isNotEmpty) return envHost;
  return const String.fromEnvironment(
    'SUPABASE_BACKEND_HOST',
    defaultValue: 'eedubttdylyqrhyeikwb.supabase.co',
  );
}

String getSupabasePublishableKey() {
  final envKey = dotenv.isInitialized
      ? dotenv.env['SUPABASE_PUBLISHABLE_KEY']
      : null;
  return envKey ??
      const String.fromEnvironment(
        'SUPABASE_PUBLISHABLE_KEY',
        defaultValue: 'sb_publishable_RIk7q1B0Cj6BWmsNGAMUsA_t09zbMv6',
      );
}

const String kSupabaseSecretKey = String.fromEnvironment(
  'SUPABASE_SECRET_KEY',
  defaultValue: '',
);

const String kGoogleWebClientId = String.fromEnvironment(
  'GOOGLE_WEB_CLIENT_ID',
  defaultValue:
      '744580314397-93gjs0lr8654pag5vc70uerb84ds5i2p.apps.googleusercontent.com',
);

/// Extracts a clean, human-readable error message from AuthException or general errors.
String formatAuthError(dynamic e) {
  if (e == null) return '';
  String raw = '';
  if (e is AuthException) {
    raw = e.message;
  } else {
    final str = e.toString();
    final match = RegExp(
      r'AuthException\(message:\s*(.*?)(?:,\s*statusCode.*)?\)',
    ).firstMatch(str);
    raw = match != null && match.group(1) != null
        ? match.group(1)!.trim()
        : str
              .replaceFirst('Exception:', '')
              .replaceFirst('AuthException:', '')
              .trim();
  }

  // Attempt to parse JSON error responses like {"code":"unexpected_failure","message":"Error sending recovery email"}
  if (raw.trim().startsWith('{') && raw.trim().endsWith('}')) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        if (decoded['message'] != null) {
          raw = decoded['message'].toString();
        } else if (decoded['error_description'] != null) {
          raw = decoded['error_description'].toString();
        }
      }
    } catch (_) {}
  }

  final lower = raw.toLowerCase();
  if (lower.contains('rate limit') || lower.contains('too many requests')) {
    return 'Email rate limit exceeded. Please wait a few minutes before requesting another code.';
  }
  if (lower.contains('error sending') ||
      lower.contains('recovery email') ||
      lower.contains('recovery mail') ||
      lower.contains('unexpected_failure') ||
      lower.contains('smtp') ||
      lower.contains('confirmation mail') ||
      lower.contains('confirmation email') ||
      lower.contains('error sending mail') ||
      lower.contains('error sending email')) {
    return 'Unable to send recovery email. Supabase Auth SMTP service encountered an issue or rate limit. If you have an OTP code, you can reset using OTP.';
  }
  if (lower.contains('user already registered') ||
      lower.contains('already been registered') ||
      lower.contains('email exists')) {
    return 'An account with this email address already exists. Please sign in instead.';
  }
  if (lower.contains('email not confirmed') ||
      lower.contains('not confirmed') ||
      lower.contains('email_not_confirmed')) {
    return 'Your email address is not verified yet. Please enter the verification code from your email.';
  }
  if (lower.contains('token has expired') ||
      lower.contains('token is expired') ||
      lower.contains('otp expired')) {
    return 'The verification code has expired. Please request a new code.';
  }
  if (lower.contains('token is invalid') ||
      lower.contains('invalid token') ||
      lower.contains('invalid otp')) {
    return 'The verification code entered is invalid. Please check your latest email and try again.';
  }
  if (lower.contains('invalid login credentials') ||
      lower.contains('invalid credentials')) {
    return 'Invalid email or password. Please verify your credentials or reset your password.';
  }
  if (lower.contains('reauthentication_needed') ||
      lower.contains('reauthentication required') ||
      lower.contains('reauthenticate')) {
    return 'Identity verification required. A 6-digit verification code has been sent to your email.';
  }
  return raw;
}

enum AuthStatus {
  initialLoading,
  guest,
  signedOut,
  emailVerificationRequired,
  authenticating,
  authenticated,
  tokenRefreshing,
  offlineGrace,
  passwordRecovery,
  reauthenticationRequired,
}

class AuthState {
  final AuthStatus status;
  final User? supabaseUser;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final String? errorMessage;
  final bool otpSent;

  const AuthState({
    this.status = AuthStatus.guest,
    User? supabaseUser,
    User? user,
    this.email,
    this.displayName,
    this.avatarUrl,
    this.errorMessage,
    this.otpSent = false,
  }) : supabaseUser = user ?? supabaseUser;

  bool get isGuest => status == AuthStatus.guest;
  bool get isAuthenticated =>
      status == AuthStatus.authenticated || status == AuthStatus.offlineGrace;
  bool get isOfflineGrace => status == AuthStatus.offlineGrace;
  bool get isEmailVerificationRequired =>
      status == AuthStatus.emailVerificationRequired;
  bool get isPasswordRecovery => status == AuthStatus.passwordRecovery;
  bool get isInitialLoading => status == AuthStatus.initialLoading;
  bool get isReauthenticationRequired =>
      status == AuthStatus.reauthenticationRequired;
  bool get isLoading =>
      status == AuthStatus.authenticating ||
      status == AuthStatus.tokenRefreshing ||
      status == AuthStatus.initialLoading;
  User? get user => supabaseUser;

  AuthState copyWith({
    AuthStatus? status,
    User? supabaseUser,
    String? email,
    String? displayName,
    String? avatarUrl,
    bool? isLoading,
    String? errorMessage,
    bool? otpSent,
    bool clearError = false,
  }) {
    return AuthState(
      status: (isLoading ?? false)
          ? AuthStatus.authenticating
          : (status ??
                (this.status == AuthStatus.authenticating
                    ? AuthStatus.guest
                    : this.status)),
      supabaseUser: supabaseUser ?? this.supabaseUser,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      otpSent: otpSent ?? this.otpSent,
    );
  }
}

class AuthService extends Notifier<AuthState> {
  static const String guestModeKey = 'fit_host_guest_mode';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isSupabaseInitialized = false;
  StreamSubscription? _authSub;

  @override
  AuthState build() {
    try {
      if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
        return const AuthState(status: AuthStatus.guest);
      }
      final binding = WidgetsBinding.instance;
      if (binding.runtimeType.toString().contains('Test')) {
        return const AuthState(status: AuthStatus.guest);
      }
    } catch (_) {}
    _initSupabaseAndLoadUser();
    return const AuthState(status: AuthStatus.initialLoading);
  }

  Future<void> _initSupabaseAndLoadUser() async {
    String? guestFlag;
    try {
      guestFlag = await _storage.read(key: guestModeKey);
    } catch (_) {}

    try {
      // If accessing client succeeds without throwing, Supabase is initialized
      final client = Supabase.instance.client;
      if (client.rest.url.isNotEmpty) {
        _isSupabaseInitialized = true;
      }
    } catch (_) {
      try {
        await Supabase.initialize(
          url: getSupabaseUrl(),
          // ignore: deprecated_member_use
          anonKey: getSupabasePublishableKey(),
        );
        _isSupabaseInitialized = true;
      } catch (e) {
        debugPrint('[AuthService] Supabase init info: $e');
      }
    }

    if (_isSupabaseInitialized) {
      try {
        final client = Supabase.instance.client;
        RouterAuthNotifier.instance.initialize(client);
        final currentSession = client.auth.currentSession;
        final currentUser = client.auth.currentUser;

        // 1. If persistent session is active, restore authenticated user immediately
        if (currentSession != null && currentUser != null) {
          if (!ref.mounted) return;
          state = AuthState(
            status: AuthStatus.authenticated,
            supabaseUser: currentUser,
            email: currentUser.email,
            displayName:
                currentUser.userMetadata?['name'] as String? ??
                currentUser.userMetadata?['full_name'] as String? ??
                currentUser.email?.split('@').first,
            avatarUrl: currentUser.userMetadata?['avatar_url'] as String?,
          );
          _storage.write(key: guestModeKey, value: 'false').ignore();
          RouterAuthNotifier.instance.notifyAuthChanged();
          _attachAuthListener(client);
          return;
        }

        // 2. If explicitly guest mode
        if (guestFlag == 'true') {
          if (!ref.mounted) return;
          state = const AuthState(status: AuthStatus.guest);
          _attachAuthListener(client);
          return;
        }

        // 3. Attach listener for subsequent state transitions
        _attachAuthListener(client);
      } catch (e) {
        debugPrint('[AuthService] Auth restoration notice: $e');
      }
    }

    if (!ref.mounted) return;
    state = const AuthState(status: AuthStatus.guest);
  }

  void _attachAuthListener(SupabaseClient client) {
    _authSub?.cancel();
    ref.onDispose(() {
      _authSub?.cancel();
    });

    _authSub = client.auth.onAuthStateChange.listen(
      (data) {
        if (!ref.mounted) return;
        final session = data.session;
        debugPrint(
          '[AuthService] onAuthStateChange event: ${data.event}, session user: ${session?.user.email}',
        );
        if (data.event == AuthChangeEvent.passwordRecovery) {
          state = state.copyWith(
            status: AuthStatus.passwordRecovery,
            supabaseUser: session?.user,
            email: session?.user.email,
            clearError: true,
          );
        } else if (data.event == AuthChangeEvent.tokenRefreshed &&
            session != null) {
          final u = session.user;
          final displayName =
              u.userMetadata?['name'] as String? ??
              u.userMetadata?['full_name'] as String? ??
              u.email?.split('@').first;
          final avatarUrl = u.userMetadata?['avatar_url'] as String?;
          state = state.copyWith(
            status: AuthStatus.authenticated,
            supabaseUser: u,
            email: u.email,
            displayName: displayName,
            avatarUrl: avatarUrl,
            clearError: true,
          );
          RouterAuthNotifier.instance.notifyAuthChanged();
        } else if (session != null) {
          final u = session.user;
          _storage.write(key: guestModeKey, value: 'false').ignore();
          final displayName =
              u.userMetadata?['name'] as String? ??
              u.userMetadata?['full_name'] as String? ??
              u.email?.split('@').first;
          final avatarUrl = u.userMetadata?['avatar_url'] as String?;
          state = state.copyWith(
            status: AuthStatus.authenticated,
            supabaseUser: u,
            email: u.email,
            displayName: displayName,
            avatarUrl: avatarUrl,
            clearError: true,
          );
          RouterAuthNotifier.instance.notifyAuthChanged();

          // If local user profile name is default guest/athlete, sync with Google display name
          try {
            if (displayName != null && displayName.isNotEmpty) {
              final profile = ref.read(userProfileProvider);
              if (profile.name == 'Guest Athlete' ||
                  profile.name == 'Athlete' ||
                  profile.name.isEmpty) {
                ref
                    .read(userProfileProvider.notifier)
                    .updateProfile(profile.copyWith(name: displayName))
                    .ignore();
              }
            }
          } catch (_) {}
        } else if (data.event == AuthChangeEvent.signedOut) {
          state = const AuthState(status: AuthStatus.guest);
          RouterAuthNotifier.instance.notifyAuthChanged();
        }
      },
      onError: (error, stackTrace) {
        debugPrint('[AuthService] onAuthStateChange stream error: $error');
        if (!ref.mounted) return;
        final msg = formatAuthError(error);
        state = state.copyWith(
          status: state.status,
          isLoading: false,
          errorMessage: msg.isNotEmpty
              ? msg
              : 'Authentication failed. Please try again.',
        );
      },
    );
  }

  /// Guest -> Account claim transaction (Deliverable G)
  Future<bool> claimLocalData(
    String newUserId, {
    required GuestAccountClaimService claimService,
  }) async {
    try {
      final outcome = await claimService.claimGuestDataToAccount(newUserId);
      return outcome != ClaimOutcome.failed;
    } catch (e) {
      debugPrint('[AuthService] claimLocalData failure: $e');
      rethrow;
    }
  }

  Future<void> continueAsGuest() async {
    try {
      await _storage.write(key: guestModeKey, value: 'true');
    } catch (_) {}
    state = const AuthState(status: AuthStatus.guest);
  }

  Future<bool> sendEmailOtp(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final trimmed = email.trim().toLowerCase();
    if (trimmed.isEmpty || !trimmed.contains('@')) {
      state = state.copyWith(
        status: state.status,
        errorMessage: 'Please enter a valid email address.',
      );
      return false;
    }

    try {
      if (!_isSupabaseInitialized || getSupabaseUrl().contains('xyzcompany')) {
        throw const AuthException(
          'Supabase authentication backend is not configured.',
        );
      }
      await Supabase.instance.client.auth.signInWithOtp(
        email: trimmed,
        emailRedirectTo: kIsWeb ? null : 'io.supabase.fithost://login-callback',
      );

      state = state.copyWith(
        status: state.status,
        isLoading: false,
        otpSent: true,
        email: trimmed,
        clearError: true,
      );
      return true;
    } catch (e) {
      final msg = formatAuthError(e);
      state = state.copyWith(
        status: AuthStatus.guest,
        isLoading: false,
        errorMessage: msg.isNotEmpty
            ? msg
            : 'Failed to send OTP code. Please check your email.',
      );
      return false;
    }
  }

  /// Sends a reauthentication OTP code to the current authenticated user's email
  /// using Supabase's Reauthentication SMTP email template.
  Future<bool> sendReauthenticationOtp() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (!_isSupabaseInitialized || getSupabaseUrl().contains('xyzcompany')) {
        throw const AuthException(
          'Supabase authentication backend is not configured.',
        );
      }
      await Supabase.instance.client.auth.reauthenticate();
      state = state.copyWith(
        status: state.status,
        isLoading: false,
        otpSent: true,
        clearError: true,
      );
      return true;
    } catch (e) {
      final msg = formatAuthError(e);
      state = state.copyWith(
        status: state.status,
        isLoading: false,
        errorMessage: msg.isNotEmpty
            ? msg
            : 'Failed to send reauthentication code. Please try again.',
      );
      return false;
    }
  }

  void setEmail(String email) {
    state = state.copyWith(email: email.trim().toLowerCase());
  }

  Future<bool> verifyOtp(
    String otpCode, {
    String? email,
    OtpType type = OtpType.signup,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final cleanCode = otpCode.replaceAll(RegExp(r'\s+|-'), '').trim();
    final targetEmail = (email != null && email.isNotEmpty)
        ? email.trim().toLowerCase()
        : state.email;
    if (targetEmail == null || targetEmail.isEmpty) {
      state = state.copyWith(
        status: AuthStatus.guest,
        isLoading: false,
        errorMessage:
            'Email session expired. Please enter your email address again.',
      );
      return false;
    }

    if (cleanCode.length < 6) {
      state = state.copyWith(
        status: state.status,
        isLoading: false,
        errorMessage: 'Please enter the complete verification code.',
      );
      return false;
    }

    try {
      if (!_isSupabaseInitialized || getSupabaseUrl().contains('xyzcompany')) {
        throw const AuthException(
          'Supabase authentication backend is not configured.',
        );
      }
      AuthResponse? res;
      final candidates = <OtpType>[
        type,
        if (type != OtpType.signup) OtpType.signup,
        if (type != OtpType.email) OtpType.email,
        if (type != OtpType.magiclink) OtpType.magiclink,
        if (type != OtpType.recovery) OtpType.recovery,
      ];

      dynamic lastError;
      for (final candidate in candidates) {
        try {
          res = await Supabase.instance.client.auth.verifyOTP(
            type: candidate,
            token: cleanCode,
            email: targetEmail,
          );
          if (res.user != null) {
            break;
          }
        } catch (e) {
          lastError = e;
          final errStr = e.toString().toLowerCase();
          if (errStr.contains('rate limit') ||
              errStr.contains('too many requests')) {
            break;
          }
        }
      }

      // If candidate verifyOTP attempts did not succeed but user has an active session,
      // verify the reauthentication OTP nonce directly with Supabase GoTrue
      if (res?.user == null &&
          Supabase.instance.client.auth.currentSession != null) {
        try {
          final userRes = await Supabase.instance.client.auth.updateUser(
            UserAttributes(nonce: cleanCode),
          );
          if (userRes.user != null) {
            final u = userRes.user!;
            await _storage.write(key: guestModeKey, value: 'false');
            state = AuthState(
              status: AuthStatus.authenticated,
              supabaseUser: u,
              email: u.email,
              displayName:
                  u.userMetadata?['name'] as String? ??
                  u.email?.split('@').first,
              avatarUrl: u.userMetadata?['avatar_url'] as String?,
            );
            return true;
          }
        } catch (nonceErr) {
          debugPrint(
            '[AuthService] Reauthentication nonce verification check: $nonceErr',
          );
          lastError ??= nonceErr;
        }
      }

      if (res?.user != null) {
        await _storage.write(key: guestModeKey, value: 'false');
        state = AuthState(
          status: AuthStatus.authenticated,
          supabaseUser: res!.user,
          email: res.user!.email,
          displayName:
              res.user!.userMetadata?['name'] as String? ??
              res.user!.email?.split('@').first,
          avatarUrl: res.user!.userMetadata?['avatar_url'] as String?,
        );
        return true;
      }
      if (lastError != null) {
        throw lastError;
      }
      throw const AuthException(
        'Invalid OTP code. Please check and try again.',
      );
    } catch (e) {
      final msg = formatAuthError(e);
      state = state.copyWith(
        status: AuthStatus.guest,
        isLoading: false,
        errorMessage: msg.isNotEmpty
            ? msg
            : 'Invalid OTP code. Please check and try again.',
      );
      return false;
    }
  }

  Future<bool> updateUserPassword(String newPassword, {String? nonce}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (!_isSupabaseInitialized || getSupabaseUrl().contains('xyzcompany')) {
        throw const AuthException(
          'Supabase authentication backend is not configured.',
        );
      }
      final cleanNonce = nonce?.replaceAll(RegExp(r'\s+|-'), '').trim();
      final res = await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          password: newPassword,
          nonce: (cleanNonce != null && cleanNonce.isNotEmpty)
              ? cleanNonce
              : null,
        ),
      );
      if (res.user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          supabaseUser: res.user,
          clearError: true,
        );
        return true;
      }
      throw const AuthException('Failed to update password.');
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('reauthentication') || errStr.contains('reauth')) {
        state = state.copyWith(
          status: AuthStatus.reauthenticationRequired,
          isLoading: false,
          errorMessage:
              'Reauthentication required. A verification code has been sent to your email.',
        );
        await sendReauthenticationOtp();
      } else {
        final msg = formatAuthError(e);
        state = state.copyWith(
          status: state.status,
          isLoading: false,
          errorMessage: msg.isNotEmpty ? msg : 'Failed to update password.',
        );
      }
      rethrow;
    }
  }

  Future<AuthResponse?> signUpWithPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final trimmed = email.trim().toLowerCase();

    try {
      if (!_isSupabaseInitialized || getSupabaseUrl().contains('xyzcompany')) {
        throw const AuthException(
          'Supabase authentication backend is not configured.',
        );
      }
      final res = await Supabase.instance.client.auth.signUp(
        email: trimmed,
        password: password,
        data: displayName != null ? {'name': displayName} : null,
        emailRedirectTo: kIsWeb ? null : 'io.supabase.fithost://login-callback',
      );
      if (res.user != null) {
        if (res.session != null) {
          await _storage.write(key: guestModeKey, value: 'false');
          state = AuthState(
            status: AuthStatus.authenticated,
            supabaseUser: res.user,
            email: res.user!.email,
            displayName:
                displayName ??
                res.user!.userMetadata?['name'] as String? ??
                res.user!.email?.split('@').first,
          );
        } else {
          // Awaiting email confirmation
          state = state.copyWith(
            status: AuthStatus.guest,
            email: trimmed,
            clearError: true,
          );
        }
        return res;
      }
      throw const AuthException('Sign up failed.');
    } catch (e) {
      final msg = formatAuthError(e);
      state = state.copyWith(
        status: AuthStatus.guest,
        isLoading: false,
        errorMessage: msg,
      );
      rethrow;
    }
  }

  Future<AuthResponse?> signInWithPassword({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final trimmed = email.trim().toLowerCase();

    try {
      if (!_isSupabaseInitialized || getSupabaseUrl().contains('xyzcompany')) {
        throw const AuthException(
          'Supabase authentication backend is not configured.',
        );
      }
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: trimmed,
        password: password,
      );
      if (res.user != null) {
        await _storage.write(key: guestModeKey, value: 'false');
        state = AuthState(
          status: AuthStatus.authenticated,
          supabaseUser: res.user,
          email: res.user!.email,
          displayName:
              res.user!.userMetadata?['name'] as String? ??
              res.user!.email?.split('@').first,
          avatarUrl: res.user!.userMetadata?['avatar_url'] as String?,
        );
        return res;
      }
      throw const AuthException('Invalid email or password.');
    } catch (e) {
      final msg = formatAuthError(e);
      state = state.copyWith(
        status: AuthStatus.guest,
        isLoading: false,
        errorMessage: msg,
      );
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final trimmed = email.trim().toLowerCase();

    try {
      if (!_isSupabaseInitialized || getSupabaseUrl().contains('xyzcompany')) {
        throw const AuthException(
          'Supabase authentication backend is not configured.',
        );
      }
      await Supabase.instance.client.auth.resetPasswordForEmail(
        trimmed,
        redirectTo: kIsWeb ? null : 'io.supabase.fithost://login-callback',
      );
      state = state.copyWith(
        status: AuthStatus.guest,
        isLoading: false,
        email: trimmed,
        clearError: true,
      );
    } catch (e) {
      final msg = formatAuthError(e);
      state = state.copyWith(
        status: AuthStatus.guest,
        isLoading: false,
        errorMessage: msg,
      );
      rethrow;
    }
  }

  Future<bool> resetPasswordWithOtp({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final trimmedEmail = email.trim().toLowerCase();
    final cleanCode = otpCode.replaceAll(RegExp(r'\s+|-'), '').trim();

    if (newPassword.length < 6) {
      state = state.copyWith(
        status: AuthStatus.guest,
        isLoading: false,
        errorMessage: 'Password must be at least 6 characters.',
      );
      return false;
    }

    try {
      if (!_isSupabaseInitialized || getSupabaseUrl().contains('xyzcompany')) {
        throw const AuthException(
          'Supabase authentication backend is not configured.',
        );
      }

      final verified = await verifyOtp(
        cleanCode,
        email: trimmedEmail,
        type: OtpType.recovery,
      );

      if (!verified) {
        final existingErr = state.errorMessage;
        throw AuthException(
          existingErr != null && existingErr.isNotEmpty
              ? existingErr
              : 'Invalid or expired recovery code. Please check and try again.',
        );
      }

      final updateRes = await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (updateRes.user != null) {
        await _storage.write(key: guestModeKey, value: 'false');
        state = state.copyWith(
          status: AuthStatus.authenticated,
          supabaseUser: updateRes.user,
          email: updateRes.user!.email,
          isLoading: false,
          clearError: true,
        );
        return true;
      }
      throw const AuthException('Failed to update password.');
    } catch (e) {
      final msg = formatAuthError(e);
      state = state.copyWith(
        status: AuthStatus.guest,
        isLoading: false,
        errorMessage: msg.isNotEmpty
            ? msg
            : 'Failed to reset password. Please check your code.',
      );
      return false;
    }
  }

  Future<void> deleteAccount({required String passwordConfirm}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final currentEmail = state.email;
    if (currentEmail == null) {
      state = state.copyWith(isLoading: false);
      throw Exception('No active authenticated user session found.');
    }

    try {
      if (!_isSupabaseInitialized || getSupabaseUrl().contains('xyzcompany')) {
        throw const AuthException(
          'Supabase authentication backend is not configured.',
        );
      }
      // 1. Re-authenticate to ensure user possesses the correct credentials
      await Supabase.instance.client.auth.signInWithPassword(
        email: currentEmail,
        password: passwordConfirm,
      );

      // 2. Execute account deletion via Supabase RPC
      try {
        await Supabase.instance.client.rpc('delete_user');
      } catch (e) {
        debugPrint('[AuthService] delete_user RPC call note: $e');
      }
      await Supabase.instance.client.auth.signOut();
      await _storage.write(key: guestModeKey, value: 'true');
      state = const AuthState(status: AuthStatus.guest);
    } catch (e) {
      final msg = formatAuthError(e);
      state = state.copyWith(
        status: state.status,
        isLoading: false,
        errorMessage: 'Account deletion failed: $msg',
      );
      rethrow;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (!_isSupabaseInitialized || getSupabaseUrl().contains('xyzcompany')) {
        throw const AuthException(
          'Supabase Google OAuth is not configured. Please configure valid Supabase credentials.',
        );
      }

      // 1. Attempt Native Google Sign-In on mobile (100% Free, zero browser redirects, zero Supabase branding shown)
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final signIn = GoogleSignIn.instance;
        await signIn.initialize(serverClientId: kGoogleWebClientId);
        if (signIn.supportsAuthenticate()) {
          try {
            final googleAccount = await signIn.authenticate();
            final idToken = googleAccount.authentication.idToken;
            if (idToken != null && idToken.isNotEmpty) {
              String? accessToken;
              try {
                final authz = await googleAccount.authorizationClient
                    .authorizationForScopes(['email', 'profile']);
                accessToken = authz?.accessToken;
              } catch (_) {}

              final res = await Supabase.instance.client.auth.signInWithIdToken(
                provider: OAuthProvider.google,
                idToken: idToken,
                accessToken: accessToken,
              );

              if (res.session != null && res.user != null) {
                final u = res.user!;
                await _storage.write(key: guestModeKey, value: 'false');
                final displayName =
                    u.userMetadata?['name'] as String? ??
                    u.userMetadata?['full_name'] as String? ??
                    googleAccount.displayName ??
                    u.email?.split('@').first;
                final avatarUrl =
                    u.userMetadata?['avatar_url'] as String? ??
                    googleAccount.photoUrl;

                state = state.copyWith(
                  status: AuthStatus.authenticated,
                  supabaseUser: u,
                  email: u.email,
                  displayName: displayName,
                  avatarUrl: avatarUrl,
                  clearError: true,
                );
                RouterAuthNotifier.instance.notifyAuthChanged();
                return true;
              } else {
                state = state.copyWith(
                  isLoading: false,
                  errorMessage:
                      'Authentication session could not be established with backend.',
                );
                return false;
              }
            } else {
              debugPrint(
                '[AuthService] Native Google Sign-In: idToken was null/empty',
              );
              state = state.copyWith(
                isLoading: false,
                errorMessage:
                    'Google Sign-In did not return an authentication token. Please verify Google Play Services.',
              );
              return false;
            }
          } catch (nativeErr) {
            debugPrint(
              '[AuthService] Native Google Sign-In notice: $nativeErr',
            );
            final errStr = nativeErr.toString();
            // Handle user cancel cleanly without bouncing to browser
            if (errStr.contains('canceled') && !errStr.contains('[16]')) {
              state = state.copyWith(isLoading: false);
              return false;
            }

            String friendlyMsg = 'Google Sign-In failed.';
            if (errStr.contains('[16]') ||
                errStr.contains('Account reauth failed')) {
              friendlyMsg =
                  'Google Play Services configuration needed: Please register your Android OAuth client in Google Cloud Console with SHA-1 8D:22:AA:48:AC:E9:17:9C:9F:F6:3C:FA:1E:7D:10:CF:A7:DC:BE:19.';
            } else if (nativeErr is AuthException) {
              friendlyMsg = formatAuthError(nativeErr);
            }

            state = state.copyWith(
              status: AuthStatus.guest,
              isLoading: false,
              errorMessage: friendlyMsg,
            );
            return false;
          }
        }
      }

      // 2. Browser OAuth flow (only for Web or devices where native authenticate is unsupported)
      final oAuthRes = await Supabase.instance.client.auth.getOAuthSignInUrl(
        provider: OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.fithost://login-callback',
      );

      final initiated = await launchUrl(
        Uri.parse(oAuthRes.url),
        mode: LaunchMode.externalApplication,
      );
      state = state.copyWith(isLoading: false);
      return initiated;
    } catch (e) {
      final msg = formatAuthError(e);
      state = state.copyWith(
        status: AuthStatus.guest,
        isLoading: false,
        errorMessage: msg.isNotEmpty ? msg : 'Google Sign-In failed.',
      );
      return false;
    }
  }

  Future<bool> resendVerificationEmail(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final trimmed = email.trim().toLowerCase();
    try {
      if (!_isSupabaseInitialized || getSupabaseUrl().contains('xyzcompany')) {
        throw const AuthException(
          'Supabase authentication backend is not configured.',
        );
      }

      // If user has an active session and requires reauthentication or matches session email,
      // trigger reauthenticate() first which maps directly to Supabase Reauthentication SMTP
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null &&
          (state.isReauthenticationRequired ||
              session.user.email?.toLowerCase() == trimmed)) {
        try {
          await Supabase.instance.client.auth.reauthenticate();
          state = state.copyWith(
            status: state.status,
            isLoading: false,
            email: trimmed,
            otpSent: true,
            clearError: true,
          );
          return true;
        } catch (reauthErr) {
          debugPrint('[AuthService] Reauthentication send notice: $reauthErr');
        }
      }

      try {
        await Supabase.instance.client.auth.resend(
          type: OtpType.signup,
          email: trimmed,
          emailRedirectTo: kIsWeb
              ? null
              : 'io.supabase.fithost://login-callback',
        );
      } catch (_) {
        // Fallback to signInWithOtp if signup resend fails (e.g. user exists but unconfirmed)
        await Supabase.instance.client.auth.signInWithOtp(
          email: trimmed,
          emailRedirectTo: kIsWeb
              ? null
              : 'io.supabase.fithost://login-callback',
        );
      }
      state = state.copyWith(
        status: state.status == AuthStatus.authenticated
            ? AuthStatus.authenticated
            : AuthStatus.guest,
        isLoading: false,
        email: trimmed,
        otpSent: true,
        clearError: true,
      );
      return true;
    } catch (e) {
      final msg = formatAuthError(e);
      state = state.copyWith(
        status: state.status == AuthStatus.authenticated
            ? AuthStatus.authenticated
            : AuthStatus.guest,
        isLoading: false,
        errorMessage: msg.isNotEmpty
            ? msg
            : 'Failed to resend confirmation email.',
      );
      return false;
    }
  }

  Future<void> updateUserProfileMetadata({
    String? name,
    String? avatarUrl,
  }) async {
    try {
      if (_isSupabaseInitialized &&
          state.isAuthenticated &&
          state.supabaseUser != null) {
        final data = <String, dynamic>{};
        if (name != null) data['name'] = name;
        if (avatarUrl != null) data['avatar_url'] = avatarUrl;
        if (data.isNotEmpty) {
          final res = await Supabase.instance.client.auth.updateUser(
            UserAttributes(data: data),
          );
          if (res.user != null) {
            state = state.copyWith(
              supabaseUser: res.user,
              displayName: name ?? state.displayName,
              avatarUrl: avatarUrl ?? state.avatarUrl,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[AuthService] Update user metadata notice: $e');
    }
  }

  void setManualAuthenticatedUser(User user) {
    state = AuthState(
      status: AuthStatus.authenticated,
      supabaseUser: user,
      email: user.email,
      displayName:
          user.userMetadata?['name'] as String? ?? user.email?.split('@').first,
    );
  }

  void setManualGuest() {
    state = const AuthState(status: AuthStatus.guest);
  }

  void setManualOfflineGrace() {
    state = AuthState(
      status: AuthStatus.offlineGrace,
      supabaseUser: state.supabaseUser,
      email: state.email,
    );
  }

  /// Initiates token refresh with strict offlineGrace and signedOut transitions:
  /// - Network failure (e.g. SocketException) -> AuthStatus.offlineGrace, KEEP cached user.
  /// - Revoked/invalid token (AuthException 401/403) -> AuthStatus.signedOut.
  /// - Never auto-downgrades authenticated -> guest on network failure.
  Future<void> refreshSession({
    Future<void> Function()? customRefreshAction,
  }) async {
    final cachedUser = state.supabaseUser;
    final cachedEmail = state.email;
    final cachedDisplayName = state.displayName;
    final cachedAvatarUrl = state.avatarUrl;

    state = state.copyWith(status: AuthStatus.tokenRefreshing);

    try {
      if (customRefreshAction != null) {
        await customRefreshAction();
      } else if (_isSupabaseInitialized) {
        await Supabase.instance.client.auth.refreshSession();
      }
      state = state.copyWith(
        status: AuthStatus.authenticated,
        clearError: true,
      );
    } on SocketException catch (e) {
      // Network failure -> offlineGrace, KEEP the cached user
      debugPrint('[AuthService] refreshSession SocketException: $e');
      state = AuthState(
        status: AuthStatus.offlineGrace,
        supabaseUser: cachedUser,
        email: cachedEmail,
        displayName: cachedDisplayName,
        avatarUrl: cachedAvatarUrl,
      );
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
        state = AuthState(
          status: AuthStatus.signedOut,
          errorMessage: e.message,
        );
      } else {
        // Other auth error / transient error -> offlineGrace, keep cached user
        state = AuthState(
          status: AuthStatus.offlineGrace,
          supabaseUser: cachedUser,
          email: cachedEmail,
          displayName: cachedDisplayName,
          avatarUrl: cachedAvatarUrl,
          errorMessage: e.message,
        );
      }
    } catch (e) {
      final str = e.toString().toLowerCase();
      if (str.contains('socketexception') ||
          str.contains('network') ||
          str.contains('failed host lookup') ||
          str.contains('connection') ||
          str.contains('clientexception')) {
        // Network/offline -> offlineGrace, KEEP the cached user
        state = AuthState(
          status: AuthStatus.offlineGrace,
          supabaseUser: cachedUser,
          email: cachedEmail,
          displayName: cachedDisplayName,
          avatarUrl: cachedAvatarUrl,
        );
      } else {
        state = AuthState(
          status: AuthStatus.signedOut,
          errorMessage: e.toString(),
        );
      }
    }
  }

  Future<void> signOutToGuest() async {
    final priorUserId = state.user?.id;
    try {
      if (_isSupabaseInitialized) {
        await Supabase.instance.client.auth.signOut();
      }
    } catch (e) {
      debugPrint('[AuthService] Sign out notice: $e');
    }
    try {
      await _storage.write(key: guestModeKey, value: 'true');
    } catch (_) {}
    if (priorUserId != null && priorUserId != 'guest') {
      try {
        await ref.read(databaseProvider).clearAccountCache(priorUserId);
      } catch (e) {
        debugPrint('[AuthService] Clear account cache notice: $e');
      }
    }
    state = const AuthState(status: AuthStatus.guest);
  }

  Future<void> signOut() => signOutToGuest();

  void resetOtpState() {
    state = state.copyWith(otpSent: false, clearError: true);
  }
}

final authProvider = NotifierProvider<AuthService, AuthState>(AuthService.new);

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final authStatusProvider = Provider<AuthStatus>((ref) {
  return ref.watch(authProvider).status;
});
