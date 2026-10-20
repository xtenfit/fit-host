import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database.dart' hide CalendarEvent;
import '../services/supabase_service.dart';
import '../sync/sync_utils.dart';
import '../../features/calendar/domain/models/calendar_event.dart';
import '../../features/calendar/data/repositories/calendar_repository.dart';

export '../../features/calendar/domain/models/calendar_event.dart';
export '../../features/calendar/data/repositories/calendar_repository.dart';

class LocalCalendarRepository implements CalendarRepository {
  final AppDatabase db;
  final CalendarRepositoryImpl _impl;

  LocalCalendarRepository(this.db) : _impl = CalendarRepositoryImpl(db);

  @override
  Stream<List<CalendarEvent>> watchAllEvents() => _impl.watchAllEvents();

  @override
  Stream<List<CalendarEvent>> watchEventsForDate(DateTime date) =>
      _impl.watchEventsForDate(date);

  @override
  Stream<List<CalendarEvent>> watchEventsForMonth(DateTime month) =>
      _impl.watchEventsForMonth(month);

  @override
  Future<List<CalendarEvent>> getEventsForDate(DateTime date) =>
      _impl.getEventsForDate(date);

  @override
  Future<void> createEvent(CalendarEvent event) => _impl.createEvent(event);

  @override
  Future<void> updateEvent(CalendarEvent event) => _impl.updateEvent(event);

  @override
  Future<void> deleteEvent(String id) => _impl.deleteEvent(id);

  @override
  Future<void> toggleCompletion(String id, bool isCompleted) =>
      _impl.toggleCompletion(id, isCompleted);

  @override
  Future<void> rescheduleEvent(String id, DateTime newDate, DateTime? newStartTime) =>
      _impl.rescheduleEvent(id, newDate, newStartTime);

  @override
  Future<void> clearAllEvents() => _impl.clearAllEvents();

  @override
  Future<void> cleanDemoSeededEvents() => _impl.cleanDemoSeededEvents();
}

class CloudCalendarRepository implements CalendarRepository {
  final AppDatabase db;
  final SupabaseClient? supabase;
  final String userId;
  final LocalCalendarRepository _local;

  CloudCalendarRepository({
    required this.db,
    required this.userId,
    this.supabase,
  }) : _local = LocalCalendarRepository(db);

  @override
  Stream<List<CalendarEvent>> watchAllEvents() {
    _backgroundRefresh().ignore();
    return _local.watchAllEvents();
  }

  @override
  Stream<List<CalendarEvent>> watchEventsForDate(DateTime date) {
    _backgroundRefresh().ignore();
    return _local.watchEventsForDate(date);
  }

  @override
  Stream<List<CalendarEvent>> watchEventsForMonth(DateTime month) {
    _backgroundRefresh().ignore();
    return _local.watchEventsForMonth(month);
  }

  @override
  Future<List<CalendarEvent>> getEventsForDate(DateTime date) =>
      _local.getEventsForDate(date);

  @override
  Future<void> createEvent(CalendarEvent event) async {
    await _local.createEvent(event);
    await _uploadEvent(event);
  }

  @override
  Future<void> updateEvent(CalendarEvent event) async {
    await _local.updateEvent(event);
    await _uploadEvent(event);
  }

  @override
  Future<void> deleteEvent(String id) async {
    await _local.deleteEvent(id);

    // Only attempt cloud deletion if authenticated with valid UUID
    if (!isValidUuid(userId)) {
      return;
    }

    if (supabase != null) {
      try {
        await supabase!.from('calendar_events').update({
          'is_deleted': true,
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).match({'id': id, 'user_id': userId});
        return;
      } catch (_) {}
    }
    // Queue offline delete
    await db.into(db.syncQueue).insertOnConflictUpdate(
          SyncQueueCompanion.insert(
            id: 'delete_event_$id',
            userId: drift.Value(userId),
            entityType: 'calendar_events',
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
  Future<void> toggleCompletion(String id, bool isCompleted) async {
    await _local.toggleCompletion(id, isCompleted);
    final events = await _local.getEventsForDate(DateTime.now());
    final ev = events.firstWhere((e) => e.id == id, orElse: () => events.first);
    await _uploadEvent(ev.copyWith(isCompleted: isCompleted));
  }

  @override
  Future<void> rescheduleEvent(String id, DateTime newDate, DateTime? newStartTime) async {
    await _local.rescheduleEvent(id, newDate, newStartTime);
  }

  @override
  Future<void> clearAllEvents() => _local.clearAllEvents();

  @override
  Future<void> cleanDemoSeededEvents() => _local.cleanDemoSeededEvents();

  Future<void> _uploadEvent(CalendarEvent event) async {
    // Only attempt cloud upload if authenticated with valid UUID
    if (!isValidUuid(userId)) {
      return;
    }

    final payload = {
      'id': event.id,
      'user_id': userId,
      'title': event.title,
      'description': event.description,
      'event_type': event.eventType.name,
      'scheduled_date': event.scheduledDate.toIso8601String().substring(0, 10),
      'start_time': event.startTime?.toUtc().toIso8601String(),
      'end_time': event.endTime?.toUtc().toIso8601String(),
      'is_completed': event.isCompleted,
      'is_missed': event.isMissed,
      'recurrence_rule': event.recurrenceRule,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (supabase != null) {
      try {
        await supabase!.from('calendar_events').upsert(payload, onConflict: 'id');
        return;
      } catch (e) {
        debugPrint('[CloudCalendarRepository] Cloud write error: $e');
      }
    }

    await db.into(db.syncQueue).insertOnConflictUpdate(
          SyncQueueCompanion.insert(
            id: 'sync_event_${event.id}',
            userId: drift.Value(userId),
            entityType: 'calendar_events',
            entityId: event.id,
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
          .from('calendar_events')
          .select()
          .match({'user_id': userId})
          .isFilter('deleted_at', null);

      for (final r in rows) {
        await db.into(db.calendarEvents).insertOnConflictUpdate(
              CalendarEventsCompanion.insert(
                id: r['id'] as String,
                userId: drift.Value(userId),
                title: r['title'] as String,
                description: drift.Value(r['description'] as String?),
                eventType: r['event_type'] as String,
                scheduledDate: DateTime.parse(r['scheduled_date'] as String),
                startTime: drift.Value(r['start_time'] != null
                    ? DateTime.parse(r['start_time'] as String)
                    : null),
                endTime: drift.Value(r['end_time'] != null
                    ? DateTime.parse(r['end_time'] as String)
                    : null),
                isCompleted: drift.Value(r['is_completed'] as bool? ?? false),
                isMissed: drift.Value(r['is_missed'] as bool? ?? false),
                recurrenceRule: drift.Value(r['recurrence_rule'] as String? ?? 'none'),
                createdAt: DateTime.now(),
                updatedAt: DateTime.parse(r['updated_at'] as String),
                syncStatus: const drift.Value('synced'),
              ),
            );
      }
    } catch (_) {}
  }
}

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  final status = ref.watch(authProvider).status;
  final db = ref.watch(databaseProvider);

  if (status == AuthStatus.authenticated) {
    final user = ref.watch(authProvider).user;
    if (user != null) {
      SupabaseClient? client;
      try {
        client = Supabase.instance.client;
      } catch (_) {}
      return CloudCalendarRepository(
        db: db,
        userId: user.id,
        supabase: client,
      );
    }
  }

  return LocalCalendarRepository(db);
});
