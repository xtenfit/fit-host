import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database.dart' as db;
import '../../../../core/services/notification_service.dart';
import '../../../workouts/presentation/controllers/workout_providers.dart';
import '../../domain/models/reminder.dart';

abstract class ReminderRepository {
  Stream<List<Reminder>> watchAllReminders();
  Stream<List<Reminder>> watchActiveReminders();
  Future<List<Reminder>> getAllReminders();
  Future<Reminder?> getReminder(String id);
  Future<void> createReminder(Reminder reminder);
  Future<void> updateReminder(Reminder reminder);
  Future<void> deleteReminder(String id);
  Future<void> toggleEnabled(String id, bool isEnabled);
  Future<void> snoozeReminder(String id, int minutes);
  Future<void> completeReminder(String id);
  Future<void> dismissReminder(String id);
  Future<void> seedInitialReminders();
}

class ReminderRepositoryImpl implements ReminderRepository {
  final db.AppDatabase _db;
  final NotificationService _notificationService;
  final _uuid = const Uuid();

  ReminderRepositoryImpl(this._db, this._notificationService);

  @override
  Stream<List<Reminder>> watchAllReminders() {
    return (_db.select(_db.reminders)
          ..orderBy([
            (t) => drift.OrderingTerm(expression: t.timeOfDay, mode: drift.OrderingMode.asc),
            (t) => drift.OrderingTerm(expression: t.createdAt, mode: drift.OrderingMode.asc),
          ]))
        .watch()
        .map((rows) => rows.map((r) => Reminder.fromDb(r)).toList());
  }

  @override
  Stream<List<Reminder>> watchActiveReminders() {
    return (_db.select(_db.reminders)
          ..where((t) => t.isEnabled.equals(true))
          ..orderBy([
            (t) => drift.OrderingTerm(expression: t.timeOfDay, mode: drift.OrderingMode.asc),
          ]))
        .watch()
        .map((rows) => rows.map((r) => Reminder.fromDb(r)).toList());
  }

  @override
  Future<List<Reminder>> getAllReminders() async {
    final rows = await (_db.select(_db.reminders)
          ..orderBy([
            (t) => drift.OrderingTerm(expression: t.timeOfDay, mode: drift.OrderingMode.asc),
          ]))
        .get();
    return rows.map((r) => Reminder.fromDb(r)).toList();
  }

