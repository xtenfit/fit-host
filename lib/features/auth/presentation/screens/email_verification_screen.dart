import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/analytics_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../helpers/auth_navigation_helper.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String? email;

  const EmailVerificationScreen({super.key, this.email});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  late final TextEditingController _emailController;
  bool _isResending = false;
  bool _isVerifyingOtp = false;
  bool _isNavigating = false;
  String? _otpError;
  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email ?? '');
    _startCountdown();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingAuth();
    });
  }

  void _checkExistingAuth() {
    if (_isNavigating || !mounted) return;
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null && session.user.id.isNotEmpty) {
        _handlePostAuthNavigation(session.user.id);
        return;
      }
    } catch (_) {}

    final auth = ref.read(authProvider);
    if (auth.isAuthenticated && auth.user != null) {
      _handlePostAuthNavigation(auth.user!.id);
    }
  }

  Future<void> _handlePostAuthNavigation(String userId) async {
    if (_isNavigating) return;
    _isNavigating = true;
    _timer?.cancel();
    if (!mounted) return;
    await AuthNavigationHelper.checkAccountSetupAndNavigate(
      context,
      ref,
      userId,
    );
  }

  void _startCountdown() {
    _resendCountdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_resendCountdown > 0) {
          setState(() => _resendCountdown--);
        } else {
          timer.cancel();
        }
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _emailController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String _getTargetEmail() {
    if (widget.email != null && widget.email!.trim().isNotEmpty) {
      return widget.email!.trim();
    }
    if (_emailController.text.trim().isNotEmpty) {
      return _emailController.text.trim();
    }
    return ref.read(authProvider).email ?? '';
  }

  Future<void> _handleResend() async {
    final email = _getTargetEmail();
    if (_resendCountdown > 0) return;
    if (email.isEmpty) {
      setState(() => _otpError = 'Please enter your email address to resend.');
      return;
    }

    setState(() {
      _isResending = true;
      _otpError = null;
    });

    try {
      final authState = ref.read(authProvider);
      final bool success;
      if (authState.isReauthenticationRequired) {
        success = await ref
            .read(authProvider.notifier)
            .sendReauthenticationOtp();
      } else {
        success = await ref
            .read(authProvider.notifier)
            .resendVerificationEmail(email);
      }

      if (mounted) {
        setState(() => _isResending = false);
        if (success) {
          _startCountdown();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Verification link and code resent! Please check your inbox.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          final err =
              ref.read(authProvider).errorMessage ??
              'Failed to resend confirmation email.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isResending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(formatAuthError(e)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleVerifyOtp() async {
    final code = _otpController.text.replaceAll(RegExp(r'\s+|-'), '').trim();
    final email = _getTargetEmail();

    if (email.isEmpty) {
      setState(() => _otpError = 'Please enter your account email address.');
      return;
    }

    if (code.isEmpty || code.length < 6) {
      setState(
        () => _otpError = 'Please enter the complete verification code.',
      );
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
      _otpError = null;
    });

    try {
      final success = await ref
          .read(authProvider.notifier)
          .verifyOtp(code, email: email, type: OtpType.signup);
      if (mounted) {
        setState(() => _isVerifyingOtp = false);
        if (success) {
          AnalyticsService.instance
              .track(
                AnalyticsEvents.signupCompleted,
                properties: {'signup_method': 'password'},
              )
              .ignore();
          final newUserId =
              ref.read(authProvider).user?.id ??
              'user_${DateTime.now().millisecondsSinceEpoch}';
          await _handlePostAuthNavigation(newUserId);
        } else {
          setState(() {
            _otpError =
                ref.read(authProvider).errorMessage ??
                'Invalid OTP code. Please check and try again.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifyingOtp = false;
          _otpError = formatAuthError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for deep link authentication (user clicks link in email on device)
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.isAuthenticated && mounted && !_isNavigating) {
        final newUserId =
            next.user?.id ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
        _handlePostAuthNavigation(newUserId);
      }
    });

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final targetEmail = _getTargetEmail();
    final emailDisplay = targetEmail.isNotEmpty
        ? targetEmail
        : 'your email address';

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to Sign In',
          onPressed: () => context.go('/auth/sign-in'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Animated Glowing Envelope Icon
                Center(
                  child: Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.limeGreen.withValues(alpha: 0.12),
                      border: Border.all(
                        color: AppColors.limeGreen.withValues(alpha: 0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.limeGreen.withValues(alpha: 0.2),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_rounded,
                      color: AppColors.limeGreen,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                const Text(
                  'Verify Your Email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),

                // Description
                Text(
                  'We have sent an authentication link and confirmation code to:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                if (widget.email != null && widget.email!.isNotEmpty) ...[
                  Text(
                    emailDisplay,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.limeGreen,
                    ),
                  ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'Enter your account email',
                        filled: true,
                        fillColor: isDark
                            ? AppColors.darkSurfaceElevated
                            : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // OTP Code Input Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceElevated
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkSurfaceBorder
                          : AppColors.lightSurfaceBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter Verification Code',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Copy the verification code (6 or 8 digits) from your email:',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),

                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 8,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6,
                          color: AppColors.limeGreen,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '• • • • • • (• •)',
                          hintStyle: TextStyle(
                            fontSize: 18,
                            letterSpacing: 4,
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppColors.darkBackground
                              : Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkSurfaceBorder
                                  : AppColors.lightSurfaceBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkSurfaceBorder
                                  : AppColors.lightSurfaceBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.limeGreen,
                              width: 2,
                            ),
                          ),
                        ),
                      ),

                      if (_otpError != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _otpError!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Verify Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.limeGreen,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _isVerifyingOtp ? null : _handleVerifyOtp,
                          child: _isVerifyingOtp
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Text(
                                  'Verify Code',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Or Check Link Button
                SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : Colors.black87,
                      side: BorderSide(
                        color: isDark
                            ? AppColors.darkSurfaceBorder
                            : AppColors.lightSurfaceBorder,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => context.go('/auth/sign-in'),
                    child: const Text(
                      'I Clicked the Link in My Email',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Resend email
                Center(
                  child: _isResending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.limeGreen,
                          ),
                        )
                      : TextButton.icon(
                          onPressed: _resendCountdown == 0
                              ? _handleResend
                              : null,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(
                            _resendCountdown > 0
                                ? 'Resend code in ${_resendCountdown}s'
                                : 'Resend verification email',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _resendCountdown > 0
                                  ? (isDark ? Colors.white38 : Colors.black38)
                                  : AppColors.electricCyan,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
