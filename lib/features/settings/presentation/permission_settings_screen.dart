import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/permission_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Comprehensive permission configuration and management screen.
/// Supports both:
/// 1. Post-Onboarding Mode (`isPostOnboarding = true`): "Set Up Your Experience" walkthrough.
/// 2. Settings Mode (`isPostOnboarding = false`): Ongoing permission audit and management.
class PermissionSettingsScreen extends ConsumerStatefulWidget {
  final bool isPostOnboarding;

  const PermissionSettingsScreen({super.key, this.isPostOnboarding = false});

  @override
  ConsumerState<PermissionSettingsScreen> createState() =>
      _PermissionSettingsScreenState();
}

class _PermissionSettingsScreenState
    extends ConsumerState<PermissionSettingsScreen>
    with WidgetsBindingObserver {
  AppPermissionState _state = AppPermissionState.initial();
  bool _isLoading = true;
  String? _actionInProgress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadState();
    }
  }

  Future<void> _loadState() async {
    setState(() => _isLoading = true);
    final service = ref.read(permissionServiceProvider);
    final state = await service.checkAllPermissions();
    if (mounted) {
      setState(() {
        _state = state;
        _isLoading = false;
      });
    }
  }

  Future<void> _completeAndNavigateHome() async {
    final service = ref.read(permissionServiceProvider);
    await service.setPermissionSetupCompleted(true);
    if (mounted) {
      try {
        context.go('/home');
      } catch (_) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Action Handlers
  // ---------------------------------------------------------------------------

  Future<void> _handleNotificationAction() async {
    final service = ref.read(permissionServiceProvider);
    if (_state.notifications.isGranted) {
      // Test notification delivery
      setState(() => _actionInProgress = 'notifications');
      final success = await service.sendTestNotification();
      if (mounted) {
        setState(() => _actionInProgress = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? '🔔 Test notification sent! Check your status bar.'
                  : 'Unable to deliver test notification.',
            ),
            backgroundColor: success ? AppColors.limeGreen : Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (_state.notifications == AppPermissionStatus.permanentlyDenied) {
      await service.openDeviceAppSettings();
      return;
    }

    setState(() => _actionInProgress = 'notifications');
    await service.requestNotificationPermission();
    if (mounted) {
      await _loadState();
      setState(() => _actionInProgress = null);
    }
  }

  Future<void> _handleExactAlarmAction() async {
    final service = ref.read(permissionServiceProvider);
    if (_state.exactAlarms.isGranted) return;

    await service.openExactAlarmSettings();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enable "Alarms & Reminders" for Fit Host in system settings, then return to the app.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleHealthConnectAction() async {
    final service = ref.read(permissionServiceProvider);
    if (_state.healthConnect == AppPermissionStatus.unavailable) {
      if (mounted) {
        context.push('/settings/health-connect');
      }
      return;
    }

    if (_state.healthConnect.isGranted) {
      if (mounted) {
        context.push('/settings/health-connect');
      }
      return;
    }

    setState(() => _actionInProgress = 'health');
    await service.requestHealthConnectPermission();
    if (mounted) {
      await _loadState();
      setState(() => _actionInProgress = null);
    }
  }

  Future<void> _handlePhysicalActivityAction() async {
    final service = ref.read(permissionServiceProvider);
    if (_state.physicalActivity == AppPermissionStatus.permanentlyDenied) {
      await service.openDeviceAppSettings();
      return;
    }

    setState(() => _actionInProgress = 'activity');
    await service.requestPhysicalActivityPermission();
    if (mounted) {
      await _loadState();
      setState(() => _actionInProgress = null);
    }
  }

  Future<void> _handleCameraAction() async {
    final service = ref.read(permissionServiceProvider);
    if (_state.camera == AppPermissionStatus.permanentlyDenied) {
      await service.openDeviceAppSettings();
      return;
    }

    setState(() => _actionInProgress = 'camera');
    await service.requestCameraPermission();
    if (mounted) {
      await _loadState();
      setState(() => _actionInProgress = null);
    }
  }

  // ---------------------------------------------------------------------------
  // Build Methods
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: widget.isPostOnboarding
          ? _buildPostOnboardingAppBar(isDark)
          : _buildSettingsAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.limeGreen),
            )
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      children: [
                        if (widget.isPostOnboarding) ...[
                          _buildPostOnboardingHeader(isDark),
                          const SizedBox(height: 20),
                        ] else ...[
                          _buildSettingsOverviewCard(isDark),
                          const SizedBox(height: 20),
                        ],

                        // Core Recommended Setup Cards
                        _buildSectionHeader('RECOMMENDED CAPABILITIES'),
                        const SizedBox(height: 10),

                        // Card A: Notifications
                        _buildPermissionCard(
                          icon: Icons.notifications_active_rounded,
                          iconColor: AppColors.limeGreen,
                          title: 'Notifications & Reminders',
                          purpose:
                              'Receive timely alerts for workouts, meals, hydration, and recovery so you never fall behind.',
                          status: _state.notifications,
                          isActionLoading: _actionInProgress == 'notifications',
                          actionLabel: _state.notifications.isGranted
                              ? 'Test Alert'
                              : (_state.notifications ==
                                        AppPermissionStatus.permanentlyDenied
                                    ? 'Open Settings'
                                    : 'Enable Notifications'),
                          onAction: _handleNotificationAction,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),

                        // Card B: Alarm-Style Reminders
                        _buildPermissionCard(
                          icon: Icons.alarm_on_rounded,
                          iconColor: Colors.amber,
                          title: 'Alarm-Style Precision',
                          purpose:
                              'Rings scheduled workouts on the exact minute, bypassing battery optimization and deep Doze mode.',
                          status: _state.exactAlarms,
                          isActionLoading: _actionInProgress == 'alarms',
                          actionLabel: _state.exactAlarms.isGranted
                              ? 'Enabled'
                              : 'Configure Alarm Access',
                          onAction: _state.exactAlarms.isGranted
                              ? null
                              : _handleExactAlarmAction,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),

                        // Card C: Health Connect
                        _buildPermissionCard(
                          icon: Icons.favorite_rounded,
                          iconColor: AppColors.electricBlue,
                          title: 'Health Connect Sync',
                          purpose:
                              'Securely import your daily steps and exercise data from Google Health Connect with zero duplicate counts.',
                          status: _state.healthConnect,
                          isActionLoading: _actionInProgress == 'health',
                          actionLabel: _state.healthConnect.isGranted
                              ? 'Manage Sync'
                              : (_state.healthConnect ==
                                        AppPermissionStatus.unavailable
                                    ? 'Install Health Connect'
                                    : 'Connect Health Connect'),
                          onAction: _handleHealthConnectAction,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),

                        // Card D: Physical Activity
                        _buildPermissionCard(
                          icon: Icons.directions_walk_rounded,
                          iconColor: AppColors.electricCyan,
                          title: 'Device Motion & Pedometer',
                          purpose:
                              'Counts your steps in real time via your phone\'s hardware sensor when Health Connect is not in use.',
                          status: _state.physicalActivity,
                          isActionLoading: _actionInProgress == 'activity',
                          actionLabel: _state.physicalActivity.isGranted
                              ? 'Sensor Active'
                              : (_state.physicalActivity ==
                                        AppPermissionStatus.permanentlyDenied
                                    ? 'Open Settings'
                                    : 'Allow Step Counting'),
                          onAction: _state.physicalActivity.isGranted
                              ? null
                              : _handlePhysicalActivityAction,
                          isDark: isDark,
                        ),

                        // Additional sections for Settings Mode
                        if (!widget.isPostOnboarding) ...[
                          const SizedBox(height: 24),
                          _buildSectionHeader('ON-DEMAND APP FEATURES'),
                          const SizedBox(height: 10),

                          // Camera Card (on-demand)
                          _buildPermissionCard(
                            icon: Icons.camera_alt_rounded,
                            iconColor: Colors.deepPurpleAccent,
                            title: 'Camera & Barcode Scanner',
                            purpose:
                                'Used only when you scan food barcodes or take meal and progress photos. Never accessed in the background.',
                            status: _state.camera,
                            isActionLoading: _actionInProgress == 'camera',
                            actionLabel: _state.camera.isGranted
                                ? 'Camera Allowed'
                                : (_state.camera ==
                                          AppPermissionStatus.permanentlyDenied
                                      ? 'Open Settings'
                                      : 'Allow Camera'),
                            onAction: _state.camera.isGranted
                                ? null
                                : _handleCameraAction,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),

                          // Google Calendar Integration
                          _buildGoogleCalendarCard(isDark),
                          const SizedBox(height: 24),

                          // Diagnostics & Troubleshooting Card
                          _buildTroubleshootingCard(isDark),
                          const SizedBox(height: 20),
                        ],

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // Bottom Action Buttons for Post-Onboarding
                  if (widget.isPostOnboarding)
                    _buildPostOnboardingBottomBar(isDark),
                ],
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sub-widgets
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildPostOnboardingAppBar(bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.limeGreen.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.limeGreen.withValues(alpha: 0.3)),
        ),
        child: const Text(
          'STEP 2 OF 2 • PERMISSIONS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.limeGreen,
            letterSpacing: 0.5,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _completeAndNavigateHome,
          child: Text(
            'Skip',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  PreferredSizeWidget _buildSettingsAppBar() {
    return AppBar(
      title: const Text(
        'Permissions & Integrations',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh Status',
          onPressed: _loadState,
        ),
      ],
    );
  }

  Widget _buildPostOnboardingHeader(bool isDark) {
    final granted = _state.recommendedGrantedCount;
    final total = _state.totalRecommendedCount;
    final progress = (granted / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set Up Your Experience',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Enable permissions to get the most out of Fit Host. All items are optional and can be modified anytime.',
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 16),

        // Progress bar card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? AppColors.darkSurfaceBorder
                  : AppColors.lightSurfaceBorder,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$granted of $total recommended features ready',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.limeGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: isDark
                      ? AppColors.darkSurfaceBorder
                      : Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.limeGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsOverviewCard(bool isDark) {
    final granted = _state.recommendedGrantedCount;
    final total = _state.totalRecommendedCount;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF13221C), const Color(0xFF0F172A)]
              : [const Color(0xFFE8F8F0), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: granted == total
              ? AppColors.limeGreen.withValues(alpha: 0.5)
              : Colors.amber.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (granted == total ? AppColors.limeGreen : Colors.amber)
                  .withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              granted == total
                  ? Icons.check_circle_rounded
                  : Icons.info_outline_rounded,
              color: granted == total ? AppColors.limeGreen : Colors.amber,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  granted == total
                      ? 'All Core Capabilities Active'
                      : '$granted of $total Capabilities Ready',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  granted == total
                      ? 'Fit Host has full access to deliver reminders, sync health records, and track steps.'
                      : 'Some features may be limited until corresponding permissions are enabled.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
        color: AppColors.darkTextTertiary,
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String purpose,
    required AppPermissionStatus status,
    required bool isActionLoading,
    required String actionLabel,
    required VoidCallback? onAction,
    required bool isDark,
  }) {
    final statusBadge = _buildStatusBadge(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? AppColors.darkSurfaceBorder
              : AppColors.lightSurfaceBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    statusBadge,
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            purpose,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isActionLoading ? null : onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: status.isGranted
                    ? (isDark
                          ? const Color(0xFF1B2E24)
                          : const Color(0xFFE8F8F0))
                    : AppColors.limeGreen,
                foregroundColor: status.isGranted
                    ? AppColors.limeGreen
                    : Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: status.isGranted
                      ? BorderSide(
                          color: AppColors.limeGreen.withValues(alpha: 0.3),
                        )
                      : BorderSide.none,
                ),
              ),
              child: isActionLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Text(
                      actionLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: status.isGranted
                            ? AppColors.limeGreen
                            : Colors.black,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AppPermissionStatus status) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status) {
      case AppPermissionStatus.granted:
        bg = AppColors.limeGreen.withValues(alpha: 0.15);
        fg = AppColors.limeGreen;
        label = 'Granted';
        icon = Icons.check_circle_rounded;
        break;
      case AppPermissionStatus.partiallyGranted:
        bg = Colors.amber.withValues(alpha: 0.15);
        fg = Colors.amber;
        label = 'Partially Granted';
        icon = Icons.hourglass_top_rounded;
        break;
      case AppPermissionStatus.notRequested:
        bg = Colors.blue.withValues(alpha: 0.15);
        fg = Colors.lightBlueAccent;
        label = 'Not Requested';
        icon = Icons.radio_button_unchecked_rounded;
        break;
      case AppPermissionStatus.denied:
        bg = Colors.amber.withValues(alpha: 0.15);
        fg = Colors.amber;
        label = 'Denied';
        icon = Icons.warning_amber_rounded;
        break;
      case AppPermissionStatus.permanentlyDenied:
        bg = Colors.redAccent.withValues(alpha: 0.15);
        fg = Colors.redAccent;
        label = 'Blocked in Android';
        icon = Icons.block_rounded;
        break;
      case AppPermissionStatus.requiresSystemSettings:
        bg = Colors.orangeAccent.withValues(alpha: 0.15);
        fg = Colors.orangeAccent;
        label = 'Requires System Settings';
        icon = Icons.settings_rounded;
        break;
      case AppPermissionStatus.unavailable:
        bg = Colors.grey.withValues(alpha: 0.15);
        fg = Colors.grey;
        label = 'Not Supported';
        icon = Icons.not_interested_rounded;
        break;
      case AppPermissionStatus.error:
        bg = Colors.red.withValues(alpha: 0.15);
        fg = Colors.redAccent;
        label = 'Check Failed';
        icon = Icons.error_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleCalendarCard(bool isDark) {
    final connected = _state.googleCalendarConnected;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? AppColors.darkSurfaceBorder
              : AppColors.lightSurfaceBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.blueAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Google Calendar (OAuth 2.0)',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: (connected ? AppColors.limeGreen : Colors.grey)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        connected ? 'Connected via OAuth' : 'Not Connected',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: connected ? AppColors.limeGreen : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Sync your planned workouts directly with Google Calendar via secure OAuth 2.0 without granting device calendar permissions.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push('/settings/calendar-sync'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(
                  color: isDark
                      ? AppColors.darkSurfaceBorder
                      : AppColors.lightSurfaceBorder,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                connected ? 'Manage Calendar Sync' : 'Connect Google Calendar',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? AppColors.darkSurfaceBorder
              : AppColors.lightSurfaceBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.build_rounded,
                size: 18,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              const SizedBox(width: 8),
              const Text(
                'Troubleshooting & Background Reliability',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'If reminders or step syncing do not trigger when Fit Host is closed:\n'
            '• Check that Battery Saver is not killing Fit Host in the background.\n'
            '• In Android Settings, ensure "Alarms & Reminders" is turned ON.\n'
            '• On OnePlus/OxygenOS/ColorOS, set Battery Usage to "Allow background activity".',
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => ref
                      .read(permissionServiceProvider)
                      .openDeviceAppSettings(),
                  icon: const Icon(Icons.settings_outlined, size: 16),
                  label: const Text('Android App Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.darkSurfaceElevated
                        : Colors.white,
                    foregroundColor: isDark ? Colors.white : Colors.black87,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isDark
                            ? AppColors.darkSurfaceBorder
                            : AppColors.lightSurfaceBorder,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () async {
                  await ref
                      .read(permissionServiceProvider)
                      .resetPermissionSetup();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Onboarding permission setup reset.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  side: BorderSide(
                    color: isDark
                        ? AppColors.darkSurfaceBorder
                        : AppColors.lightSurfaceBorder,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Reset Walkthrough',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostOnboardingBottomBar(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.darkSurfaceBorder
                : AppColors.lightSurfaceBorder,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _completeAndNavigateHome,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.limeGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue to Fit Host',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _completeAndNavigateHome,
            child: Text(
              'Skip for Now',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