  @override
  Future<Reminder?> getReminder(String id) async {
    final row = await (_db.select(_db.reminders)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row != null ? Reminder.fromDb(row) : null;
  }

  NotificationChannelType _channelForCategory(ReminderCategory cat) {
    switch (cat) {
      case ReminderCategory.workout:
        return NotificationChannelType.workouts;
      case ReminderCategory.meal:
        return NotificationChannelType.nutrition;
      case ReminderCategory.hydration:
        return NotificationChannelType.hydration;
      case ReminderCategory.sleep:
        return NotificationChannelType.recovery;
      case ReminderCategory.habit:
      case ReminderCategory.custom:
        return NotificationChannelType.habits;
    }
  }

  Future<void> _scheduleNotificationForReminder(Reminder reminder) async {
    if (!reminder.isEnabled) {
      await _notificationService.cancelNotification(reminder.id);
      return;
    }

    final now = DateTime.now();
    final nextTime = reminder.nextOccurrence(now);

    await _notificationService.scheduleNotification(
      id: reminder.id,
      title: reminder.title,
      body: 'Time for ${reminder.title} (${reminder.category.label})',
      scheduledTime: nextTime,
      channel: _channelForCategory(reminder.category),
      payload: '/reminders',
      sound: reminder.soundEnabled,
      vibration: reminder.vibrationEnabled,
    );
  }

  @override
  Future<void> createReminder(Reminder reminder) async {
    final existing = await (_db.select(_db.reminders)
          ..where((t) => t.title.equals(reminder.title) & t.timeOfDay.equals(reminder.timeOfDay)))
        .getSingleOrNull();

    if (existing != null) {
      final updated = reminder.copyWith(id: existing.id, updatedAt: DateTime.now());
      await updateReminder(updated);
      return;
    }

    await _db.into(_db.reminders).insertOnConflictUpdate(reminder.toCompanion());
    await _scheduleNotificationForReminder(reminder);
  }

  @override
  Future<void> updateReminder(Reminder reminder) async {
    final updated = reminder.copyWith(updatedAt: DateTime.now());
    await (_db.update(_db.reminders)..where((t) => t.id.equals(reminder.id)))
        .write(updated.toCompanion());
    await _scheduleNotificationForReminder(updated);
  }

  @override
  Future<void> deleteReminder(String id) async {
    await (_db.delete(_db.reminders)..where((t) => t.id.equals(id))).go();
    await _notificationService.cancelNotification(id);
  }

  @override
  Future<void> toggleEnabled(String id, bool isEnabled) async {
    await (_db.update(_db.reminders)..where((t) => t.id.equals(id))).write(
      db.RemindersCompanion(
        isEnabled: drift.Value(isEnabled),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );

    final rem = await getReminder(id);
    if (rem != null) {
      await _scheduleNotificationForReminder(rem);
    }
  }

  @override
  Future<void> snoozeReminder(String id, int minutes) async {
    await _notificationService.snoozeNotification(id, minutes);
    await (_db.update(_db.reminders)..where((t) => t.id.equals(id))).write(
      db.RemindersCompanion(
        lastTriggeredAt: drift.Value(DateTime.now()),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> completeReminder(String id) async {
    await (_db.update(_db.reminders)..where((t) => t.id.equals(id))).write(
      db.RemindersCompanion(
        lastCompletedAt: drift.Value(DateTime.now()),
        isDismissed: const drift.Value(false),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );

    final rem = await getReminder(id);
    if (rem != null && rem.recurrence == ReminderRecurrence.once) {
      await toggleEnabled(id, false);
    } else if (rem != null) {
      await _scheduleNotificationForReminder(rem);
    }
  }

  @override
  Future<void> dismissReminder(String id) async {
    await (_db.update(_db.reminders)..where((t) => t.id.equals(id))).write(
      db.RemindersCompanion(
        isDismissed: const drift.Value(true),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
    await _notificationService.cancelNotification(id);
  }

  @override
  Future<void> seedInitialReminders() async {
    final count = await _db.customSelect(
      'SELECT COUNT(*) as c FROM reminders',
      readsFrom: {_db.reminders},
    ).getSingle();

    final total = count.read<int>('c');
    if (total > 0) return;

    final now = DateTime.now();

    final initial = [
      Reminder(
        id: _uuid.v4(),
        title: 'Morning Electrolyte Water',
        category: ReminderCategory.hydration,
        timeOfDay: '07:30',
        isEnabled: true,
        recurrence: ReminderRecurrence.daily,
        soundEnabled: true,
        vibrationEnabled: true,
        snoozeDurationMinutes: 10,
        createdAt: now,
        updatedAt: now,
      ),
      Reminder(
        id: _uuid.v4(),
        title: 'Mid-Day High-Protein Lunch',
        category: ReminderCategory.meal,
        timeOfDay: '12:30',
        isEnabled: true,
        recurrence: ReminderRecurrence.daily,
        soundEnabled: true,
        vibrationEnabled: true,
        snoozeDurationMinutes: 15,
        createdAt: now,
        updatedAt: now,
      ),
      Reminder(
        id: _uuid.v4(),
        title: 'Afternoon Workout Session',
        category: ReminderCategory.workout,
        timeOfDay: '17:30',
        isEnabled: true,
        recurrence: ReminderRecurrence.weekdays,
        repeatDays: [1, 2, 3, 4, 5],
        soundEnabled: true,
        vibrationEnabled: true,
        snoozeDurationMinutes: 15,
        createdAt: now,
        updatedAt: now,
      ),
      Reminder(
        id: _uuid.v4(),
        title: 'Evening Hydration Check',
        category: ReminderCategory.hydration,
        timeOfDay: '19:45',
        isEnabled: true,
        recurrence: ReminderRecurrence.daily,
        soundEnabled: true,
        vibrationEnabled: true,
        snoozeDurationMinutes: 10,
        createdAt: now,
        updatedAt: now,
      ),
      Reminder(
        id: _uuid.v4(),
        title: 'Sleep Wind-Down & Dim Screens',
        category: ReminderCategory.sleep,
        timeOfDay: '22:15',
        isEnabled: true,
        recurrence: ReminderRecurrence.daily,
        soundEnabled: true,
        vibrationEnabled: true,
        snoozeDurationMinutes: 30,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    for (final r in initial) {
      await createReminder(r);
    }
  }
}

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final dbInstance = ref.watch(databaseProvider);
  final notif = ref.watch(notificationServiceProvider);
  final repo = ReminderRepositoryImpl(dbInstance, notif);
  repo.seedInitialReminders();
  return repo;
});
