import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/supabase_service.dart';
import '../helpers/auth_navigation_helper.dart';
import '../widgets/google_sign_in_button.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isNavigating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingAuth();
    });
  }

  void _checkExistingAuth() {
    if (_isNavigating || !mounted) return;
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null && session.user.id.isNotEmpty) {
        _isNavigating = true;
        AuthNavigationHelper.checkAccountSetupAndNavigate(
          context,
          ref,
          session.user.id,
        );
        return;
      }
    } catch (_) {}

    final auth = ref.read(authProvider);
    if (auth.isAuthenticated && auth.user != null) {
      _isNavigating = true;
      AuthNavigationHelper.checkAccountSetupAndNavigate(
        context,
        ref,
        auth.user!.id,
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authProvider.notifier);
      final email = _emailController.text.trim();
      final res = await authService.signInWithPassword(
        email: email,
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isNavigating = true;
        });
        final newUserId = res?.user?.id ?? 'account-user';
        await AuthNavigationHelper.checkAccountSetupAndNavigate(
          context,
          ref,
          newUserId,
        );
      }
    } catch (e) {
      if (mounted) {
        final errText = formatAuthError(e);
        final lower = errText.toLowerCase();
        final isUnconfirmed =
            lower.contains('not confirmed') ||
            lower.contains('not verified') ||
            lower.contains('unverified') ||
            lower.contains('email_not_confirmed');

        if (isUnconfirmed) {
          final email = _emailController.text.trim();
          ref
              .read(authProvider.notifier)
              .resendVerificationEmail(email)
              .ignore();
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Account requires email verification. 6-digit OTP code sent to $email.',
              ),
              backgroundColor: AppColors.limeGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.push(
            '/auth/verify-email?email=${Uri.encodeComponent(email)}',
          );
          return;
        }

        setState(() {
          _isLoading = false;
          _errorMessage = errText;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.isAuthenticated &&
          next.user != null &&
          !_isNavigating &&
          mounted) {
        setState(() => _isNavigating = true);
        AuthNavigationHelper.checkAccountSetupAndNavigate(
          context,
          ref,
          next.user!.id,
        );
      }
    });
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/auth-decision');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Brand Icon & Header
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.limeGreen.withValues(alpha: 0.15),
                            border: Border.all(
                              color: AppColors.limeGreen,
                              width: 2,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.fitness_center_rounded,
                              color: AppColors.limeGreen,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Welcome Back',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: isDark
                              ? Colors.white
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to synchronize workouts, nutrition, and steps across all your devices.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 28),

                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: AppColors.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: AppColors.error,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_errorMessage!.toLowerCase().contains(
                                    'not verified',
                                  ) ||
                                  _errorMessage!.toLowerCase().contains(
                                    'not confirmed',
                                  ) ||
                                  _errorMessage!.toLowerCase().contains(
                                    'unverified',
                                  )) ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.limeGreen,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.mark_email_read_rounded,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Enter Email Verification Code',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    onPressed: () {
                                      final email = _emailController.text
                                          .trim();
                                      context.push(
                                        '/auth/verify-email?email=$email',
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'athlete@example.com',
                          prefixIcon: const Icon(Icons.email_outlined),
                          filled: true,
                          fillColor: isDark
                              ? AppColors.darkSurfaceElevated
                              : Colors.white,
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
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Enter your email';
                          }
                          if (!val.contains('@') || !val.contains('.')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppColors.darkSurfaceElevated
                              : Colors.white,
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
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Enter your password';
                          }
                          if (val.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.go('/auth/forgot-password'),
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.electricCyan
                                  : AppColors.electricBlue,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Sign In Button
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.limeGreen,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          onPressed: (_isLoading || _isNavigating)
                              ? null
                              : _handleSignIn,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.black,
                                  ),
                                )
                              : const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: isDark ? Colors.white12 : Colors.black12,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.darkTextTertiary
                                    : AppColors.lightTextTertiary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: isDark ? Colors.white12 : Colors.black12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Google Sign In Button
                      const GoogleSignInButton(label: 'Sign In with Google'),
                      const SizedBox(height: 16),

                      // Sign Up Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/auth/sign-up'),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.limeGreen,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Continue as Guest
                      Center(
                        child: TextButton(
                          onPressed: () {
                            ref.read(authProvider.notifier).setManualGuest();
                            context.go('/home');
                          },
                          child: Text(
                            'Continue in Guest Mode (Local Storage)',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_isNavigating)
              Positioned.fill(
                child: Container(
                  color:
                      (isDark
                              ? AppColors.darkBackground
                              : AppColors.lightBackground)
                          .withValues(alpha: 0.94),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.limeGreen.withValues(
                                  alpha: 0.15,
                                ),
                                border: Border.all(
                                  color: AppColors.limeGreen,
                                  width: 2.5,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.fitness_center_rounded,
                                  color: AppColors.limeGreen,
                                  size: 36,
                                ),
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(
                              begin: const Offset(0.95, 0.95),
                              end: const Offset(1.08, 1.08),
                              duration: 700.ms,
                              curve: Curves.easeInOut,
                            ),
                        const SizedBox(height: 24),
                        const Text(
                          'Welcome to Fit Host',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ).animate().fadeIn(duration: 300.ms),
                        const SizedBox(height: 8),
                        Text(
                          'Preparing your personalized dashboard...',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ).animate().fadeIn(duration: 400.ms),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 200.ms),
              ),
          ],
        ),
      ),
    );
  }
}
