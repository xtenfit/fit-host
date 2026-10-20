import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart' as db hide Reminder;
import '../../../../core/services/notification_service.dart';
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
  Future<void> uncompleteReminder(String id);
  Future<void> dismissReminder(String id);
  Future<void> cleanDemoSeededReminders();
  Future<void> clearAllReminders();
}

class ReminderRepositoryImpl implements ReminderRepository {
  final db.AppDatabase _db;
  final NotificationService _notificationService;

  ReminderRepositoryImpl(this._db, this._notificationService) {
    cleanDemoSeededReminders();
  }

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

    // Schedule high-priority fullscreen alarm with category & payload for lock-screen popup
    await _notificationService.scheduleAlarm(
      id: reminder.id,
      title: reminder.title,
      body: 'Time for ${reminder.title} (${reminder.category.label})',
      scheduledTime: nextTime,
      channel: _channelForCategory(reminder.category),
      payload:
          '/alarm?id=${Uri.encodeComponent(reminder.id)}&title=${Uri.encodeComponent(reminder.title)}&body=${Uri.encodeComponent(reminder.category.label)}&channel=${_channelForCategory(reminder.category).name}&snoozeMinutes=${reminder.snoozeDurationMinutes}',
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
    // 1. Mark completed in database
    await (_db.update(_db.reminders)..where((t) => t.id.equals(id))).write(
      db.RemindersCompanion(
        lastCompletedAt: drift.Value(DateTime.now()),
        isDismissed: const drift.Value(false),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );

    // 2. Cancel today's active/pending alarm immediately so it stops ringing or does not fire later today
    await _notificationService.cancelNotification(id);

    // 3. For recurring reminders, schedule next occurrence (which automatically advances past today)
    final rem = await getReminder(id);
    if (rem != null && rem.recurrence == ReminderRecurrence.once) {
      await toggleEnabled(id, false);
    } else if (rem != null && rem.isEnabled) {
      await _scheduleNotificationForReminder(rem);
    }
  }

  @override
  Future<void> uncompleteReminder(String id) async {
    await (_db.update(_db.reminders)..where((t) => t.id.equals(id))).write(
      db.RemindersCompanion(
        lastCompletedAt: const drift.Value(null),
        isDismissed: const drift.Value(false),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );

    final rem = await getReminder(id);
    if (rem != null && rem.isEnabled) {
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
  Future<void> cleanDemoSeededReminders() async {
    try {
      await _db.customStatement(
        "DELETE FROM reminders WHERE title IN ('Morning Electrolyte Water', 'Mid-Day High-Protein Lunch', 'Afternoon Workout Session', 'Evening Hydration Check', 'Sleep Wind-Down & Dim Screens')",
      );
    } catch (_) {}
  }

  @override
  Future<void> clearAllReminders() async {
    try {
      final all = await getAllReminders();
      for (final r in all) {
        await _notificationService.cancelNotification(r.id);
      }
      await _db.delete(_db.reminders).go();
    } catch (_) {}
  }
}

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final dbInstance = ref.watch(db.databaseProvider);
  final notif = ref.watch(notificationServiceProvider);
  return ReminderRepositoryImpl(dbInstance, notif);
});
