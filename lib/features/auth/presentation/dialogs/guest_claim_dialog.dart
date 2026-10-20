import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/data/guest_account_claim_service.dart';

typedef AutoGuestMigrationDialog = GuestClaimDialog;

class GuestClaimDialog extends ConsumerStatefulWidget {
  final String newUserId;
  final GuestRecordBreakdown breakdown;

  const GuestClaimDialog({
    super.key,
    required this.newUserId,
    required this.breakdown,
  });

  static Future<bool> checkAndShow(
    BuildContext context,
    WidgetRef ref,
    String newUserId,
  ) async {
    final claimService = ref.read(guestAccountClaimServiceProvider);
    final breakdown = await claimService.getGuestRecordBreakdown();

    if (!breakdown.hasRecords) return true;

    if (context.mounted) {
      final res = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => GuestClaimDialog(
          newUserId: newUserId,
          breakdown: breakdown,
        ),
      );
      return res ?? false;
    }
    return false;
  }

  @override
  ConsumerState<GuestClaimDialog> createState() => _GuestClaimDialogState();
}

class _GuestClaimDialogState extends ConsumerState<GuestClaimDialog> {
  MigrationStage _currentStage = MigrationStage.preparing;
  double _progress = 0.15;
  String _statusMessage = 'Preparing your saved data.';
  String? _errorMessage;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startMigration();
    });
  }

  Future<void> _startMigration() async {
    setState(() {
      _errorMessage = null;
      _currentStage = MigrationStage.preparing;
      _progress = 0.15;
      _statusMessage = 'Preparing your saved data.';
    });

    try {
      final claimService = ref.read(guestAccountClaimServiceProvider);
      final outcome = await claimService.claimGuestDataToAccount(
        widget.newUserId,
        onProgress: (prog) {
          if (mounted) {
            setState(() {
              _currentStage = prog.stage;
              _progress = prog.progress;
              _statusMessage = prog.message;
              _errorMessage = prog.error;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isFinished = true;
          _progress = 1.0;
          _currentStage = MigrationStage.ready;
          _statusMessage = 'Your account is ready.';
        });

        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                outcome == ClaimOutcome.success
                    ? '✅ Successfully backed up ${widget.breakdown.totalRecords} records to your account!'
                    : '⏳ Account created! Records will finish synchronizing in the background.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentStage = MigrationStage.failed;
          _errorMessage = e.toString();
          _statusMessage =
              'Migration interrupted. Local records are preserved safely on your device.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: _isFinished || _currentStage == MigrationStage.failed,
      child: AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isFinished
                    ? AppColors.limeGreen.withValues(alpha: 0.18)
                    : (_currentStage == MigrationStage.failed
                        ? AppColors.error.withValues(alpha: 0.18)
                        : AppColors.electricCyan.withValues(alpha: 0.18)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isFinished
                    ? Icons.check_circle_rounded
                    : (_currentStage == MigrationStage.failed
                        ? Icons.warning_amber_rounded
                        : Icons.cloud_sync_rounded),
                color: _isFinished
                    ? AppColors.limeGreen
                    : (_currentStage == MigrationStage.failed
                        ? AppColors.error
                        : AppColors.electricCyan),
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isFinished
                        ? 'Account Ready'
                        : (_currentStage == MigrationStage.failed
                            ? 'Sync Interrupted'
                            : 'Backing Up Data'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    '${widget.breakdown.totalRecords} local records detected',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Animated Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(begin: 0.0, end: _progress),
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: isDark
                          ? AppColors.darkSurfaceElevated
                          : Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _isFinished
                            ? AppColors.limeGreen
                            : (_currentStage == MigrationStage.failed
                                ? AppColors.error
                                : AppColors.electricCyan),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Status message with stage explanation
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceElevated
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkSurfaceBorder
                        : AppColors.lightSurfaceBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _currentStage == MigrationStage.failed
                            ? AppColors.error
                            : (_isFinished
                                ? AppColors.limeGreen
                                : (isDark
                                    ? Colors.white
                                    : Colors.grey.shade900)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Progress stages list
                    _buildStageStep(
                      title: 'Preparing your saved data.',
                      stage: MigrationStage.preparing,
                      isDark: isDark,
                    ),
                    _buildStageStep(
                      title: 'Backing up your workouts and activity logs.',
                      stage: MigrationStage.backingUp,
                      isDark: isDark,
                    ),
                    _buildStageStep(
                      title: 'Synchronizing your records.',
                      stage: MigrationStage.synchronizing,
                      isDark: isDark,
                    ),
                    _buildStageStep(
                      title: 'Your account is ready.',
                      stage: MigrationStage.ready,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Note: Your guest data is safe in local storage. You can retry now or proceed with local caching.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (_currentStage == MigrationStage.failed) ...[
            TextButton(
              onPressed: () {
                // Let user continue; data is saved in local Drift
                Navigator.of(context).pop(false);
              },
              child: Text(
                'Continue Locally',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.limeGreen,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _startMigration,
              child: const Text(
                'Retry Backup',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ] else if (_isFinished) ...[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.limeGreen,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Get Started',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStageStep({
    required String title,
    required MigrationStage stage,
    required bool isDark,
  }) {
    final bool isCompleted = _stageIndex(_currentStage) > _stageIndex(stage) ||
        _currentStage == MigrationStage.ready;
    final bool isCurrent = _currentStage == stage;

    Color iconColor;
    IconData icon;
    if (isCompleted) {
      iconColor = AppColors.limeGreen;
      icon = Icons.check_circle_rounded;
    } else if (isCurrent) {
      iconColor = AppColors.electricCyan;
      icon = Icons.radio_button_checked;
    } else {
      iconColor = isDark ? Colors.grey.shade700 : Colors.grey.shade400;
      icon = Icons.radio_button_unchecked;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                color: isCurrent
                    ? (isDark ? Colors.white : Colors.black87)
                    : (isCompleted
                        ? (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary)
                        : (isDark ? Colors.grey.shade600 : Colors.grey.shade500)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _stageIndex(MigrationStage stage) {
    switch (stage) {
      case MigrationStage.idle:
        return 0;
      case MigrationStage.preparing:
        return 1;
      case MigrationStage.backingUp:
        return 2;
      case MigrationStage.synchronizing:
        return 3;
      case MigrationStage.ready:
        return 4;
      case MigrationStage.failed:
        return -1;
    }
  }
}

