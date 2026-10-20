import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/data/guest_account_claim_service.dart';

class SupabaseAuthDialog extends ConsumerStatefulWidget {
  const SupabaseAuthDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SupabaseAuthDialog(),
    );
  }

  @override
  ConsumerState<SupabaseAuthDialog> createState() => _SupabaseAuthDialogState();
}

class _SupabaseAuthDialogState extends ConsumerState<SupabaseAuthDialog> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _promptGuestDataClaim(String newUid) async {
    final shouldUpload = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Upload Local Data?'),
        content: const Text(
          'Upload your local data to your new account so you never lose your progress across devices?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Start Fresh'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.limeGreen,
              foregroundColor: Colors.black,
            ),
            child: const Text('Upload & Sync'),
          ),
        ],
      ),
    );

    if (shouldUpload == true) {
      await ref.read(guestAccountClaimServiceProvider).claimGuestDataToAccount(newUid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authState.otpSent ? 'Enter Email Code' : 'Sign In & Sync',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authState.otpSent
                          ? 'We sent a 6-digit OTP code to ${authState.email}'
                          : 'Backup workouts & sync across all your devices',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {
                    authNotifier.resetOtpState();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Error display if any
            if (authState.errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        authState.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            if (!authState.otpSent) ...[
              // Option 1: Continue with Google Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: authState.isLoading
                      ? null
                      : () async {
                          final ok = await authNotifier.signInWithGoogle();
                          if (ok && context.mounted) {
                            final uid = ref.read(authProvider).user?.id ?? 'account_${DateTime.now().millisecondsSinceEpoch}';
                            Navigator.of(context).pop();
                            await _promptGuestDataClaim(uid);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🎉 Signed in with Google! Cloud Sync active.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : Colors.black87,
                    side: BorderSide(
                      color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Google Logo G
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: Center(
                          child: Text(
                            'G',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isDark ? AppColors.limeGreen : Colors.blueAccent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Flexible(
                        child: Text(
                          'Continue with Google',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // OR Divider
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'OR EMAIL OTP',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Email input
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'athlete@example.com',
                  prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Send OTP Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: authState.isLoading
                      ? null
                      : () async {
                          await authNotifier.sendEmailOtp(_emailController.text);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.limeGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: authState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    authState.isLoading ? 'Sending code...' : 'Send Login OTP Code',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ),
            ] else ...[
              // Step 2: OTP Verification
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                ),
                decoration: InputDecoration(
                  labelText: '6-Digit OTP Code',
                  hintText: '123456',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: authState.isLoading
                      ? null
                      : () async {
                          final ok = await authNotifier.verifyOtp(_otpController.text);
                          if (ok && context.mounted) {
                            final uid = ref.read(authProvider).user?.id ?? 'account_${DateTime.now().millisecondsSinceEpoch}';
                            Navigator.of(context).pop();
                            await _promptGuestDataClaim(uid);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('🎉 Verified! Welcome ${authState.email}'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.limeGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: authState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(
                    authState.isLoading ? 'Verifying...' : 'Verify OTP & Sign In',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Resend / Change Email
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => authNotifier.resetOtpState(),
                    child: const Text('Change Email'),
                  ),
                  TextButton(
                    onPressed: () => authNotifier.sendEmailOtp(_emailController.text),
                    child: const Text('Resend Code'),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),
            // Cloud Sync Guarantee Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B231D) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.limeGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_done_rounded, color: AppColors.limeGreen, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cloud Sync: Backup and restore your workouts, nutrition logs, and target stats across devices securely anytime.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
