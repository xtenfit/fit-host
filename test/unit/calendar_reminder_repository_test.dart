import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/database/database.dart' as db;
import 'package:fit_host/core/services/notification_service.dart';
import 'package:fit_host/features/calendar/data/repositories/calendar_repository.dart';
import 'package:fit_host/features/calendar/domain/models/calendar_event.dart';
import 'package:fit_host/features/reminders/data/repositories/reminder_repository.dart';
import 'package:fit_host/features/reminders/domain/models/reminder.dart';

void main() {
  late db.AppDatabase dbInstance;
  late CalendarRepository calendarRepo;
  late ReminderRepository reminderRepo;
  late NotificationService notifService;

  setUp(() {
    dbInstance = db.AppDatabase(NativeDatabase.memory());
    calendarRepo = CalendarRepositoryImpl(dbInstance);
    notifService = NotificationService();
    reminderRepo = ReminderRepositoryImpl(dbInstance, notifService);
  });

  tearDown(() async {
    await dbInstance.close();
  });

  group('Calendar & Reminder Repository SQLite Persistence Tests', () {
    test('CalendarRepository seeds initial events and supports CRUD & Rescheduling', () async {
      await calendarRepo.seedInitialCalendarEvents();

      final allEvents = await calendarRepo.watchAllEvents().first;
      expect(allEvents.isNotEmpty, isTrue);

      final today = DateTime.now();
      final testEvent = CalendarEvent(
        id: 'cal-test-1',
        title: 'HIIT Cardio Session',
        eventType: CalendarEventType.workout,
        scheduledDate: today,
        createdAt: today,
        updatedAt: today,
      );

      await calendarRepo.createEvent(testEvent);
      final eventsToday = await calendarRepo.getEventsForDate(today);
      expect(eventsToday.any((e) => e.id == 'cal-test-1'), isTrue);

      // Reschedule
      final tomorrow = today.add(const Duration(days: 1));
      await calendarRepo.rescheduleEvent('cal-test-1', tomorrow, null);

      final eventsTomorrow = await calendarRepo.getEventsForDate(tomorrow);
      expect(eventsTomorrow.any((e) => e.id == 'cal-test-1'), isTrue);

      // Toggle Complete
      await calendarRepo.toggleCompletion('cal-test-1', true);
      final updatedEvents = await calendarRepo.getEventsForDate(tomorrow);
      final updated = updatedEvents.firstWhere((e) => e.id == 'cal-test-1');
      expect(updated.isCompleted, isTrue);

      // Delete
      await calendarRepo.deleteEvent('cal-test-1');
      final finalEvents = await calendarRepo.getEventsForDate(tomorrow);
      expect(finalEvents.any((e) => e.id == 'cal-test-1'), isFalse);
    });

    test('ReminderRepository supports CRUD, deduplication, and snooze', () async {
      await reminderRepo.seedInitialReminders();

      final initialReminders = await reminderRepo.getAllReminders();
      expect(initialReminders.isNotEmpty, isTrue);

      final now = DateTime.now();
      final newReminder = Reminder(
        id: 'rem-test-1',
        title: 'Electrolyte Refill',
        category: ReminderCategory.hydration,
        timeOfDay: '11:00',
        isEnabled: true,
        recurrence: ReminderRecurrence.daily,
        snoozeDurationMinutes: 15,
        createdAt: now,
        updatedAt: now,
      );

      await reminderRepo.createReminder(newReminder);
      final fetched = await reminderRepo.getReminder('rem-test-1');
      expect(fetched, isNotNull);
      expect(fetched!.title, 'Electrolyte Refill');

      // Duplicate prevention: same title & time should update rather than insert duplicate
      final dupReminder = newReminder.copyWith(id: 'rem-test-dup', snoozeDurationMinutes: 20);
      await reminderRepo.createReminder(dupReminder);

      final allReminders = await reminderRepo.getAllReminders();
      final matches = allReminders.where((r) => r.title == 'Electrolyte Refill');
      expect(matches.length, 1);
      expect(matches.first.snoozeDurationMinutes, 20);

      // Toggle enabled
      await reminderRepo.toggleEnabled(matches.first.id, false);
      final disabled = await reminderRepo.getReminder(matches.first.id);
      expect(disabled!.isEnabled, isFalse);

      // Snooze
      await reminderRepo.snoozeReminder(matches.first.id, 10);
      final snoozed = await reminderRepo.getReminder(matches.first.id);
      expect(snoozed!.lastTriggeredAt, isNotNull);

      // Complete
      await reminderRepo.completeReminder(matches.first.id);
      final completed = await reminderRepo.getReminder(matches.first.id);
      expect(completed!.lastCompletedAt, isNotNull);

      // Delete
      await reminderRepo.deleteReminder(matches.first.id);
      final deleted = await reminderRepo.getReminder(matches.first.id);
      expect(deleted, isNull);
    });
  });
}
