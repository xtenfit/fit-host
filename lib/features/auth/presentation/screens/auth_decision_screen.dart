import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:fit_host/core/theme/app_colors.dart';
import 'package:fit_host/core/services/supabase_service.dart';
import '../helpers/auth_navigation_helper.dart';
import '../widgets/google_sign_in_button.dart';

class AuthDecisionScreen extends ConsumerStatefulWidget {
  const AuthDecisionScreen({super.key});

  @override
  ConsumerState<AuthDecisionScreen> createState() => _AuthDecisionScreenState();
}

class _AuthDecisionScreenState extends ConsumerState<AuthDecisionScreen> {
  bool _isNavigating = false;

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
        setState(() => _isNavigating = true);
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
      setState(() => _isNavigating = true);
      AuthNavigationHelper.checkAccountSetupAndNavigate(
        context,
        ref,
        auth.user!.id,
      );
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
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                24,
                20,
                24,
                32 + MediaQuery.viewPaddingOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 32),

                  // Logo & Illustration
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.limeGreen.withValues(alpha: 0.15),
                      border: Border.all(color: AppColors.limeGreen, width: 2),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.bolt_rounded,
                        size: 48,
                        color: AppColors.limeGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Unlock Fit Host Experience',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Save your personalized fitness plans, track your progress automatically, and keep your health records securely backed up.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Feature badges
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkSurfaceBorder
                            : AppColors.lightSurfaceBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildFeatureRow(
                          Icons.cloud_sync_rounded,
                          'Instant Cloud Backup',
                          'Sync seamlessly across all your phones and tablets',
                          AppColors.electricCyan,
                        ),
                        const Divider(height: 20),
                        _buildFeatureRow(
                          Icons.insights_rounded,
                          'Advanced Analytics',
                          'Detailed macro trends, MET calorie computation & recovery stats',
                          AppColors.limeGreen,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Action 1: Continue with Google
                  const GoogleSignInButton(label: 'Continue with Google'),
                  const SizedBox(height: 14),

                  // OR Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: isDark
                              ? AppColors.darkSurfaceBorder
                              : AppColors.lightSurfaceBorder,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
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
                          color: isDark
                              ? AppColors.darkSurfaceBorder
                              : AppColors.lightSurfaceBorder,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Action 2: Create Account (Primary)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.limeGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => context.go('/auth/sign-up'),
                      child: const Text(
                        'Create Account with Email',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Action 3: Sign In (Secondary)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.white : Colors.black87,
                        side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.black26,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => context.go('/auth/sign-in'),
                      child: const Text(
                        'Sign In to Existing Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 15,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Account required to ensure encrypted backup & sync',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
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
                                  Icons.bolt_rounded,
                                  color: AppColors.limeGreen,
                                  size: 38,
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

  Widget _buildFeatureRow(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.darkTextTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
