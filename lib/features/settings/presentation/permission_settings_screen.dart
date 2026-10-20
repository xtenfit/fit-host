import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionSettingsScreen extends ConsumerStatefulWidget {
  const PermissionSettingsScreen({super.key});

  @override
  ConsumerState<PermissionSettingsScreen> createState() =>
      _PermissionSettingsScreenState();
}

class _PermissionSettingsScreenState extends ConsumerState<PermissionSettingsScreen>
    with WidgetsBindingObserver {
  FitHostPermissionReport? _report;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadReport();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadReport();
    }
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    final report = await PermissionService.instance.checkPermissionReport();
    if (mounted) {
      setState(() {
        _report = report;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestNotification() async {
    await PermissionService.instance.requestReminderPermissions(context);
    await _loadReport();
  }

  Future<void> _requestBattery() async {
    await PermissionService.instance.showBatteryOptimizationDialog(context);
    await _loadReport();
  }

  Future<void> _requestOverlay() async {
    if (!kIsWeb && Platform.isAndroid) {
      await Permission.systemAlertWindow.request();
    }
    await _loadReport();
  }

  Future<void> _openSettings() async {
    await PermissionService.instance.openDeviceAppSettings();
  }

  Future<void> _testImmediateAlarm() async {
    final now = DateTime.now().add(const Duration(seconds: 5));
    await NotificationService.instance.scheduleAlarm(
      id: 'permission_test_alarm_${DateTime.now().millisecondsSinceEpoch}',
      title: '🚨 Fit Host Lockscreen & Popup Test',
      body: 'Your alarm and popup screen permissions are functioning perfectly!',
      scheduledTime: now,
      channel: NotificationChannelType.workouts,
      payload:
          '/alarm?id=test_preview&title=${Uri.encodeComponent('Fit Host Popup Test')}&body=${Uri.encodeComponent('Workout reminder alarm test ring')}&channel=workouts&snoozeMinutes=5',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '🔔 Test alarm scheduled in 5 seconds! Lock your phone or go to home screen now.',
          ),
          backgroundColor: AppColors.limeGreen,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'App Permissions & Reliability',
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
            onPressed: _loadReport,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.limeGreen))
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Status Header Card
                  Container(
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
                        color: (_report?.allEssentialGranted ?? false)
                            ? AppColors.limeGreen.withValues(alpha: 0.5)
                            : Colors.amber.withValues(alpha: 0.5),
                        width: 1.5,
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
                                color: (_report?.allEssentialGranted ?? false)
                                    ? AppColors.limeGreen.withValues(alpha: 0.2)
                                    : Colors.amber.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                (_report?.allEssentialGranted ?? false)
                                    ? Icons.verified_user_rounded
                                    : Icons.warning_amber_rounded,
                                color: (_report?.allEssentialGranted ?? false)
                                    ? AppColors.limeGreen
                                    : Colors.amber,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (_report?.allEssentialGranted ?? false)
                                        ? 'Alarms Fully Armed & Reliable'
                                        : 'Action Required for Background Rings',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    (_report?.allEssentialGranted ?? false)
                                        ? 'All lockscreen alarms and offline reminders will ring on time.'
                                        : 'Enable exact alarms and battery exemption so phone lock does not kill alerts.',
                                    style: TextStyle(
                                      fontSize: 11,
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
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _openSettings,
                            icon: const Icon(Icons.settings_rounded, size: 16),
                            label: const Text('Open Device App Settings'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.electricBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'System Permission Controls',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),

                  // 1. Notifications Permission
                  _buildPermissionCard(
                    title: 'Notifications & Alerts',
                    description:
                        'Allows Fit Host to deliver timely alarms for workouts, meals, and hydration.',
                    icon: Icons.notifications_active_rounded,
                    color: AppColors.electricBlue,
                    isGranted: _report?.notificationGranted ?? false,
                    onFix: _requestNotification,
                    fixLabel: 'Allow Notifications',
                  ),
                  const SizedBox(height: 10),

                  // 2. Schedule Exact Alarms (Android 12+)
                  if (!kIsWeb && Platform.isAndroid) ...[
                    _buildPermissionCard(
                      title: 'Schedule Exact Alarms',
                      description:
                          'Required by Android 12+ so alarms ring at the precise minute without Doze delays.',
                      icon: Icons.alarm_on_rounded,
                      color: AppColors.limeGreen,
                      isGranted: _report?.exactAlarmGranted ?? false,
                      onFix: _openSettings,
                      fixLabel: 'Allow Exact Alarms',
                    ),
                    const SizedBox(height: 10),

                    // 3. Battery Optimization Exemption
                    _buildPermissionCard(
                      title: 'Background Battery Exemption',
                      description:
                          'Prevents Android power saving from freezing Fit Host while phone is locked or screen is off.',
                      icon: Icons.battery_charging_full_rounded,
                      color: Colors.amber,
                      isGranted: _report?.batteryOptimizationExempt ?? false,
                      onFix: _requestBattery,
                      fixLabel: 'Disable Battery Optimization',
                    ),
                    const SizedBox(height: 10),

                    // 4. Draw Over Other Apps / Popups
                    _buildPermissionCard(
                      title: 'Display Over Other Apps / Lockscreen',
                      description:
                          'Enables the full-screen alarm popup screen to show over the lock screen and other open apps.',
                      icon: Icons.picture_in_picture_alt_rounded,
                      color: const Color(0xFF9D4EDD),
                      isGranted: _report?.systemAlertWindowGranted ?? false,
                      onFix: _requestOverlay,
                      fixLabel: 'Allow Overlays & Popups',
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Diagnostics & Testing Section
                  const Text(
                    'Alarm Diagnostics',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),

                  Container(
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
                        const Text(
                          'Test 5-Second Popup & Ringing Alarm',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Press this button, then immediately lock your phone or switch to another app. Verify that the alarm rings and shows the popup screen.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _testImmediateAlarm,
                            icon: const Icon(Icons.timer_rounded, size: 16),
                            label: const Text('Fire 5-Second Test Alarm'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.limeGreen,
                              side: const BorderSide(color: AppColors.limeGreen),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isGranted,
    required VoidCallback onFix,
    required String fixLabel,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onFix,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isGranted
                  ? (isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder)
                  : Colors.amber.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isGranted ? 'Allowed / Optimized' : 'Action Required (Tap to Grant)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isGranted ? AppColors.limeGreen : Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isGranted ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                    color: isGranted ? AppColors.limeGreen : Colors.amber,
                    size: 22,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  height: 1.4,
                ),
              ),
              if (!isGranted) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onFix,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                    label: Text(fixLabel),
                    style: TextButton.styleFrom(
                      foregroundColor: color,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
