import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fit_host/core/services/notification_service.dart';
import 'package:fit_host/features/reminders/domain/models/reminder.dart';
import 'package:fit_host/features/reminders/presentation/widgets/add_edit_reminder_dialog.dart';
import 'package:fit_host/features/settings/presentation/notification_settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('1. Next Occurrence & Recurrence Rules Tests', () {
    test(
      'Daily reminder calculates next occurrence today if before scheduled time',
      () {
        final base = DateTime(2026, 10, 23, 7, 0); // 7:00 AM
        final reminder = Reminder(
          id: 'rem-daily-1',
          title: 'Morning Run',
          category: ReminderCategory.workout,
          timeOfDay: '08:30',
          recurrence: ReminderRecurrence.daily,
          createdAt: base,
          updatedAt: base,
        );

        final next = reminder.nextOccurrence(base);
        expect(next, equals(DateTime(2026, 10, 23, 8, 30)));
      },
    );

    test(
      'Daily reminder advances to tomorrow if today scheduled time has passed',
      () {
        final base = DateTime(2026, 10, 23, 9, 0); // 9:00 AM (after 8:30)
        final reminder = Reminder(
          id: 'rem-daily-2',
          title: 'Morning Run',
          category: ReminderCategory.workout,
          timeOfDay: '08:30',
          recurrence: ReminderRecurrence.daily,
          createdAt: base,
          updatedAt: base,
        );

        final next = reminder.nextOccurrence(base);
        expect(next, equals(DateTime(2026, 10, 24, 8, 30)));
      },
    );

    test('Weekdays recurrence skips Saturday and Sunday to land on Monday', () {
      // 2026-10-23 is a Friday.
      final fridayEvening = DateTime(2026, 10, 23, 19, 0);
      final reminder = Reminder(
        id: 'rem-weekday-1',
        title: 'Workday Stretch',
        category: ReminderCategory.workout,
        timeOfDay: '08:00',
        recurrence: ReminderRecurrence.weekdays,
        createdAt: fridayEvening,
        updatedAt: fridayEvening,
      );

      final next = reminder.nextOccurrence(fridayEvening);
      // Next weekday must be Monday 2026-10-26
      expect(next.weekday, equals(DateTime.monday));
      expect(next.year, equals(2026));
      expect(next.month, equals(10));
      expect(next.day, equals(26));
      expect(next.hour, equals(8));
      expect(next.minute, equals(0));
    });

    test(
      'Weekly recurrence schedules exactly 7 days later after time passes',
      () {
        final base = DateTime(2026, 10, 23, 15, 0);
        final reminder = Reminder(
          id: 'rem-weekly-1',
          title: 'Weekly Long Run',
          category: ReminderCategory.workout,
          timeOfDay: '09:00',
          recurrence: ReminderRecurrence.weekly,
          createdAt: base,
          updatedAt: base,
        );

        final next = reminder.nextOccurrence(base);
        expect(next, equals(DateTime(2026, 10, 30, 9, 0)));
        expect(next.difference(DateTime(2026, 10, 23, 9, 0)).inDays, equals(7));
      },
    );

    test('Monthly recurrence advances correctly to next month same day', () {
      final base = DateTime(2026, 1, 15, 12, 0);
      final reminder = Reminder(
        id: 'rem-monthly-1',
        title: 'Monthly Measurements',
        category: ReminderCategory.habit,
        timeOfDay: '10:00',
        recurrence: ReminderRecurrence.monthly,
        createdAt: base,
        updatedAt: base,
      );

      final next = reminder.nextOccurrence(base);
      expect(next.month, equals(2));
      expect(next.day, equals(15));
      expect(next.hour, equals(10));
      expect(next.minute, equals(0));
    });

    test(
      'Custom days recurrence schedules only on selected days (Mon, Wed, Fri)',
      () {
        // 2026-10-23 is Friday (day 5). Scheduled time is 18:00. Base is Friday 19:00.
        final fridayNight = DateTime(2026, 10, 23, 19, 0);
        final reminder = Reminder(
          id: 'rem-custom-1',
          title: 'MWF Push Day',
          category: ReminderCategory.workout,
          timeOfDay: '18:00',
          recurrence: ReminderRecurrence.custom,
          repeatDays: [1, 3, 5], // Mon, Wed, Fri
          createdAt: fridayNight,
          updatedAt: fridayNight,
        );

        final next = reminder.nextOccurrence(fridayNight);
        // Next day must be Monday (day 1)
        expect(next.weekday, equals(DateTime.monday));
        expect(next.day, equals(26));
        expect(next.hour, equals(18));
        expect(next.minute, equals(0));
      },
    );
  });

  group('2. Snooze, Cancellation & Duplicate Prevention Tests', () {
    test('Stable notification hash code produces valid 31-bit integers', () {
      const id1 = 'rem-workout-uuid-12345';
      const id2 = 'rem-workout-uuid-67890';
      final notifId1 = id1.hashCode.abs() % 2147483647;
      final notifId2 = id2.hashCode.abs() % 2147483647;

      expect(notifId1, isNonNegative);
      expect(notifId1, lessThan(2147483647));
      expect(notifId2, isNonNegative);
      expect(notifId1, isNot(equals(notifId2)));
    });

    test(
      'NotificationService scheduleAlarm and cancel prevent duplicates',
      () async {
        final notif = NotificationService.instance;
        await notif.initialize();

        const reminderId = 'test-dup-prevention-1';
        final time1 = DateTime.now().add(const Duration(hours: 1));
        final time2 = DateTime.now().add(const Duration(hours: 2));

        await notif.scheduleAlarm(
          id: reminderId,
          title: 'Initial Alarm',
          body: 'Body 1',
          scheduledTime: time1,
          channel: NotificationChannelType.workouts,
        );

        expect(
          notif.scheduledNotifications.where((i) => i.id == reminderId).length,
          equals(1),
        );
        expect(
          notif.scheduledNotifications
              .firstWhere((i) => i.id == reminderId)
              .title,
          equals('Initial Alarm'),
        );

        // Reschedule same ID with new time (edit flow)
        await notif.scheduleAlarm(
          id: reminderId,
          title: 'Updated Alarm',
          body: 'Body 2',
          scheduledTime: time2,
          channel: NotificationChannelType.workouts,
        );

        // Must replace existing, not append duplicate
        expect(
          notif.scheduledNotifications.where((i) => i.id == reminderId).length,
          equals(1),
        );
        expect(
          notif.scheduledNotifications
              .firstWhere((i) => i.id == reminderId)
              .title,
          equals('Updated Alarm'),
        );

        // Cancel
        await notif.cancelNotification(reminderId);
        expect(
          notif.scheduledNotifications.any((i) => i.id == reminderId),
          isFalse,
        );
      },
    );

    test(
      'Snooze properly reschedules alarm for snoozeMinutes into the future',
      () async {
        final notif = NotificationService.instance;
        const reminderId = 'test-snooze-unit';

        await notif.scheduleAlarm(
          id: reminderId,
          title: 'Hydration Alarm',
          body: 'Drink 500ml water',
          scheduledTime: DateTime.now().add(const Duration(minutes: 1)),
          channel: NotificationChannelType.hydration,
        );

        final beforeSnooze = DateTime.now();
        await notif.snoozeNotification(reminderId, 10);

        final snoozed = notif.scheduledNotifications.firstWhere(
          (i) => i.id == reminderId,
        );
        expect(snoozed.title, equals('Hydration Alarm'));
        expect(snoozed.channel, equals(NotificationChannelType.hydration));
        // Scheduled time should be ~10 minutes from now
        final diff = snoozed.scheduledTime.difference(beforeSnooze);
        expect(diff.inMinutes, inInclusiveRange(9, 11));

        await notif.cancelNotification(reminderId);
      },
    );
  });

  group('3. Reminder Delivery Mode Model & Persistence Tests', () {
    test('ReminderDeliveryMode enum maps from and to strings accurately', () {
      expect(
        ReminderDeliveryMode.fromString('alarm'),
        equals(ReminderDeliveryMode.alarm),
      );
      expect(
        ReminderDeliveryMode.fromString('ALARM'),
        equals(ReminderDeliveryMode.alarm),
      );
      expect(
        ReminderDeliveryMode.fromString('notification'),
        equals(ReminderDeliveryMode.notification),
      );
      expect(
        ReminderDeliveryMode.fromString('NOTIFICATION'),
        equals(ReminderDeliveryMode.notification),
      );
      expect(
        ReminderDeliveryMode.fromString(null),
        equals(ReminderDeliveryMode.alarm),
      );
      expect(
        ReminderDeliveryMode.fromString('unknown'),
        equals(ReminderDeliveryMode.alarm),
      );

      expect(ReminderDeliveryMode.alarm.dbValue, equals('alarm'));
      expect(ReminderDeliveryMode.notification.dbValue, equals('notification'));
    });

    test('Reminder copyWith and defaults preserve deliveryMode', () {
      final now = DateTime.now();
      final reminder = Reminder(
        id: 'rem-mode-test',
        title: 'Chest Day',
        category: ReminderCategory.workout,
        timeOfDay: '17:00',
        createdAt: now,
        updatedAt: now,
        deliveryMode: ReminderDeliveryMode.alarm,
      );

      expect(reminder.deliveryMode, equals(ReminderDeliveryMode.alarm));

      final updated = reminder.copyWith(
        deliveryMode: ReminderDeliveryMode.notification,
      );
      expect(updated.deliveryMode, equals(ReminderDeliveryMode.notification));
      expect(updated.id, equals(reminder.id));
    });
  });

  group('4. Widget Tests: AddEditReminderDialog & Delivery Mode UI', () {
    testWidgets(
      'AddEditReminderDialog displays delivery mode options and allows toggle',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.5;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        Reminder? savedReminder;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () {
                    AddEditReminderDialog.show(
                      ctx,
                      onSave: (rem) => savedReminder = rem,
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        // Verify delivery mode options are rendered
        expect(find.text('Delivery Mode'), findsOneWidget);
        expect(find.text('Alarm-Style'), findsOneWidget);
        expect(find.text('Standard'), findsOneWidget);

        // Toggle to Standard Notification
        await tester.tap(find.text('Standard'));
        await tester.pumpAndSettle();

        // Enter label and save
        await tester.enterText(find.byType(TextField).first, 'Protein Shake');
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Set Reminder'));
        await tester.tap(find.text('Set Reminder'));
        await tester.pumpAndSettle();

        expect(savedReminder, isNotNull);
        expect(savedReminder!.title, equals('Protein Shake'));
        expect(
          savedReminder!.deliveryMode,
          equals(ReminderDeliveryMode.notification),
        );
      },
    );

    testWidgets(
      'NotificationSettingsScreen renders Alarm Tone dropdown and Test Alarm trigger',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.5;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: NotificationSettingsScreen()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Notification & Alarm Settings'), findsOneWidget);
        expect(find.text('Default Delivery Mode'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('Test Real Android Alarm'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(find.text('Test Real Android Alarm'), findsOneWidget);
        expect(find.text('Trigger 10s Test Alarm'), findsOneWidget);

        // Tap Trigger 10s Test Alarm
        await tester.tap(find.text('Trigger 10s Test Alarm'));
        await tester.pump();

        expect(
          find.textContaining('10-Second Alarm Scheduled'),
          findsOneWidget,
        );
      },
    );
  });
}
