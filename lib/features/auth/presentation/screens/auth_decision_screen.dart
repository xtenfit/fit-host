import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_host/core/theme/app_colors.dart';
import 'package:fit_host/core/services/startup_gate_service.dart';
import '../widgets/google_sign_in_button.dart';

class AuthDecisionScreen extends ConsumerStatefulWidget {
  const AuthDecisionScreen({super.key});

  @override
  ConsumerState<AuthDecisionScreen> createState() => _AuthDecisionScreenState();
}

class _AuthDecisionScreenState extends ConsumerState<AuthDecisionScreen> {
  Future<void> _handleContinueAsGuest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).brightness == Brightness.dark
            ? AppColors.darkSurface
            : Colors.white,
        title: const Text(
          'Continue as Guest?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Your workouts and nutrition data will be saved locally on this device. You can link or create a cloud account anytime in Profile to sync across devices.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.limeGreen,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Continue as Guest',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(startupGateServiceProvider).setAuthDecisionMade(true);
      if (mounted) {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const Spacer(),

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
              const SizedBox(height: 28),

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
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // Feature badges
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
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

              const Spacer(),

              // Action 1: Continue with Google
              const GoogleSignInButton(label: 'Continue with Google'),
              const SizedBox(height: 14),

              // OR Divider
              Row(
                children: [
                  Expanded(child: Divider(color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => context.push('/auth/sign-up'),
                  child: const Text(
                    'Create Account with Email',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => context.push('/auth/sign-in'),
                  child: const Text(
                    'Sign In to Existing Account',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Action 3: Continue as Guest (Text Link)
              TextButton(
                onPressed: _handleContinueAsGuest,
                child: Text(
                  'Continue as Guest',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle, Color color) {
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
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.darkTextTertiary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
