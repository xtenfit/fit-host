import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/database/database.dart' as db hide Reminder;
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/supabase_service.dart';
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
  Future<void> reconcileSchedules();
}

class ReminderRepositoryImpl implements ReminderRepository {
  final db.AppDatabase _db;
  final NotificationService _notificationService;
  final String userId;

  ReminderRepositoryImpl(
    this._db,
    this._notificationService, {
    this.userId = 'guest',
  }) {
    cleanDemoSeededReminders();
  }

  @override
  Stream<List<Reminder>> watchAllReminders() {
    return (_db.select(_db.reminders)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))
          ..orderBy([
            (t) => drift.OrderingTerm(
              expression: t.timeOfDay,
              mode: drift.OrderingMode.asc,
            ),
            (t) => drift.OrderingTerm(
              expression: t.createdAt,
              mode: drift.OrderingMode.asc,
            ),
          ]))
        .watch()
        .map((rows) => rows.map((r) => Reminder.fromDb(r)).toList());
  }

  @override
  Stream<List<Reminder>> watchActiveReminders() {
    return (_db.select(_db.reminders)
          ..where(
            (t) =>
                t.userId.equals(userId) &
                t.isEnabled.equals(true) &
                t.isDeleted.equals(false),
          )
          ..orderBy([
            (t) => drift.OrderingTerm(
              expression: t.timeOfDay,
              mode: drift.OrderingMode.asc,
            ),
          ]))
        .watch()
        .map((rows) => rows.map((r) => Reminder.fromDb(r)).toList());
  }

  @override
  Future<List<Reminder>> getAllReminders() async {
    final rows =
        await (_db.select(_db.reminders)
              ..where(
                (t) => t.userId.equals(userId) & t.isDeleted.equals(false),
              )
              ..orderBy([
                (t) => drift.OrderingTerm(
                  expression: t.timeOfDay,
                  mode: drift.OrderingMode.asc,
                ),
              ]))
            .get();
    return rows.map((r) => Reminder.fromDb(r)).toList();
  }

  @override
  Future<Reminder?> getReminder(String id) async {
    final row =
        await (_db.select(_db.reminders)..where(
              (t) =>
                  t.id.equals(id) &
                  t.userId.equals(userId) &
                  t.isDeleted.equals(false),
            ))
            .getSingleOrNull();
    return row != null ? Reminder.fromDb(row) : null;
  }

  NotificationChannelType _channelForCategory(ReminderCategory category) {
    switch (category) {
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

    try {
      final prefs = await SharedPreferences.getInstance();
      final masterEnabled =
          prefs.getBool('notification_master_enabled') ?? true;
      if (!masterEnabled) {
        await _notificationService.cancelNotification(reminder.id);
        return;
      }

      bool categoryEnabled = true;
      switch (reminder.category) {
        case ReminderCategory.workout:
          categoryEnabled =
              prefs.getBool('notification_workouts_enabled') ?? true;
          break;
        case ReminderCategory.meal:
          categoryEnabled = prefs.getBool('notification_meals_enabled') ?? true;
          break;
        case ReminderCategory.hydration:
          categoryEnabled =
              prefs.getBool('notification_hydration_enabled') ?? true;
          break;
        case ReminderCategory.sleep:
          categoryEnabled =
              prefs.getBool('notification_recovery_enabled') ?? true;
          break;
        case ReminderCategory.habit:
        case ReminderCategory.custom:
          categoryEnabled =
              prefs.getBool('notification_habits_enabled') ?? true;
          break;
      }

      if (!categoryEnabled) {
        await _notificationService.cancelNotification(reminder.id);
        return;
      }
    } catch (_) {}

    final channel = _channelForCategory(reminder.category);
    final nextTime = reminder.nextOccurrence(DateTime.now());
    final body = '${reminder.category.label} • ${reminder.formattedTime}';

    if (reminder.deliveryMode == ReminderDeliveryMode.alarm) {
      await _notificationService.scheduleAlarm(
        id: reminder.id,
        title: reminder.title,
        body: body,
        scheduledTime: nextTime,
        channel: channel,
        snoozeMinutes: reminder.snoozeDurationMinutes,
        sound: reminder.soundEnabled,
        vibration: reminder.vibrationEnabled,
      );
    } else {
      await _notificationService.scheduleNotification(
        id: reminder.id,
        title: reminder.title,
        body: body,
        scheduledTime: nextTime,
        channel: channel,
        snoozeMinutes: reminder.snoozeDurationMinutes,
        sound: reminder.soundEnabled,
        vibration: reminder.vibrationEnabled,
      );
    }
  }

  @override
  Future<void> createReminder(Reminder reminder) async {
    final existing =
        await (_db.select(_db.reminders)..where(
              (t) =>
                  t.userId.equals(userId) &
                  t.title.equals(reminder.title) &
                  t.timeOfDay.equals(reminder.timeOfDay) &
                  t.isDeleted.equals(false),
            ))
            .getSingleOrNull();

    if (existing != null) {
      final updated = reminder.copyWith(
        id: existing.id,
        updatedAt: DateTime.now(),
      );
      await updateReminder(updated);
      return;
    }

    await _db
        .into(_db.reminders)
        .insertOnConflictUpdate(reminder.toCompanion(userId: userId));
    await _scheduleNotificationForReminder(reminder);
  }

  @override
  Future<void> updateReminder(Reminder reminder) async {
    final updated = reminder.copyWith(updatedAt: DateTime.now());
    await (_db.update(_db.reminders)
          ..where((t) => t.id.equals(reminder.id) & t.userId.equals(userId)))
        .write(updated.toCompanion(userId: userId));
    await _scheduleNotificationForReminder(updated);
  }

  @override
  Future<void> deleteReminder(String id) async {
    await (_db.update(
      _db.reminders,
    )..where((t) => t.id.equals(id) & t.userId.equals(userId))).write(
      db.RemindersCompanion(
        isDeleted: const drift.Value(true),
        deletedAt: drift.Value(DateTime.now()),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
    await _notificationService.cancelNotification(id);

    final remainingActive =
        await (_db.select(_db.reminders)..where(
              (t) =>
                  t.userId.equals(userId) &
                  t.isEnabled.equals(true) &
                  t.isDeleted.equals(false),
            ))
            .get();
    if (remainingActive.isEmpty) {
      await _notificationService.cancelAllNotifications();
    }
  }

  @override
  Future<void> toggleEnabled(String id, bool isEnabled) async {
    await (_db.update(
      _db.reminders,
    )..where((t) => t.id.equals(id) & t.userId.equals(userId))).write(
      db.RemindersCompanion(
        isEnabled: drift.Value(isEnabled),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );

    if (!isEnabled) {
      await _notificationService.cancelNotification(id);
    } else {
      final rem = await getReminder(id);
      if (rem != null) {
        await _scheduleNotificationForReminder(rem);
      }
    }

    final remainingActive =
        await (_db.select(_db.reminders)..where(
              (t) =>
                  t.userId.equals(userId) &
                  t.isEnabled.equals(true) &
                  t.isDeleted.equals(false),
            ))
            .get();
    if (remainingActive.isEmpty) {
      await _notificationService.cancelAllNotifications();
    }
  }

  @override
  Future<void> snoozeReminder(String id, int minutes) async {
    final reminder = await getReminder(id);
    if (reminder != null) {
      final snoozedTime = DateTime.now().add(Duration(minutes: minutes));
      final channel = _channelForCategory(reminder.category);
      final body = 'Snoozed (${minutes}m) • ${reminder.category.label}';
      if (reminder.deliveryMode == ReminderDeliveryMode.alarm) {
        await _notificationService.scheduleAlarm(
          id: id,
          title: reminder.title,
          body: body,
          scheduledTime: snoozedTime,
          channel: channel,
          snoozeMinutes: minutes,
          sound: reminder.soundEnabled,
          vibration: reminder.vibrationEnabled,
        );
      } else {
        await _notificationService.scheduleNotification(
          id: id,
          title: reminder.title,
          body: body,
          scheduledTime: snoozedTime,
          channel: channel,
          snoozeMinutes: minutes,
          sound: reminder.soundEnabled,
          vibration: reminder.vibrationEnabled,
        );
      }
    } else {
      await _notificationService.snoozeNotification(id, minutes);
    }

    await (_db.update(
      _db.reminders,
    )..where((t) => t.id.equals(id) & t.userId.equals(userId))).write(
      db.RemindersCompanion(
        lastTriggeredAt: drift.Value(DateTime.now()),
        isDismissed: const drift.Value(false),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> completeReminder(String id) async {
    // 1. Mark completed in database
    await (_db.update(
      _db.reminders,
    )..where((t) => t.id.equals(id) & t.userId.equals(userId))).write(
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
    await (_db.update(
      _db.reminders,
    )..where((t) => t.id.equals(id) & t.userId.equals(userId))).write(
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
    await (_db.update(
      _db.reminders,
    )..where((t) => t.id.equals(id) & t.userId.equals(userId))).write(
      db.RemindersCompanion(
        isDismissed: const drift.Value(true),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
    await _notificationService.cancelNotification(id);

    final rem = await getReminder(id);
    if (rem != null &&
        rem.isEnabled &&
        rem.recurrence != ReminderRecurrence.once) {
      await _scheduleNotificationForReminder(rem);
    }
  }

  @override
  Future<void> cleanDemoSeededReminders() async {
    try {
      await _db.customStatement(
        "DELETE FROM reminders WHERE user_id = '$userId' AND title IN ('Morning Electrolyte Water', 'Mid-Day High-Protein Lunch', 'Afternoon Workout Session', 'Evening Hydration Check', 'Sleep Wind-Down & Dim Screens')",
      );
    } catch (_) {}
  }

  @override
  Future<void> reconcileSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final masterEnabled =
          prefs.getBool('notification_master_enabled') ?? true;
      if (!masterEnabled) {
        await _notificationService.cancelAllNotifications();
        return;
      }

      final all = await (_db.select(
        _db.reminders,
      )..where((t) => t.userId.equals(userId))).get();

      final disabledOrDeleted = all
          .where((r) => !r.isEnabled || r.isDeleted)
          .toList();
      for (final r in disabledOrDeleted) {
        await _notificationService.cancelNotification(r.id);
      }

      final active = all.where((r) => r.isEnabled && !r.isDeleted).toList();
      if (active.isEmpty) {
        await _notificationService.cancelAllNotifications();
        return;
      }

      for (final r in active) {
        final reminder = Reminder.fromDb(r);
        await _scheduleNotificationForReminder(reminder);
      }
    } catch (_) {}
  }

  @override
  Future<void> clearAllReminders() async {
    try {
      final all = await getAllReminders();
      for (final r in all) {
        await _notificationService.cancelNotification(r.id);
      }
      await (_db.update(
        _db.reminders,
      )..where((t) => t.userId.equals(userId))).write(
        db.RemindersCompanion(
          isDeleted: const drift.Value(true),
          deletedAt: drift.Value(DateTime.now()),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
      await _notificationService.cancelAllNotifications();
    } catch (_) {}
  }
}

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final dbInstance = ref.watch(db.databaseProvider);
  final notif = ref.watch(notificationServiceProvider);
  final authState = ref.watch(authProvider);
  final user = authState.user;
  final userId = (authState.status == AuthStatus.authenticated && user != null)
      ? user.id
      : 'guest';
  return ReminderRepositoryImpl(dbInstance, notif, userId: userId);
});
