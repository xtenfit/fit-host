import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart' as db hide CalendarEvent;
import '../../../../core/services/notification_service.dart';
import '../../domain/models/calendar_event.dart';
import '../services/google_calendar_service.dart';

abstract class CalendarRepository {
  Stream<List<CalendarEvent>> watchAllEvents();
  Stream<List<CalendarEvent>> watchEventsForDate(DateTime date);
  Stream<List<CalendarEvent>> watchEventsForMonth(DateTime month);
  Future<List<CalendarEvent>> getEventsForDate(DateTime date);
  Future<void> createEvent(CalendarEvent event);
  Future<void> updateEvent(CalendarEvent event);
  Future<void> deleteEvent(String id);
  Future<void> toggleCompletion(String id, bool isCompleted);
  Future<void> rescheduleEvent(
    String id,
    DateTime newDate,
    DateTime? newStartTime,
  );
  Future<void> syncPendingToGoogleCalendar();
  Future<void> clearAllEvents();
  Future<void> cleanDemoSeededEvents();
}

class CalendarRepositoryImpl implements CalendarRepository {
  final db.AppDatabase _db;
  final GoogleCalendarService? googleCalendarService;
  final NotificationService _notificationService;
  final String userId;

  GoogleCalendarService? get _googleCalendarService => googleCalendarService;

  CalendarRepositoryImpl(
    this._db, {
    this.googleCalendarService,
    NotificationService? notificationService,
    this.userId = 'guest',
  }) : _notificationService =
           notificationService ?? NotificationService.instance {
    cleanDemoSeededEvents();
  }

  NotificationChannelType _channelForType(CalendarEventType type) {
    switch (type) {
      case CalendarEventType.workout:
        return NotificationChannelType.workouts;
      case CalendarEventType.meal:
        return NotificationChannelType.nutrition;
      case CalendarEventType.hydration:
        return NotificationChannelType.hydration;
      case CalendarEventType.sleep:
        return NotificationChannelType.recovery;
      case CalendarEventType.restDay:
      case CalendarEventType.weighIn:
      case CalendarEventType.custom:
        return NotificationChannelType.habits;
    }
  }

  Future<void> _scheduleLocalReminder(CalendarEvent event) async {
    if (event.startTime == null || event.isCompleted) return;
    try {
      final notifId = 'cal_${event.id}';
      if (event.startTime!.isAfter(DateTime.now())) {
        await _notificationService.scheduleNotification(
          id: notifId,
          title: event.title,
          body: event.description ?? 'Scheduled ${event.eventType.label}',
          scheduledTime: event.startTime!,
          channel: _channelForType(event.eventType),
        );
      }
    } catch (e) {
      debugPrint(
        '[CalendarRepository] Local notification scheduling notice: $e',
      );
    }
  }

  Future<void> _cancelLocalReminder(String id) async {
    try {
      await _notificationService.cancelNotification('cal_$id');
    } catch (_) {}
  }

  @override
  Stream<List<CalendarEvent>> watchAllEvents() {
    return (_db.select(_db.calendarEvents)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([
            (t) => drift.OrderingTerm(
              expression: t.scheduledDate,
              mode: drift.OrderingMode.asc,
            ),
            (t) => drift.OrderingTerm(
              expression: t.startTime,
              mode: drift.OrderingMode.asc,
            ),
          ]))
        .watch()
        .map((rows) => rows.map((r) => CalendarEvent.fromDb(r)).toList());
  }

