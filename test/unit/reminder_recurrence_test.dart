import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/reminders/domain/models/reminder.dart';

void main() {
  group('Reminder Recurrence & Schedule Unit Tests', () {
    test('Daily recurrence calculates correct next occurrence', () {
      final now = DateTime(2026, 10, 15, 6, 0); // 6:00 AM
      final reminder = Reminder(
        id: '1',
        title: 'Morning Water',
        category: ReminderCategory.hydration,
        timeOfDay: '08:30',
        isEnabled: true,
        recurrence: ReminderRecurrence.daily,
        createdAt: now,
        updatedAt: now,
      );

      final next = reminder.nextOccurrence(now);
      expect(next.year, 2026);
      expect(next.month, 10);
      expect(next.day, 15);
      expect(next.hour, 8);
      expect(next.minute, 30);

      // When 'from' is past 8:30 AM, next occurrence should be next day (Oct 16)
      final pastNow = DateTime(2026, 10, 15, 9, 0);
      final nextDay = reminder.nextOccurrence(pastNow);
      expect(nextDay.year, 2026);
      expect(nextDay.month, 10);
      expect(nextDay.day, 16);
      expect(nextDay.hour, 8);
      expect(nextDay.minute, 30);
    });

    test('Weekday recurrence skips Saturday and Sunday', () {
      // 2026-10-16 is Friday
      final fridayEvening = DateTime(2026, 10, 16, 20, 0);
      final reminder = Reminder(
        id: '2',
        title: 'Workday Stretch',
        category: ReminderCategory.workout,
        timeOfDay: '17:00',
        isEnabled: true,
        recurrence: ReminderRecurrence.weekdays,
        createdAt: fridayEvening,
        updatedAt: fridayEvening,
      );

      final next = reminder.nextOccurrence(fridayEvening);
      // Next weekday after Friday evening must be Monday (Oct 19)
      expect(next.year, 2026);
      expect(next.month, 10);
      expect(next.day, 19);
      expect(next.weekday, DateTime.monday);
      expect(next.hour, 17);
      expect(next.minute, 0);
    });

    test('Weekly recurrence adds 7 days', () {
      final now = DateTime(2026, 10, 15, 12, 0); // Thursday 12:00
      final reminder = Reminder(
        id: '3',
        title: 'Weekly Weigh-in',
        category: ReminderCategory.custom,
        timeOfDay: '07:00',
        isEnabled: true,
        recurrence: ReminderRecurrence.weekly,
        createdAt: now,
        updatedAt: now,
      );

      final next = reminder.nextOccurrence(now);
      // Since 7:00 AM on Oct 15 has already passed, next should be next Thursday (Oct 22)
      expect(next.year, 2026);
      expect(next.month, 10);
      expect(next.day, 22);
      expect(next.hour, 7);
      expect(next.minute, 0);
    });

    test('Custom days recurrence picks next scheduled day', () {
      // 2026-10-15 is Thursday (weekday 4)
      final thursdayMorning = DateTime(2026, 10, 15, 6, 0);
      final reminder = Reminder(
        id: '4',
        title: 'Mon-Wed-Fri Routine',
        category: ReminderCategory.workout,
        timeOfDay: '18:00',
        isEnabled: true,
        recurrence: ReminderRecurrence.custom,
        repeatDays: [DateTime.monday, DateTime.wednesday, DateTime.friday],
        createdAt: thursdayMorning,
        updatedAt: thursdayMorning,
      );

      final next = reminder.nextOccurrence(thursdayMorning);
      // Scheduled for Friday Oct 16
      expect(next.year, 2026);
      expect(next.month, 10);
      expect(next.day, 16);
      expect(next.weekday, DateTime.friday);
      expect(next.hour, 18);
    });

    test('Formatted time and repeat summary format correctly', () {
      final rem = Reminder(
        id: '5',
        title: 'Bedtime',
        category: ReminderCategory.sleep,
        timeOfDay: '22:15',
        isEnabled: true,
        recurrence: ReminderRecurrence.daily,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(rem.formattedTime, '10:15 PM');
      expect(rem.repeatSummary, 'Every day');

      final remWeekdays = rem.copyWith(recurrence: ReminderRecurrence.weekdays);
      expect(remWeekdays.repeatSummary, 'Mon - Fri');

      final remCustom = rem.copyWith(
        recurrence: ReminderRecurrence.custom,
        repeatDays: [1, 3, 5],
      );
      expect(remCustom.repeatSummary, 'Mon, Wed, Fri');
    });
  });
}
