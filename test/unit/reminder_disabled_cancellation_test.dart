import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fit_host/core/database/database.dart' as db;
import 'package:fit_host/core/services/notification_service.dart';
import 'package:fit_host/features/reminders/data/repositories/reminder_repository.dart';
import 'package:fit_host/features/reminders/domain/models/reminder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late NotificationService notificationService;
  late ReminderRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    database = db.AppDatabase(NativeDatabase.memory());
    notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.cancelAllNotifications();
    repository = ReminderRepositoryImpl(
      database,
      notificationService,
      userId: 'test_user',
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('Reminder Disabled & Cancellation Bug Fix Tests', () {
    test(
      'NotificationService.toNotificationId is 100% deterministic and non-negative 31-bit integer',
      () {
        final id1 = NotificationService.toNotificationId(
          'workout_reminder_morning',
        );
        final id2 = NotificationService.toNotificationId(
          'workout_reminder_morning',
        );
        final id3 = NotificationService.toNotificationId('meal_reminder_lunch');

        expect(id1, equals(id2));
        expect(id1, isNot(equals(id3)));
        expect(id1, isNonNegative);
        expect(id1, lessThanOrEqualTo(2147483647));
      },
    );

    test(
      'Toggling off all reminders calls cancelAllNotifications and leaves zero active alarms',
      () async {
        final rem1 = Reminder(
          id: 'rem-1',
          title: 'Morning Workout',
          category: ReminderCategory.workout,
          timeOfDay: '07:00',
          isEnabled: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final rem2 = Reminder(
          id: 'rem-2',
          title: 'Evening Hydration',
          category: ReminderCategory.hydration,
          timeOfDay: '18:00',
          isEnabled: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.createReminder(rem1);
        await repository.createReminder(rem2);

        // Verify both are scheduled
        expect(notificationService.scheduledNotifications.length, equals(2));

        // Toggle off rem-1
        await repository.toggleEnabled('rem-1', false);
        expect(
          notificationService.scheduledNotifications.any(
            (item) => item.id == 'rem-1',
          ),
          isFalse,
        );
        expect(notificationService.scheduledNotifications.length, equals(1));

        // Toggle off rem-2 (all reminders are now disabled)
        await repository.toggleEnabled('rem-2', false);
        // All items must be completely empty
        expect(notificationService.scheduledNotifications, isEmpty);
      },
    );

    test(
      'reconcileSchedules cancels all alarms when master notification toggle is disabled',
      () async {
        final rem = Reminder(
          id: 'rem-active-1',
          title: 'Post-workout Protein',
          category: ReminderCategory.meal,
          timeOfDay: '12:30',
          isEnabled: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await repository.createReminder(rem);
        expect(notificationService.scheduledNotifications.length, equals(1));

        // User disables all notifications via master switch
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('notification_master_enabled', false);

        await repository.reconcileSchedules();

        // Everything must be cancelled
        expect(notificationService.scheduledNotifications, isEmpty);
      },
    );

    test(
      'reconcileSchedules cancels category when specific category is disabled in settings',
      () async {
        final workoutRem = Reminder(
          id: 'workout-rem-1',
          title: 'Leg Day Session',
          category: ReminderCategory.workout,
          timeOfDay: '08:00',
          isEnabled: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final mealRem = Reminder(
          id: 'meal-rem-1',
          title: 'Lunch Timing',
          category: ReminderCategory.meal,
          timeOfDay: '13:00',
          isEnabled: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.createReminder(workoutRem);
        await repository.createReminder(mealRem);
        expect(notificationService.scheduledNotifications.length, equals(2));

        // Disable workouts in preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('notification_workouts_enabled', false);

        await repository.reconcileSchedules();

        // Workout reminder must be cancelled; meal reminder remains active
        expect(
          notificationService.scheduledNotifications.any(
            (item) => item.id == 'workout-rem-1',
          ),
          isFalse,
        );
        expect(
          notificationService.scheduledNotifications.any(
            (item) => item.id == 'meal-rem-1',
          ),
          isTrue,
        );
      },
    );

    test(
      'reconcileSchedules cleans up previously scheduled alarms when all reminders in DB are disabled',
      () async {
        final rem = Reminder(
          id: 'rem-toggle-test',
          title: 'Nightly Sleep cutoff',
          category: ReminderCategory.sleep,
          timeOfDay: '22:30',
          isEnabled: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await repository.createReminder(rem);
        expect(notificationService.scheduledNotifications.length, equals(1));

        // Simulate reminder disabled directly in DB or via another session
        await (database.update(database.reminders)
              ..where((t) => t.id.equals(rem.id)))
            .write(const db.RemindersCompanion(isEnabled: drift.Value(false)));

        // Reconcile must detect 0 active reminders and cancel everything
        await repository.reconcileSchedules();
        expect(notificationService.scheduledNotifications, isEmpty);
      },
    );

    test(
      'deleteReminder cancels all notifications when remaining active reminders are empty',
      () async {
        final rem = Reminder(
          id: 'rem-to-delete',
          title: 'Daily Streak Habit',
          category: ReminderCategory.habit,
          timeOfDay: '19:00',
          isEnabled: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await repository.createReminder(rem);
        expect(notificationService.scheduledNotifications.length, equals(1));

        await repository.deleteReminder(rem.id);
        expect(notificationService.scheduledNotifications, isEmpty);
      },
    );
  });
}
