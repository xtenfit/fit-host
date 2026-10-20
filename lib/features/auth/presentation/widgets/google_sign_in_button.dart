import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/supabase_service.dart';
import '../dialogs/guest_claim_dialog.dart';

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

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final authNotifier = ref.read(authProvider.notifier);
      final ok = await authNotifier.signInWithGoogle();

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (ok) {
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else {
          final user = ref.read(authProvider).user;
          final newUserId = user?.id ?? 'google_${DateTime.now().millisecondsSinceEpoch}';
          await GuestClaimDialog.checkAndShow(context, ref, newUserId);
          if (mounted) {
            context.go('/home');
          }
        }
      } else {
        final err = ref.read(authProvider).errorMessage ?? 'Google Sign-In was cancelled or failed.';
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final msg = e.toString().replaceFirst('Exception:', '').trim();
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? Colors.white : Colors.black87,
          backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
          side: BorderSide(
            color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.limeGreen,
                ),
              )
            : Row(
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
