import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database.dart' hide Reminder;
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import '../sync/sync_utils.dart';
import '../../features/reminders/domain/models/reminder.dart';
import '../../features/reminders/data/repositories/reminder_repository.dart';

export '../../features/reminders/domain/models/reminder.dart';
export '../../features/reminders/data/repositories/reminder_repository.dart';

class LocalReminderRepository implements ReminderRepository {
  final AppDatabase db;
  final ReminderRepositoryImpl _impl;

  LocalReminderRepository(this.db, NotificationService notificationService)
      : _impl = ReminderRepositoryImpl(db, notificationService);

  @override
  Stream<List<Reminder>> watchAllReminders() => _impl.watchAllReminders();

  @override
  Stream<List<Reminder>> watchActiveReminders() => _impl.watchActiveReminders();

  @override
  Future<List<Reminder>> getAllReminders() => _impl.getAllReminders();

  @override
  Future<Reminder?> getReminder(String id) => _impl.getReminder(id);

  @override
  Future<void> createReminder(Reminder reminder) => _impl.createReminder(reminder);

  @override
  Future<void> updateReminder(Reminder reminder) => _impl.updateReminder(reminder);

  @override
  Future<void> deleteReminder(String id) => _impl.deleteReminder(id);

  @override
  Future<void> toggleEnabled(String id, bool isEnabled) =>
      _impl.toggleEnabled(id, isEnabled);

  @override
  Future<void> snoozeReminder(String id, int minutes) =>
      _impl.snoozeReminder(id, minutes);

  @override
  Future<void> completeReminder(String id) => _impl.completeReminder(id);

  @override
  Future<void> uncompleteReminder(String id) => _impl.uncompleteReminder(id);

  @override
  Future<void> dismissReminder(String id) => _impl.dismissReminder(id);

  @override
  Future<void> cleanDemoSeededReminders() => _impl.cleanDemoSeededReminders();

  @override
  Future<void> clearAllReminders() => _impl.clearAllReminders();
}

class CloudReminderRepository implements ReminderRepository {
  final AppDatabase db;
  final SupabaseClient? supabase;
  final String userId;
  final LocalReminderRepository _local;

  CloudReminderRepository({
    required this.db,
    required this.userId,
    required NotificationService notificationService,
    this.supabase,
  }) : _local = LocalReminderRepository(db, notificationService);

  @override
  Stream<List<Reminder>> watchAllReminders() {
    _backgroundRefresh().ignore();
    return _local.watchAllReminders();
  }

  @override
  Stream<List<Reminder>> watchActiveReminders() {
    _backgroundRefresh().ignore();
    return _local.watchActiveReminders();
  }

  @override
  Future<List<Reminder>> getAllReminders() => _local.getAllReminders();

  @override
  Future<Reminder?> getReminder(String id) => _local.getReminder(id);

  @override
  Future<void> createReminder(Reminder reminder) async {
    await _local.createReminder(reminder);
    await _uploadReminder(reminder);
  }

  @override
  Future<void> updateReminder(Reminder reminder) async {
    await _local.updateReminder(reminder);
    await _uploadReminder(reminder);
  }