  @override
  Stream<List<CalendarEvent>> watchEventsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return (_db.select(_db.calendarEvents)
          ..where(
            (t) =>
                t.userId.equals(userId) &
                t.scheduledDate.isBiggerOrEqualValue(startOfDay) &
                t.scheduledDate.isSmallerOrEqualValue(endOfDay),
          )
          ..orderBy([
            (t) => drift.OrderingTerm(
              expression: t.startTime,
              mode: drift.OrderingMode.asc,
            ),
            (t) => drift.OrderingTerm(
              expression: t.createdAt,
              mode: drift.OrderingMode.asc,
            ),
          ]))
        .watch()
        .map((rows) => rows.map((r) => CalendarEvent.fromDb(r)).toList());
  }

  @override
  Stream<List<CalendarEvent>> watchEventsForMonth(DateTime month) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    return (_db.select(_db.calendarEvents)
          ..where(
            (t) =>
                t.userId.equals(userId) &
                t.scheduledDate.isBiggerOrEqualValue(startOfMonth) &
                t.scheduledDate.isSmallerOrEqualValue(endOfMonth),
          )
          ..orderBy([
            (t) => drift.OrderingTerm(
              expression: t.scheduledDate,
              mode: drift.OrderingMode.asc,
            ),
          ]))
        .watch()
        .map((rows) => rows.map((r) => CalendarEvent.fromDb(r)).toList());
  }

  @override
  Future<List<CalendarEvent>> getEventsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final rows =
        await (_db.select(_db.calendarEvents)
              ..where(
                (t) =>
                    t.userId.equals(userId) &
                    t.scheduledDate.isBiggerOrEqualValue(startOfDay) &
                    t.scheduledDate.isSmallerOrEqualValue(endOfDay),
              )
              ..orderBy([
                (t) => drift.OrderingTerm(
                  expression: t.startTime,
                  mode: drift.OrderingMode.asc,
                ),
              ]))
            .get();

    return rows.map((r) => CalendarEvent.fromDb(r)).toList();
  }

  @override
  Future<void> createEvent(CalendarEvent event) async {
    var eventToSave = event;

    // Try Google Calendar sync if connected and start/end times exist
    final gCal = _googleCalendarService;
    if (gCal != null &&
        gCal.currentState.isConnected &&
        event.startTime != null) {
      final endTime =
          event.endTime ?? event.startTime!.add(const Duration(minutes: 45));
      final gEventId = await gCal.createEvent(
        title: event.title,
        description: event.description,
        startTime: event.startTime!,
        endTime: endTime,
        idempotencyKey: event.id,
      );
      if (gEventId != null) {
        eventToSave = event
            .withGoogleEventId(gEventId)
            .copyWith(syncStatus: 'synced');
      }
    }

    await _db
        .into(_db.calendarEvents)
        .insertOnConflictUpdate(
          eventToSave.toCompanion().copyWith(userId: drift.Value(userId)),
        );
    await _scheduleLocalReminder(eventToSave);
  }

  @override
  Future<void> updateEvent(CalendarEvent event) async {
    final updated = event.copyWith(updatedAt: DateTime.now());

    // Update in Google Calendar if mapped
    final gCal = _googleCalendarService;
    if (gCal != null &&
        gCal.currentState.isConnected &&
        event.googleEventId != null &&
        event.startTime != null) {
      final endTime =
          event.endTime ?? event.startTime!.add(const Duration(minutes: 45));
      await gCal.updateEvent(
        googleEventId: event.googleEventId!,
        title: event.title,
        description: event.description,
        startTime: event.startTime!,
        endTime: endTime,
      );
    }

    await (_db.update(_db.calendarEvents)
          ..where((t) => t.id.equals(event.id) & t.userId.equals(userId)))
        .write(updated.toCompanion());
    await _scheduleLocalReminder(updated);
  }

  @override
  Future<void> deleteEvent(String id) async {
    final existingRow =
        await (_db.select(_db.calendarEvents)
              ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
            .getSingleOrNull();
    if (existingRow != null) {
      final event = CalendarEvent.fromDb(existingRow);
      final gCal = _googleCalendarService;
      if (event.googleEventId != null && gCal != null) {
        await gCal.deleteEvent(event.googleEventId!);
      }
    }

    await _cancelLocalReminder(id);
    await (_db.delete(
      _db.calendarEvents,
    )..where((t) => t.id.equals(id) & t.userId.equals(userId))).go();
  }

  @override
  Future<void> toggleCompletion(String id, bool isCompleted) async {
    await (_db.update(
      _db.calendarEvents,
    )..where((t) => t.id.equals(id) & t.userId.equals(userId))).write(
      db.CalendarEventsCompanion(
        isCompleted: drift.Value(isCompleted),
        isMissed: drift.Value(!isCompleted && false),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );

    if (isCompleted) {
      await _cancelLocalReminder(id);
    }
  }

  @override
  Future<void> rescheduleEvent(
    String id,
    DateTime newDate,
    DateTime? newStartTime,
  ) async {
    final normalizedDate = DateTime(newDate.year, newDate.month, newDate.day);
    DateTime? updatedStartTime;
    if (newStartTime != null) {
      updatedStartTime = DateTime(
        newDate.year,
        newDate.month,
        newDate.day,
        newStartTime.hour,
        newStartTime.minute,
      );
    }

    await (_db.update(
      _db.calendarEvents,
    )..where((t) => t.id.equals(id) & t.userId.equals(userId))).write(
      db.CalendarEventsCompanion(
        scheduledDate: drift.Value(normalizedDate),
        startTime: drift.Value(updatedStartTime),
        isMissed: const drift.Value(false),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );

    final row =
        await (_db.select(_db.calendarEvents)
              ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
            .getSingleOrNull();
    if (row != null) {
      final event = CalendarEvent.fromDb(row);
      final gCal = _googleCalendarService;
      if (event.googleEventId != null &&
          gCal != null &&
          updatedStartTime != null) {
        final endTime =
            event.endTime ?? updatedStartTime.add(const Duration(minutes: 45));
        await gCal.updateEvent(
          googleEventId: event.googleEventId!,
          title: event.title,
          description: event.description,
          startTime: updatedStartTime,
          endTime: endTime,
        );
      }
      await _scheduleLocalReminder(event);
    }
  }

  @override
  Future<void> syncPendingToGoogleCalendar() async {
    final gCal = _googleCalendarService;
    if (gCal == null || !gCal.currentState.isConnected) return;

    final unSynced =
        await (_db.select(_db.calendarEvents)..where(
              (t) =>
                  t.userId.equals(userId) &
                  (t.syncStatus.equals('pending') | t.syncStatus.isNull()),
            ))
            .get();

    for (final row in unSynced) {
      final event = CalendarEvent.fromDb(row);
      if (event.startTime != null && event.googleEventId == null) {
        final endTime =
            event.endTime ?? event.startTime!.add(const Duration(minutes: 45));
        final gId = await gCal.createEvent(
          title: event.title,
          description: event.description,
          startTime: event.startTime!,
          endTime: endTime,
          idempotencyKey: event.id,
        );
        if (gId != null) {
          final updated = event
              .withGoogleEventId(gId)
              .copyWith(syncStatus: 'synced');
          await updateEvent(updated);
        }
      }
    }
  }

  @override
  Future<void> cleanDemoSeededEvents() async {
    try {
      await _db.customStatement(
        "DELETE FROM calendar_events WHERE user_id = 'guest' AND title IN ('Upper Body Hypertrophy', 'Post-Workout High Protein Fuel', 'Daily Hydration Target', 'Lower Body & Core Blast', 'Active Recovery & Mobility', 'Weekly Bodyweight & Composition Check', 'Sleep Wind-Down & Blue Light Cutoff')",
      );
    } catch (_) {}
  }

  @override
  Future<void> clearAllEvents() async {
    await (_db.delete(
      _db.calendarEvents,
    )..where((t) => t.userId.equals(userId))).go();
  }
}

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  final dbInstance = ref.watch(db.databaseProvider);
  final gcalService = ref.watch(googleCalendarServiceProvider);
  return CalendarRepositoryImpl(dbInstance, googleCalendarService: gcalService);
});
