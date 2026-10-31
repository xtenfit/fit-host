import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/alarm_sound_service.dart';
import '../../domain/models/reminder.dart';
import '../controllers/reminders_controller.dart';

/// A non-intrusive, clear in-app reminder presentation banner that appears at
/// the top of the screen when a scheduled reminder is due while the app is in the foreground.
/// Allows the user to complete, snooze, or open the full alarm screen without disrupting their current flow.
class InAppReminderBanner extends ConsumerStatefulWidget {
  const InAppReminderBanner({super.key});

  @override
  ConsumerState<InAppReminderBanner> createState() =>
      _InAppReminderBannerState();
}

class _InAppReminderBannerState extends ConsumerState<InAppReminderBanner> {
  Timer? _timer;
  Timer? _alarmRingTimer;
  int _secondsRemaining = 60;
  final Set<String> _locallyDismissedIds = {};
  String? _soundingReminderId;

  @override
  void initState() {
    super.initState();
    // Check every 10 seconds for any due reminders while foregrounded
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _alarmRingTimer?.cancel();
    if (_soundingReminderId != null) {
      ref.read(alarmSoundServiceProvider).stopContinuousAlarm();
      ref.read(alarmSoundServiceProvider).stopSound();
    }
    super.dispose();
  }

  Future<void> _autoSnooze(Reminder reminder) async {
    setState(() {
      _locallyDismissedIds.add(reminder.id);
    });
    await ref.read(alarmSoundServiceProvider).stopContinuousAlarm();
    _soundingReminderId = null;
    await ref
        .read(remindersControllerProvider)
        .snoozeReminder(reminder.id, reminder.snoozeDurationMinutes);
  }

  void _playReminderSound(Reminder reminder) {
    if (_soundingReminderId == reminder.id || !reminder.soundEnabled) {
      return;
    }
    _soundingReminderId = reminder.id;
    _secondsRemaining = 60;
    _alarmRingTimer?.cancel();

    if (reminder.deliveryMode == ReminderDeliveryMode.alarm) {
      ref
          .read(alarmSoundServiceProvider)
          .startContinuousAlarm(soundId: 'cyber_chime', boostVolume: true);

      _alarmRingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
          _autoSnooze(reminder);
        }
      });
    } else {
      ref
          .read(alarmSoundServiceProvider)
          .previewSound('cyber_chime', boostVolume: true);
    }
  }

  bool _isDue(Reminder reminder, DateTime now) {
    if (!reminder.isEnabled ||
        reminder.isDismissed ||
        reminder.isCompletedToday) {
      return false;
    }
    if (_locallyDismissedIds.contains(reminder.id)) {
      return false;
    }

    // Check day recurrence
    bool dayMatches = false;
    switch (reminder.recurrence) {
      case ReminderRecurrence.once:
        dayMatches =
            now.year == reminder.createdAt.year &&
            now.month == reminder.createdAt.month &&
            now.day == reminder.createdAt.day;
        break;
      case ReminderRecurrence.daily:
        dayMatches = true;
        break;
      case ReminderRecurrence.weekdays:
        dayMatches =
            now.weekday >= DateTime.monday && now.weekday <= DateTime.friday;
        break;
      case ReminderRecurrence.weekly:
        dayMatches = now.weekday == reminder.createdAt.weekday;
        break;
      case ReminderRecurrence.monthly:
        dayMatches = now.day == reminder.createdAt.day;
        break;
      case ReminderRecurrence.custom:
        dayMatches =
            reminder.repeatDays.isEmpty ||
            reminder.repeatDays.contains(now.weekday);
        break;
    }

    if (!dayMatches) return false;

    // Check time window: active if within [0..5] minutes past the scheduled hour:minute
    final nowMinutes = now.hour * 60 + now.minute;
    final scheduledMinutes = reminder.hour * 60 + reminder.minute;
    final diff = nowMinutes - scheduledMinutes;

    return diff >= 0 && diff <= 5;
  }

  @override
  Widget build(BuildContext context) {
    final remindersAsync = ref.watch(activeRemindersProvider);

    return remindersAsync.when(
      data: (reminders) {
        final now = DateTime.now();
        final dueReminders = reminders.where((r) => _isDue(r, now)).toList();

        if (dueReminders.isEmpty) {
          if (_soundingReminderId != null) {
            ref.read(alarmSoundServiceProvider).stopSound();
            _soundingReminderId = null;
          }
          return const SizedBox.shrink();
        }

        final reminder = dueReminders.first;
        _playReminderSound(reminder);
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Material(
          type: MaterialType.transparency,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E222D) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.limeGreen.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.limeGreen.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.alarm_on_rounded,
                        color: AppColors.limeGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            reminder.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${reminder.category.label} • ${reminder.formattedTime}',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (reminder.deliveryMode == ReminderDeliveryMode.alarm)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.volume_up_rounded,
                              color: Colors.redAccent,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_secondsRemaining}s',
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: isDark ? Colors.white60 : Colors.black45,
                      onPressed: () {
                        _alarmRingTimer?.cancel();
                        setState(() {
                          _locallyDismissedIds.add(reminder.id);
                        });
                        ref
                            .read(alarmSoundServiceProvider)
                            .stopContinuousAlarm();
                        ref.read(alarmSoundServiceProvider).stopSound();
                        _soundingReminderId = null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Complete action
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.limeGreen,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          visualDensity: VisualDensity.compact,
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        icon: const Icon(Icons.check_rounded, size: 15),
                        label: const Text('Mark Complete ✓'),
                        onPressed: () async {
                          _alarmRingTimer?.cancel();
                          setState(() {
                            _locallyDismissedIds.add(reminder.id);
                          });
                          await ref
                              .read(alarmSoundServiceProvider)
                              .stopContinuousAlarm();
                          await ref.read(alarmSoundServiceProvider).stopSound();
                          _soundingReminderId = null;
                          await ref
                              .read(remindersControllerProvider)
                              .completeReminder(reminder.id);
                        },
                      ),
                      const SizedBox(width: 8),
                      // Snooze action
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? Colors.white
                              : Colors.black87,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          visualDensity: VisualDensity.compact,
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        icon: const Icon(Icons.snooze_rounded, size: 15),
                        label: Text(
                          'Snooze ${reminder.snoozeDurationMinutes}m',
                        ),
                        onPressed: () async {
                          _alarmRingTimer?.cancel();
                          setState(() {
                            _locallyDismissedIds.add(reminder.id);
                          });
                          await ref
                              .read(alarmSoundServiceProvider)
                              .stopContinuousAlarm();
                          await ref.read(alarmSoundServiceProvider).stopSound();
                          _soundingReminderId = null;
                          await ref
                              .read(remindersControllerProvider)
                              .snoozeReminder(
                                reminder.id,
                                reminder.snoozeDurationMinutes,
                              );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}
