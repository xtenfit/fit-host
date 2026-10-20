import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/alarm_sound_service.dart';
import '../controllers/reminders_controller.dart';
import '../../../workouts/presentation/controllers/workout_providers.dart';
import '../../../workouts/domain/models/workout_models.dart';

class FullscreenAlarmScreen extends ConsumerStatefulWidget {
  final String id;
  final String title;
  final String body;
  final String? channel;
  final int snoozeMinutes;

  const FullscreenAlarmScreen({
    super.key,
    required this.id,
    required this.title,
    required this.body,
    this.channel,
    this.snoozeMinutes = 10,
  });

  @override
  ConsumerState<FullscreenAlarmScreen> createState() =>
      _FullscreenAlarmScreenState();
}

class _FullscreenAlarmScreenState extends ConsumerState<FullscreenAlarmScreen>
    with SingleTickerProviderStateMixin {
  late Timer _clockTimer;
  Timer? _countdownTimer;
  int _secondsRemaining = 60;
  DateTime _now = DateTime.now();
  late AnimationController _pulseController;

  AlarmSoundService? _soundService;

  @override
  void initState() {
    super.initState();
    _soundService = ref.read(alarmSoundServiceProvider);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });

    _startCountdownTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAlarmRinging();
    });
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        _autoSnoozeDueToTimeout();
      }
    });
  }

  void _startAlarmRinging() {
    final soundService = ref.read(alarmSoundServiceProvider);
    final soundSettings = ref.read(alarmSoundSettingsProvider).value;
    String soundId = 'cyber_chime';
    if (soundSettings != null) {
      final act = widget.channel ?? 'workout';
      soundId = soundSettings.activitySounds[act] ?? soundSettings.defaultSoundId;
    }
    soundService.startContinuousAlarm(soundId: soundId, boostVolume: true);
  }

  Future<void> _autoSnoozeDueToTimeout() async {
    final soundService = ref.read(alarmSoundServiceProvider);
    await soundService.stopContinuousAlarm();

    final gapTime = widget.snoozeMinutes > 0 ? widget.snoozeMinutes : 5;

    // Reschedule alarm for gapTime so it reminds again
    if (!_isTestId(widget.id)) {
      try {
        await ref
            .read(remindersControllerProvider)
            .snoozeReminder(widget.id, gapTime);
      } catch (_) {}
    }
    await NotificationService.instance.snoozeNotification(widget.id, gapTime);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⏰ Alarm timed out after 60s. Auto-snoozed for $gapTime mins.',
          ),
          backgroundColor: Colors.amber.shade800,
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.of(context).maybePop();
    }
  }

  bool _isTestId(String id) {
    return id.startsWith('test_') || id == 'alarm_default';
  }

  Future<void> _completeAlarmForToday() async {
    _countdownTimer?.cancel();
    final soundService = ref.read(alarmSoundServiceProvider);
    await soundService.stopContinuousAlarm();

    // 1. Log workout in Drift/Supabase if this is a workout reminder
    final channelLower = widget.channel?.toLowerCase() ?? '';
    if (channelLower == 'workout' || channelLower == 'workouts' || widget.title.toLowerCase().contains('workout')) {
      try {
        final repo = ref.read(workoutRepositoryProvider);
        final now = DateTime.now();
        final workoutId = 'workout_alarm_${now.millisecondsSinceEpoch}';
        final completedWorkout = WorkoutEntity(
          id: workoutId,
          title: widget.title.isNotEmpty ? widget.title : 'Completed Workout Session',
          category: 'Strength',
          startedAt: now.subtract(const Duration(minutes: 30)),
          completedAt: now,
          status: 'completed',
          durationSeconds: 1800,
          caloriesBurned: 220,
          updatedAt: now,
          exercises: const [],
        );
        await repo.saveWorkout(completedWorkout);
        ref.invalidate(workoutsStreamProvider);
      } catch (e) {
        debugPrint('[FullscreenAlarmScreen] Failed to save workout record: $e');
      }
    }

    // 2. Mark reminder completed
    if (!_isTestId(widget.id)) {
      try {
        await ref
            .read(remindersControllerProvider)
            .completeReminder(widget.id);
      } catch (_) {}
    }
    await NotificationService.instance.cancelNotification(widget.id);

    // 3. Dismiss alarm overlay and show success snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Mark completed! Logged to history and next alarm set for tomorrow.'),
          backgroundColor: AppColors.limeGreen,
          duration: Duration(seconds: 3),
        ),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        context.go('/home');
      }
    }
  }

  Future<void> _snoozeAlarm() async {
    _countdownTimer?.cancel();
    final soundService = ref.read(alarmSoundServiceProvider);
    await soundService.stopContinuousAlarm();

    final gapTime = widget.snoozeMinutes > 0 ? widget.snoozeMinutes : 10;

    if (!_isTestId(widget.id)) {
      try {
        await ref
            .read(remindersControllerProvider)
            .snoozeReminder(widget.id, gapTime);
      } catch (_) {}
    }
    await NotificationService.instance.snoozeNotification(widget.id, gapTime);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Snoozed for $gapTime minutes. Will ring again.'),
          backgroundColor: Colors.blueGrey,
          duration: const Duration(seconds: 3),
        ),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        context.go('/home');
      }
    }
  }

  Future<void> _dismissOnly() async {
    _countdownTimer?.cancel();
    final soundService = ref.read(alarmSoundServiceProvider);
    await soundService.stopContinuousAlarm();
    await NotificationService.instance.cancelNotification(widget.id);
    if (mounted) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        context.go('/home');
      }
    }
  }

  void _openTracker(String route) {
    _countdownTimer?.cancel();
    _soundService?.stopContinuousAlarm();
    NotificationService.instance.cancelNotification(widget.id);
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    context.push(route);
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _soundService?.stopContinuousAlarm();
    super.dispose();
  }

  // --- Type-Specific Styling & UI Attributes ---
  _ReminderTypeConfig _getConfig(String? channel) {
    switch (channel?.toLowerCase()) {
      case 'workouts':
      case 'workout':
        return const _ReminderTypeConfig(
          label: 'WORKOUT SESSION',
          subtitle: 'Time to hit your workout, crush sets & log reps',
          primaryColor: AppColors.limeGreen,
          secondaryColor: Color(0xFF10B981),
          icon: Icons.fitness_center_rounded,
          completeButtonLabel: 'Mark Complete ✓',
          trackerRoute: '/workouts',
          trackerButtonLabel: 'Open Workout Tracker',
        );
      case 'nutrition':
      case 'diet':
        return const _ReminderTypeConfig(
          label: 'DIET & NUTRITION',
          subtitle: 'Scheduled meal window & macro fuel check-in',
          primaryColor: Color(0xFFF97316),
          secondaryColor: Color(0xFFFB923C),
          icon: Icons.restaurant_rounded,
          completeButtonLabel: 'Log Meal ✓',
          trackerRoute: '/nutrition',
          trackerButtonLabel: 'Open Nutrition Diary',
        );
      case 'hydration':
      case 'water':
        return const _ReminderTypeConfig(
          label: 'HYDRATION CHECK',
          subtitle: 'Drink a tall glass of water (250ml) for peak energy',
          primaryColor: Color(0xFF00E5FF),
          secondaryColor: Color(0xFF38BDF8),
          icon: Icons.water_drop_rounded,
          completeButtonLabel: 'Log Water (+250ml) ✓',
          trackerRoute: '/nutrition',
          trackerButtonLabel: 'Open Hydration Log',
        );
      case 'recovery':
      case 'sleep':
        return const _ReminderTypeConfig(
          label: 'REST & RECOVERY',
          subtitle: 'Wind down, dim blue light & prepare for restorative sleep',
          primaryColor: Color(0xFFA855F7),
          secondaryColor: Color(0xFFC084FC),
          icon: Icons.bedtime_rounded,
          completeButtonLabel: 'Mark Complete ✓',
          trackerRoute: null,
          trackerButtonLabel: null,
        );
      case 'habits':
      case 'diary':
      default:
        return const _ReminderTypeConfig(
          label: 'DAILY HABIT & STREAK',
          subtitle: 'Maintain your consistency streak and check off your goal',
          primaryColor: Color(0xFFFFB300),
          secondaryColor: Color(0xFFFCD34D),
          icon: Icons.local_fire_department_rounded,
          completeButtonLabel: 'Mark Complete ✓',
          trackerRoute: '/diary',
          trackerButtonLabel: 'Open Daily Diary',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('hh:mm').format(_now);
    final periodStr = DateFormat('a').format(_now);
    final dateStr = DateFormat('EEEE, MMMM d').format(_now);
    final cfg = _getConfig(widget.channel);
    final progress = _secondsRemaining / 60.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _dismissOnly();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF070B14),
        body: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.2,
              colors: [
                cfg.primaryColor.withValues(alpha: 0.18),
                const Color(0xFF090E1A),
                const Color(0xFF05070D),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // --- TOP BAR: Category Badge & 60s Ringing Timer ---
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Type Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: cfg.primaryColor.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: cfg.primaryColor.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(cfg.icon, color: cfg.primaryColor, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  cfg.label,
                                  style: TextStyle(
                                    color: cfg.primaryColor,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Close / Dismiss Icon
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 24),
                            onPressed: _dismissOnly,
                            tooltip: 'Dismiss',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Ringing 60s Countdown Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cfg.primaryColor.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.ring_volume_rounded,
                                      color: cfg.primaryColor,
                                      size: 15,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Ringing for 1 minute',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Auto-snooze in ${_secondsRemaining}s',
                                  style: TextStyle(
                                    color: cfg.primaryColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.white12,
                                valueColor: AlwaysStoppedAnimation<Color>(cfg.primaryColor),
                                minHeight: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  // --- CENTER SECTION: Animated Pulsing Radar & Digital Clock ---
                  Column(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final scale = 1.0 + (_pulseController.value * 0.12);
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cfg.primaryColor.withValues(alpha: 0.15),
                                border: Border.all(
                                  color: cfg.primaryColor.withValues(alpha: 0.6),
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: cfg.primaryColor.withValues(alpha: 0.35),
                                    blurRadius: 36 * _pulseController.value,
                                    spreadRadius: 8 * _pulseController.value,
                                  ),
                                ],
                              ),
                              child: Icon(
                                cfg.icon,
                                size: 56,
                                color: cfg.primaryColor,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            timeStr,
                            style: const TextStyle(
                              fontSize: 62,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -2,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            periodStr,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: cfg.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.body.isNotEmpty ? widget.body : cfg.subtitle,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFCBD5E1),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),

                  // --- BOTTOM ACTIONS: Complete for Today, Snooze, & Tracker Shortcut ---
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Primary Action: Complete for Today (Stops alarm, advances to tomorrow)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _completeAlarmForToday,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cfg.primaryColor,
                            foregroundColor: Colors.black,
                            elevation: 8,
                            shadowColor: cfg.primaryColor.withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 22),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  cfg.completeButtonLabel,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 2. Secondary Action: Snooze with gap time
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _snoozeAlarm,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF334155), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.snooze_rounded, size: 20, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 8),
                              Text(
                                'Snooze (${widget.snoozeMinutes} Min Gap)',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 3. Optional Tracker Shortcut
                      if (cfg.trackerRoute != null && cfg.trackerButtonLabel != null) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _openTracker(cfg.trackerRoute!),
                          icon: Icon(Icons.open_in_new_rounded, size: 16, color: cfg.primaryColor),
                          label: Text(
                            cfg.trackerButtonLabel!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: cfg.primaryColor,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReminderTypeConfig {
  final String label;
  final String subtitle;
  final Color primaryColor;
  final Color secondaryColor;
  final IconData icon;
  final String completeButtonLabel;
  final String? trackerRoute;
  final String? trackerButtonLabel;

  const _ReminderTypeConfig({
    required this.label,
    required this.subtitle,
    required this.primaryColor,
    required this.secondaryColor,
    required this.icon,
    required this.completeButtonLabel,
    this.trackerRoute,
    this.trackerButtonLabel,
  });
}