  @override
  Future<void> deleteReminder(String id) async {
    await _local.deleteReminder(id);

    // Only attempt cloud deletion if authenticated with valid UUID
    if (!isValidUuid(userId)) {
      return;
    }

    if (supabase != null) {
      try {
        await supabase!.from('reminders').update({
          'is_deleted': true,
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).match({'id': id, 'user_id': userId});
        return;
      } catch (_) {}
    }

    await db.into(db.syncQueue).insertOnConflictUpdate(
          SyncQueueCompanion.insert(
            id: 'delete_reminder_$id',
            userId: drift.Value(userId),
            entityType: 'reminders',
            entityId: id,
            operation: 'DELETE',
            payload: jsonEncode({'id': id, 'user_id': userId}),
            createdAt: DateTime.now().toUtc(),
            clientTimestamp: drift.Value(DateTime.now().toUtc()),
            status: const drift.Value('queued'),
          ),
        );
  }

  @override
  Future<void> toggleEnabled(String id, bool isEnabled) async {
    await _local.toggleEnabled(id, isEnabled);
    final r = await _local.getReminder(id);
    if (r != null) await _uploadReminder(r);
  }

  @override
  Future<void> snoozeReminder(String id, int minutes) =>
      _local.snoozeReminder(id, minutes);

  @override
  Future<void> completeReminder(String id) => _local.completeReminder(id);

  @override
  Future<void> uncompleteReminder(String id) => _local.uncompleteReminder(id);

  @override
  Future<void> dismissReminder(String id) => _local.dismissReminder(id);

  @override
  Future<void> cleanDemoSeededReminders() => _local.cleanDemoSeededReminders();

  @override
  Future<void> clearAllReminders() => _local.clearAllReminders();

  Future<void> _uploadReminder(Reminder r) async {
    // Only attempt cloud upload if authenticated with valid UUID
    if (!isValidUuid(userId)) {
      return;
    }

    final payload = {
      'id': r.id,
      'user_id': userId,
      'title': r.title,
      'category': r.category.name,
      'time_of_day': r.timeOfDay,
      'is_enabled': r.isEnabled,
      'recurrence': r.recurrence.name,
      'repeat_days': r.repeatDays.join(','),
      'sound_enabled': r.soundEnabled,
      'vibration_enabled': r.vibrationEnabled,
      'snooze_duration_minutes': r.snoozeDurationMinutes,
      'last_triggered_at': r.lastTriggeredAt?.toUtc().toIso8601String(),
      'last_completed_at': r.lastCompletedAt?.toUtc().toIso8601String(),
      'is_dismissed': r.isDismissed,
      'created_at': r.createdAt.toUtc().toIso8601String(),
      'updated_at': r.updatedAt.toUtc().toIso8601String(),
    };

    if (supabase != null) {
      try {
        await supabase!.from('reminders').upsert(payload, onConflict: 'id');
        return;
      } catch (e) {
        debugPrint('[CloudReminderRepository] Write error: $e');
      }
    }

    await db.into(db.syncQueue).insertOnConflictUpdate(
          SyncQueueCompanion.insert(
            id: 'sync_reminder_${r.id}',
            userId: drift.Value(userId),
            entityType: 'reminders',
            entityId: r.id,
            operation: 'upsert',
            payload: jsonEncode(payload),
            createdAt: DateTime.now().toUtc(),
            clientTimestamp: drift.Value(DateTime.now().toUtc()),
            status: const drift.Value('queued'),
          ),
        );
  }

  Future<void> _backgroundRefresh() async {
    if (supabase == null) return;
    try {
      final rows = await supabase!
          .from('reminders')
          .select()
          .match({'user_id': userId})
          .isFilter('deleted_at', null);

      for (final r in rows) {
        await db.into(db.reminders).insertOnConflictUpdate(
              RemindersCompanion.insert(
                id: r['id'] as String,
                userId: drift.Value(userId),
                title: r['title'] as String,
                category: r['category'] as String,
                timeOfDay: r['time_of_day'] as String,
                isEnabled: drift.Value(r['is_enabled'] as bool? ?? true),
                recurrence: drift.Value(r['recurrence'] as String? ?? 'daily'),
                repeatDays: drift.Value(r['repeat_days'] as String?),
                soundEnabled: drift.Value(r['sound_enabled'] as bool? ?? true),
                vibrationEnabled: drift.Value(r['vibration_enabled'] as bool? ?? true),
                snoozeDurationMinutes: drift.Value(r['snooze_duration_minutes'] as int? ?? 10),
                isDismissed: drift.Value(r['is_dismissed'] as bool? ?? false),
                createdAt: DateTime.parse(r['created_at'] as String),
                updatedAt: DateTime.parse(r['updated_at'] as String),
                syncStatus: const drift.Value('synced'),
              ),
            );
      }
    } catch (_) {}
  }
}

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final status = ref.watch(authProvider).status;
  final db = ref.watch(databaseProvider);
  final notificationService = ref.watch(notificationServiceProvider);

  if (status == AuthStatus.authenticated) {
    final user = ref.watch(authProvider).user;
    if (user != null) {
      SupabaseClient? client;
      try {
        client = Supabase.instance.client;
      } catch (_) {}
      return CloudReminderRepository(
        db: db,
        userId: user.id,
        notificationService: notificationService,
        supabase: client,
      );
    }
  }

  return LocalReminderRepository(db, notificationService);
});
