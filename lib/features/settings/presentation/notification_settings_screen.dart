import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/notification_service.dart';
import '../../reminders/data/alarm_sound_service.dart';
import '../../reminders/data/repositories/reminder_repository.dart';
import '../../reminders/domain/models/reminder.dart';

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
  ReminderDeliveryMode _defaultDeliveryMode = ReminderDeliveryMode.alarm;
  String _selectedSoundId = 'cyber_chime';
  bool _isPlayingPreview = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString('default_reminder_delivery_mode');
      final soundId =
          prefs.getString('fit_host_default_alarm_sound') ?? 'cyber_chime';

      setState(() {
        _masterNotifications =
            prefs.getBool('notification_master_enabled') ?? true;
        _workoutsEnabled =
            prefs.getBool('notification_workouts_enabled') ?? true;
        _mealsEnabled = prefs.getBool('notification_meals_enabled') ?? true;
        _hydrationEnabled =
            prefs.getBool('notification_hydration_enabled') ?? true;
        _recoveryEnabled =
            prefs.getBool('notification_recovery_enabled') ?? true;
        _habitsEnabled = prefs.getBool('notification_habits_enabled') ?? true;
        _soundEnabled = prefs.getBool('notification_sound_enabled') ?? true;
        _vibrationEnabled =
            prefs.getBool('notification_vibration_enabled') ?? true;
        _defaultSnooze = prefs.getInt('notification_default_snooze') ?? 10;
        _defaultDeliveryMode = ReminderDeliveryMode.fromString(modeStr);
        _selectedSoundId = soundId;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreference(String key, dynamic val) async {
    final prefs = await SharedPreferences.getInstance();
    if (val is bool) {
      await prefs.setBool(key, val);
    } else if (val is int) {
      await prefs.setInt(key, val);
    } else if (val is String) {
      await prefs.setString(key, val);
    }
  }

  Future<void> _previewSound(String soundId) async {
    final soundService = ref.read(alarmSoundServiceProvider);
    setState(() => _isPlayingPreview = true);
    try {
      await soundService.previewSound(soundId);
    } catch (e) {
      debugPrint('[NotificationSettings] Sound preview error: $e');
    } finally {
      if (mounted) setState(() => _isPlayingPreview = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notifService = ref.read(notificationServiceProvider);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Notification & Alarm Settings',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Permission & Reliability Status Card
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF13221C), const Color(0xFF101924)]
                      : [const Color(0xFFE8F8F0), Colors.white],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.limeGreen.withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.limeGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security_update_good_rounded,
                    color: AppColors.limeGreen,
                    size: 22,
                  ),
                ),
                title: const Text(
                  'Android Permissions & Exact Alarms',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                subtitle: Text(
                  'Manage exact alarms, lockscreen display, and battery exclusions',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.limeGreen,
                ),
                onTap: () => context.push('/permission-settings'),
              ),
            ),

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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Schedule offline alarms & alerts for workouts & meals',
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
                      _savePreference('notification_master_enabled', val);
                      notifService.setPermissionsAllowed(val);
                      ref.read(reminderRepositoryProvider).reconcileSchedules();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Default Delivery Mode Selector
            const Text(
              'Default Delivery Mode',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(
                              () => _defaultDeliveryMode =
                                  ReminderDeliveryMode.alarm,
                            );
                            _savePreference(
                              'default_reminder_delivery_mode',
                              'alarm',
                            );
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  _defaultDeliveryMode ==
                                      ReminderDeliveryMode.alarm
                                  ? AppColors.electricBlue.withValues(
                                      alpha: 0.15,
                                    )
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color:
                                    _defaultDeliveryMode ==
                                        ReminderDeliveryMode.alarm
                                    ? AppColors.electricBlue
                                    : (isDark
                                          ? Colors.white12
                                          : Colors.black12),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.alarm_rounded,
                                  size: 18,
                                  color:
                                      _defaultDeliveryMode ==
                                          ReminderDeliveryMode.alarm
                                      ? AppColors.electricBlue
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                const Flexible(
                                  child: Text(
                                    'Alarm-Style',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(
                              () => _defaultDeliveryMode =
                                  ReminderDeliveryMode.notification,
                            );
                            _savePreference(
                              'default_reminder_delivery_mode',
                              'notification',
                            );
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  _defaultDeliveryMode ==
                                      ReminderDeliveryMode.notification
                                  ? AppColors.electricBlue.withValues(
                                      alpha: 0.15,
                                    )
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color:
                                    _defaultDeliveryMode ==
                                        ReminderDeliveryMode.notification
                                    ? AppColors.electricBlue
                                    : (isDark
                                          ? Colors.white12
                                          : Colors.black12),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.notifications_none_rounded,
                                  size: 18,
                                  color:
                                      _defaultDeliveryMode ==
                                          ReminderDeliveryMode.notification
                                      ? AppColors.electricBlue
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                const Flexible(
                                  child: Text(
                                    'Standard',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _defaultDeliveryMode == ReminderDeliveryMode.alarm
                        ? 'Alarm-Style triggers a prominent notification with continuous ringing audio, vibration, and Snooze/Stop buttons on your lock screen.'
                        : 'Standard mode posts a standard notification banner with a single chime.',
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
            const SizedBox(height: 20),

            // Sound, Vibration, Snooze & Test Alarm Group
            const Text(
              'Alarm Sound, Vibration & Snooze',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkSurfaceBorder
                      : AppColors.lightSurfaceBorder,
                ),
              ),
              child: Column(
                children: [
                  // Sound Selector & Preview
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.music_note_rounded,
                            size: 20,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Alarm Tone',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Select sound preset',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DropdownButton<String>(
                          value: _selectedSoundId,
                          underline: const SizedBox.shrink(),
                          items: AlarmSoundService.defaultPresets.map((p) {
                            return DropdownMenuItem(
                              value: p.id,
                              child: Text(
                                p.name,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedSoundId = val);
                              _savePreference(
                                'fit_host_default_alarm_sound',
                                val,
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip: 'Preview sound',
                          icon: _isPlayingPreview
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.play_circle_fill_rounded,
                                  color: AppColors.limeGreen,
                                ),
                          onPressed: _isPlayingPreview
                              ? null
                              : () => _previewSound(_selectedSoundId),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Sound Notification Toggle
                  _buildToggleRow(
                    title: 'Sound Notification',
                    subtitle: 'Play selected alarm tone when firing',
                    icon: Icons.volume_up_rounded,
                    color: Colors.teal,
                    value: _soundEnabled && _masterNotifications,
                    onChanged: _masterNotifications
                        ? (v) {
                            setState(() => _soundEnabled = v);
                            _savePreference('notification_sound_enabled', v);
                          }
                        : null,
                  ),
                  const Divider(height: 1),

                  // Vibration Toggle
                  _buildToggleRow(
                    title: 'Haptic Vibration',
                    subtitle: 'Vibrate device on reminder firing',
                    icon: Icons.vibration_rounded,
                    color: Colors.amber,
                    value: _vibrationEnabled && _masterNotifications,
                    onChanged: _masterNotifications
                        ? (v) {
                            setState(() => _vibrationEnabled = v);
                            _savePreference(
                              'notification_vibration_enabled',
                              v,
                            );
                          }
                        : null,
                  ),
                  const Divider(height: 1),

                  // Snooze Duration
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.snooze_rounded,
                                color: Colors.blueGrey,
                                size: 22,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Default Snooze Duration',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Used for quick snooze buttons',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
                            if (val != null) {
                              setState(() => _defaultSnooze = val);
                              _savePreference(
                                'notification_default_snooze',
                                val,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Live Test Alarm Trigger Action
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF16231C)
                    : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.limeGreen.withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.alarm_on_rounded,
                        color: AppColors.limeGreen,
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Test Real Android Alarm',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Schedules an exact Android alarm for 10 seconds from now. '
                    'Lock your phone or press Home to confirm delivery when closed.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await notifService.testTenSecondAlarm();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '⏰ 10-Second Alarm Scheduled! Lock device or minimize app now.',
                              ),
                              backgroundColor: AppColors.limeGreen,
                              duration: Duration(seconds: 4),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.limeGreen,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.timer_rounded, size: 18),
                      label: const Text(
                        'Trigger 10s Test Alarm',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

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
                  color: isDark
                      ? AppColors.darkSurfaceBorder
                      : AppColors.lightSurfaceBorder,
                ),
              ),
              child: Column(
                children: [
                  _buildToggleRow(
                    title: 'Workouts & Training',
                    subtitle:
                        'Scheduled workouts, routine alerts & warmup reminders',
                    icon: Icons.fitness_center_rounded,
                    color: AppColors.electricBlue,
                    value: _workoutsEnabled && _masterNotifications,
                    onChanged: _masterNotifications
                        ? (v) {
                            setState(() => _workoutsEnabled = v);
                            _savePreference('notification_workouts_enabled', v);
                            ref
                                .read(reminderRepositoryProvider)
                                .reconcileSchedules();
                          }
                        : null,
                  ),
                  const Divider(height: 1),
                  _buildToggleRow(
                    title: 'Meals & Nutrition Alarms',
                    subtitle:
                        'Breakfast, lunch, post-workout protein & dinner timing',
                    icon: Icons.restaurant_rounded,
                    color: const Color(0xFFFF6B4A),
                    value: _mealsEnabled && _masterNotifications,
                    onChanged: _masterNotifications
                        ? (v) {
                            setState(() => _mealsEnabled = v);
                            _savePreference('notification_meals_enabled', v);
                            ref
                                .read(reminderRepositoryProvider)
                                .reconcileSchedules();
                          }
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
                        ? (v) {
                            setState(() => _hydrationEnabled = v);
                            _savePreference(
                              'notification_hydration_enabled',
                              v,
                            );
                            ref
                                .read(reminderRepositoryProvider)
                                .reconcileSchedules();
                          }
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
                        ? (v) {
                            setState(() => _recoveryEnabled = v);
                            _savePreference('notification_recovery_enabled', v);
                            ref
                                .read(reminderRepositoryProvider)
                                .reconcileSchedules();
                          }
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
                        ? (v) {
                            setState(() => _habitsEnabled = v);
                            _savePreference('notification_habits_enabled', v);
                            ref
                                .read(reminderRepositoryProvider)
                                .reconcileSchedules();
                          }
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Alarms trigger even when Fit Host is closed using Android Exact Alarm scheduling '
              'with sound, vibration, and Snooze/Stop actions.',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
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
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
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
