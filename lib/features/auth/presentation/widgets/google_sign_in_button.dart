import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/supabase_service.dart';
import '../helpers/auth_navigation_helper.dart';

class GoogleSignInButton extends ConsumerStatefulWidget {
  final String label;
  final VoidCallback? onSuccess;
  final ValueChanged<String>? onError;
  final bool isSecondary;

  const GoogleSignInButton({
    super.key,
    this.label = 'Continue with Google',
    this.onSuccess,
    this.onError,
    this.isSecondary = false,
  });

  @override
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  bool _isLoading = false;
  bool _isSuccess = false;

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading || _isSuccess) return;
    setState(() {
      _isLoading = true;
      _isSuccess = false;
    });

    try {
      final authNotifier = ref.read(authProvider.notifier);
      final ok = await authNotifier.signInWithGoogle();

      if (!mounted) return;

      if (ok) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });

        final user = ref.read(authProvider).user;
        if (user != null) {
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          } else {
            await AuthNavigationHelper.checkAccountSetupAndNavigate(
              context,
              ref,
              user.id,
            );
          }
        }
      } else {
        setState(() => _isLoading = false);
        final err = ref.read(authProvider).errorMessage;
        if (err != null && err.isNotEmpty) {
          if (widget.onError != null) {
            widget.onError!(err);
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(err),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final msg = formatAuthError(e);
      if (widget.onError != null) {
        widget.onError!(msg);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.isAuthenticated && next.user != null && mounted && !_isSuccess) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else {
          AuthNavigationHelper.checkAccountSetupAndNavigate(
            context,
            ref,
            next.user!.id,
          );
        }
      }
    });

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: (_isLoading || _isSuccess) ? null : _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? Colors.white : Colors.black87,
          backgroundColor: _isSuccess
              ? AppColors.limeGreen.withValues(alpha: 0.15)
              : (isDark ? AppColors.darkSurfaceElevated : Colors.white),
          side: BorderSide(
            color: _isSuccess
                ? AppColors.limeGreen
                : (isDark
                      ? AppColors.darkSurfaceBorder
                      : AppColors.lightSurfaceBorder),
            width: _isSuccess ? 2.0 : 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _isSuccess
              ? Row(
                  key: const ValueKey('success'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.limeGreen,
                      size: 20,
                    ).animate().scale(
                      duration: 300.ms,
                      curve: Curves.easeOutBack,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Entering Fit Host...',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.limeGreen,
                        letterSpacing: -0.2,
                      ),
                    ).animate().fadeIn(duration: 250.ms),
                  ],
                )
              : _isLoading
              ? Row(
                  key: const ValueKey('loading'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.limeGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Connecting Account...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                )
              : Row(
                  key: const ValueKey('idle'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildGoogleIcon(),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            fontFamily: 'Roboto',
            color: Colors.blue.shade700,
          ),
        ),
      ),
    );
  }
}
