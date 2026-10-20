import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart' as db hide CalendarEvent;
import '../../domain/models/calendar_event.dart';

abstract class CalendarRepository {
  Stream<List<CalendarEvent>> watchAllEvents();
  Stream<List<CalendarEvent>> watchEventsForDate(DateTime date);
  Stream<List<CalendarEvent>> watchEventsForMonth(DateTime month);
  Future<List<CalendarEvent>> getEventsForDate(DateTime date);
  Future<void> createEvent(CalendarEvent event);
  Future<void> updateEvent(CalendarEvent event);
  Future<void> deleteEvent(String id);
  Future<void> toggleCompletion(String id, bool isCompleted);
  Future<void> rescheduleEvent(String id, DateTime newDate, DateTime? newStartTime);
  Future<void> clearAllEvents();
  Future<void> cleanDemoSeededEvents();
}

class CalendarRepositoryImpl implements CalendarRepository {
  final db.AppDatabase _db;

  CalendarRepositoryImpl(this._db) {
    cleanDemoSeededEvents();
  }

  @override
  Stream<List<CalendarEvent>> watchAllEvents() {
    return (_db.select(_db.calendarEvents)
          ..orderBy([
            (t) => drift.OrderingTerm(expression: t.scheduledDate, mode: drift.OrderingMode.asc),
            (t) => drift.OrderingTerm(expression: t.startTime, mode: drift.OrderingMode.asc),
          ]))
        .watch()
        .map((rows) => rows.map((r) => CalendarEvent.fromDb(r)).toList());
  }

  @override
  Stream<List<CalendarEvent>> watchEventsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return (_db.select(_db.calendarEvents)
          ..where((t) => t.scheduledDate.isBiggerOrEqualValue(startOfDay) &
              t.scheduledDate.isSmallerOrEqualValue(endOfDay))
          ..orderBy([
            (t) => drift.OrderingTerm(expression: t.startTime, mode: drift.OrderingMode.asc),
            (t) => drift.OrderingTerm(expression: t.createdAt, mode: drift.OrderingMode.asc),
          ]))
        .watch()
        .map((rows) => rows.map((r) => CalendarEvent.fromDb(r)).toList());
  }

  @override
  Stream<List<CalendarEvent>> watchEventsForMonth(DateTime month) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    return (_db.select(_db.calendarEvents)
          ..where((t) => t.scheduledDate.isBiggerOrEqualValue(startOfMonth) &
              t.scheduledDate.isSmallerOrEqualValue(endOfMonth))
          ..orderBy([
            (t) => drift.OrderingTerm(expression: t.scheduledDate, mode: drift.OrderingMode.asc),
          ]))
        .watch()
        .map((rows) => rows.map((r) => CalendarEvent.fromDb(r)).toList());
  }

  @override
  Future<List<CalendarEvent>> getEventsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final rows = await (_db.select(_db.calendarEvents)
          ..where((t) => t.scheduledDate.isBiggerOrEqualValue(startOfDay) &
              t.scheduledDate.isSmallerOrEqualValue(endOfDay))
          ..orderBy([
            (t) => drift.OrderingTerm(expression: t.startTime, mode: drift.OrderingMode.asc),
          ]))
        .get();

    return rows.map((r) => CalendarEvent.fromDb(r)).toList();
  }

  @override
  Future<void> createEvent(CalendarEvent event) async {
    await _db.into(_db.calendarEvents).insertOnConflictUpdate(event.toCompanion());
  }

  @override
  Future<void> updateEvent(CalendarEvent event) async {
    final updated = event.copyWith(updatedAt: DateTime.now());
    await (_db.update(_db.calendarEvents)..where((t) => t.id.equals(event.id)))
        .write(updated.toCompanion());
  }

  @override
  Future<void> deleteEvent(String id) async {
    await (_db.delete(_db.calendarEvents)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> toggleCompletion(String id, bool isCompleted) async {
    await (_db.update(_db.calendarEvents)..where((t) => t.id.equals(id))).write(
      db.CalendarEventsCompanion(
        isCompleted: drift.Value(isCompleted),
        isMissed: drift.Value(!isCompleted && false),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> rescheduleEvent(String id, DateTime newDate, DateTime? newStartTime) async {
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

    await (_db.update(_db.calendarEvents)..where((t) => t.id.equals(id))).write(
      db.CalendarEventsCompanion(
        scheduledDate: drift.Value(normalizedDate),
        startTime: drift.Value(updatedStartTime),
        isMissed: const drift.Value(false),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> cleanDemoSeededEvents() async {
    try {
      await _db.customStatement(
        "DELETE FROM calendar_events WHERE title IN ('Upper Body Hypertrophy', 'Post-Workout High Protein Fuel', 'Daily Hydration Target', 'Lower Body & Core Blast', 'Active Recovery & Mobility', 'Weekly Bodyweight & Composition Check', 'Sleep Wind-Down & Blue Light Cutoff')",
      );
    } catch (_) {}
  }

  @override
  Future<void> clearAllEvents() async {
    await _db.delete(_db.calendarEvents).go();
  }
}

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  final dbInstance = ref.watch(db.databaseProvider);
  return CalendarRepositoryImpl(dbInstance);
});
