import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/reminders/domain/models/reminder.dart';
import 'package:fit_host/features/reminders/data/alarm_sound_service.dart';

void main() {
  group('Reminder isCompletedToday & Advance Occurrences', () {
    test('isCompletedToday returns true when lastCompletedAt is today', () {
      final now = DateTime.now();
      final reminder = Reminder(
        id: 'rem_1',
        title: 'Morning Workout',
        timeOfDay: '08:00',
        recurrence: ReminderRecurrence.daily,
        category: ReminderCategory.workout,
        soundEnabled: true,
        vibrationEnabled: true,
        isEnabled: true,
        snoozeDurationMinutes: 10,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now,
        lastCompletedAt: DateTime(now.year, now.month, now.day, 7, 55),
      );

      expect(reminder.isCompletedToday, isTrue);
    });

    test('isCompletedToday returns false when lastCompletedAt is yesterday', () {
      final now = DateTime.now();
      final reminder = Reminder(
        id: 'rem_2',
        title: 'Hydration Break',
        timeOfDay: '10:00',
        recurrence: ReminderRecurrence.daily,
        category: ReminderCategory.hydration,
        soundEnabled: true,
        vibrationEnabled: true,
        isEnabled: true,
        snoozeDurationMinutes: 10,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now,
        lastCompletedAt: now.subtract(const Duration(days: 1)),
      );

      expect(reminder.isCompletedToday, isFalse);
    });

    test('nextOccurrence advances to tomorrow when completed before set time today', () {
      // Current time is 07:00, alarm set for 09:00, but user clicks complete before set time at 07:00
      final now = DateTime.now();
      final today7am = DateTime(now.year, now.month, now.day, 7, 0);
      final reminder = Reminder(
        id: 'rem_3',
        title: 'Morning Workout',
        timeOfDay: '09:00',
        recurrence: ReminderRecurrence.daily,
        category: ReminderCategory.workout,
        soundEnabled: true,
        vibrationEnabled: true,
        isEnabled: true,
        snoozeDurationMinutes: 10,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now,
        lastCompletedAt: today7am,
      );

      expect(reminder.isCompletedToday, isTrue);

      final next = reminder.nextOccurrence(today7am);
      final expectedTomorrow = today7am.add(const Duration(days: 1));
      // Next occurrence MUST be tomorrow at 09:00, not today at 09:00!
      expect(next.year, expectedTomorrow.year);
      expect(next.month, expectedTomorrow.month);
      expect(next.day, expectedTomorrow.day);
      expect(next.hour, 9);
      expect(next.minute, 0);
    });

    test('AlarmSoundSettings supports custom audio and clearCustomAudio', () {
      const initial = AlarmSoundSettings(
        defaultSoundId: 'cyber_chime',
        fullVolumeBoost: true,
        vibrationPattern: 'standard',
        activitySounds: {'workout': 'titan_horn'},
      );

      expect(initial.customAudioPath, isNull);
      expect(initial.customAudioName, isNull);

      final withCustom = initial.copyWith(
        customAudioPath: '/data/user/0/custom_alarm.mp3',
        customAudioName: 'My Gym Hype Track.mp3',
        defaultSoundId: AlarmSoundService.customSoundId,
      );

      expect(withCustom.defaultSoundId, AlarmSoundService.customSoundId);
      expect(withCustom.customAudioName, 'My Gym Hype Track.mp3');
      expect(withCustom.customAudioPath, '/data/user/0/custom_alarm.mp3');

      final cleared = withCustom.copyWith(
        clearCustomAudio: true,
        defaultSoundId: 'cyber_chime',
      );
      expect(cleared.customAudioPath, isNull);
      expect(cleared.customAudioName, isNull);
      expect(cleared.defaultSoundId, 'cyber_chime');
    });
  });
}
