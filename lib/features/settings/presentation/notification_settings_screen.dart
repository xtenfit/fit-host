import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/notification_service.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _masterNotifications = true;
  bool _workoutsEnabled = true;
  bool _mealsEnabled = true;
  bool _hydrationEnabled = true;
  bool _recoveryEnabled = true;
  bool _habitsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  int _defaultSnooze = 10;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notifService = ref.read(notificationServiceProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Notification Settings',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Master Switch Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.electricBlue.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.electricBlue.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: AppColors.electricBlue,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Allow All Notifications',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Receive offline reminders for workouts & nutrition',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _masterNotifications,
                    activeTrackColor: AppColors.electricBlue,
                    onChanged: (val) {
                      setState(() => _masterNotifications = val);
                      notifService.setPermissionsAllowed(val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Notification Channels Group
            const Text(
              'Notification Categories',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                ),
              ),
              child: Column(
                children: [
                  _buildToggleRow(
                    title: 'Workouts & Training',
                    subtitle: 'Scheduled workouts, routine alerts & warmup reminders',
                    icon: Icons.fitness_center_rounded,
                    color: AppColors.electricBlue,
                    value: _workoutsEnabled && _masterNotifications,
                    onChanged: _masterNotifications
                        ? (v) => setState(() => _workoutsEnabled = v)
                        : null,
                  ),
                  const Divider(height: 1),
                  _buildToggleRow(
                    title: 'Meals & Nutrition Alarms',
                    subtitle: 'Breakfast, lunch, post-workout protein & dinner timing',
                    icon: Icons.restaurant_rounded,
                    color: const Color(0xFFFF6B4A),
                    value: _mealsEnabled && _masterNotifications,
                    onChanged: _masterNotifications
                        ? (v) => setState(() => _mealsEnabled = v)
                        : null,
                  ),
                  const Divider(height: 1),
                  _buildToggleRow(
                    title: 'Hydration & Water Check-ins',
                    subtitle: 'Regular intervals to hit 3.5L fluid target',
                    icon: Icons.water_drop_rounded,
                    color: const Color(0xFF00B4D8),
                    value: _hydrationEnabled && _masterNotifications,
                    onChanged: _masterNotifications
                        ? (v) => setState(() => _hydrationEnabled = v)
                        : null,
                  ),
                  const Divider(height: 1),
                  _buildToggleRow(
                    title: 'Sleep & Recovery Wind-down',
                    subtitle: 'Nightly screen cutoff and mobility check-ins',
                    icon: Icons.bedtime_rounded,
                    color: const Color(0xFF9D4EDD),
                    value: _recoveryEnabled && _masterNotifications,
                    onChanged: _masterNotifications
                        ? (v) => setState(() => _recoveryEnabled = v)
                        : null,
                  ),
                  const Divider(height: 1),
                  _buildToggleRow(
                    title: 'Daily Habits & Streaks',
                    subtitle: 'Reminders to maintain your workout streak',
                    icon: Icons.local_fire_department_rounded,
                    color: const Color(0xFFFF9E00),
                    value: _habitsEnabled && _masterNotifications,
                    onChanged: _masterNotifications
                        ? (v) => setState(() => _habitsEnabled = v)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Sound, Vibration & Snooze Group
            const Text(
              'Alert Style & Snooze',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                ),
              ),
              child: Column(
                children: [
                  _buildToggleRow(
                    title: 'Sound Notification',
                    subtitle: 'Play gentle chime on alert',
                    icon: Icons.volume_up_rounded,
                    color: Colors.teal,
                    value: _soundEnabled && _masterNotifications,
                    onChanged: _masterNotifications
                        ? (v) => setState(() => _soundEnabled = v)
                        : null,
                  ),
                  const Divider(height: 1),
                  _buildToggleRow(
                    title: 'Haptic Vibration',
                    subtitle: 'Vibrate device on reminder firing',
                    icon: Icons.vibration_rounded,
                    color: Colors.amber,
                    value: _vibrationEnabled && _masterNotifications,
                    onChanged: _masterNotifications
                        ? (v) => setState(() => _vibrationEnabled = v)
                        : null,
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.snooze_rounded, color: Colors.blueGrey, size: 22),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Default Snooze Duration',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('Used for quick snooze buttons',
                                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                        DropdownButton<int>(
                          value: _defaultSnooze,
                          underline: const SizedBox.shrink(),
                          items: [5, 10, 15, 30, 60].map((mins) {
                            return DropdownMenuItem(
                              value: mins,
                              child: Text('$mins min'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _defaultSnooze = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Test Notification Button
            OutlinedButton.icon(
              onPressed: () async {
                await notifService.scheduleNotification(
                  id: 'test_notification',
                  title: '🔔 Fit Host Test Notification',
                  body: 'All reminders and alarm channels are working offline!',
                  scheduledTime: DateTime.now().add(const Duration(seconds: 1)),
                  channel: NotificationChannelType.workouts,
                  sound: _soundEnabled,
                  vibration: _vibrationEnabled,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🔔 Test notification fired successfully!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Send Test Notification'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.electricBlue,
                side: const BorderSide(color: AppColors.electricBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool value,
    required Function(bool)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppColors.electricBlue,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
