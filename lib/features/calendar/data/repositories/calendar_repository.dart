import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database.dart' as db;
import '../../../workouts/presentation/controllers/workout_providers.dart';
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
  Future<void> seedInitialCalendarEvents();
}

class CalendarRepositoryImpl implements CalendarRepository {
  final db.AppDatabase _db;
  final _uuid = const Uuid();

  CalendarRepositoryImpl(this._db);

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
  Future<void> seedInitialCalendarEvents() async {
    final count = await _db.customSelect(
      'SELECT COUNT(*) as c FROM calendar_events',
      readsFrom: {_db.calendarEvents},
    ).getSingle();

    final total = count.read<int>('c');
    if (total > 0) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final initialEvents = [
      CalendarEvent(
        id: _uuid.v4(),
        title: 'Upper Body Hypertrophy',
        description: 'Chest, Shoulders & Triceps progressive overload session',
        eventType: CalendarEventType.workout,
        scheduledDate: today,
        startTime: DateTime(today.year, today.month, today.day, 17, 30),
        endTime: DateTime(today.year, today.month, today.day, 18, 30),
        isCompleted: false,
        recurrenceRule: RecurrenceRule.weekdays,
        targetMetrics: {'targetDurationMinutes': 60, 'targetCalories': 450},
        createdAt: now,
        updatedAt: now,
      ),
      CalendarEvent(
        id: _uuid.v4(),
        title: 'Post-Workout High Protein Fuel',
        description: 'Grilled salmon, brown rice & steamed broccoli (45g protein)',
        eventType: CalendarEventType.meal,
        scheduledDate: today,
        startTime: DateTime(today.year, today.month, today.day, 19, 0),
        endTime: DateTime(today.year, today.month, today.day, 19, 30),
        isCompleted: false,
        recurrenceRule: RecurrenceRule.daily,
        targetMetrics: {'calories': 680, 'proteinGrams': 45},
        createdAt: now,
        updatedAt: now,
      ),
      CalendarEvent(
        id: _uuid.v4(),
        title: 'Daily Hydration Target',
        description: '3.5 Liters electrolyte-infused water',
        eventType: CalendarEventType.hydration,
        scheduledDate: today,
        startTime: DateTime(today.year, today.month, today.day, 9, 0),
        isCompleted: true,
        recurrenceRule: RecurrenceRule.daily,
        targetMetrics: {'targetMl': 3500, 'currentMl': 3500},
        createdAt: now,
        updatedAt: now,
      ),
      CalendarEvent(
        id: _uuid.v4(),
        title: 'Lower Body & Core Blast',
        description: 'Barbell squats, Romanian deadlifts & cable crunches',
        eventType: CalendarEventType.workout,
        scheduledDate: today.add(const Duration(days: 1)),
        startTime: DateTime(today.year, today.month, today.day + 1, 18, 0),
        endTime: DateTime(today.year, today.month, today.day + 1, 19, 15),
        isCompleted: false,
        recurrenceRule: RecurrenceRule.weekly,
        targetMetrics: {'targetDurationMinutes': 75, 'targetCalories': 520},
        createdAt: now,
        updatedAt: now,
      ),
      CalendarEvent(
        id: _uuid.v4(),
        title: 'Active Recovery & Mobility',
        description: 'Light 30m outdoor walk, foam rolling & hamstring stretches',
        eventType: CalendarEventType.restDay,
        scheduledDate: today.add(const Duration(days: 2)),
        startTime: DateTime(today.year, today.month, today.day + 2, 10, 0),
        isCompleted: false,
        recurrenceRule: RecurrenceRule.none,
        targetMetrics: {'targetDurationMinutes': 45},
        createdAt: now,
        updatedAt: now,
      ),
      CalendarEvent(
        id: _uuid.v4(),
        title: 'Weekly Bodyweight & Composition Check',
        description: 'Fasted morning weigh-in and progress metric check',
        eventType: CalendarEventType.weighIn,
        scheduledDate: today.add(const Duration(days: 3)),
        startTime: DateTime(today.year, today.month, today.day + 3, 7, 30),
        isCompleted: false,
        recurrenceRule: RecurrenceRule.weekly,
        targetMetrics: {'targetWeightKg': 75.0},
        createdAt: now,
        updatedAt: now,
      ),
      CalendarEvent(
        id: _uuid.v4(),
        title: 'Sleep Wind-Down & Blue Light Cutoff',
        description: 'Read physical book, dim lights, 8 hours restorative sleep',
        eventType: CalendarEventType.sleep,
        scheduledDate: today,
        startTime: DateTime(today.year, today.month, today.day, 22, 30),
        isCompleted: false,
        recurrenceRule: RecurrenceRule.daily,
        targetMetrics: {'targetSleepHours': 8.0},
        createdAt: now,
        updatedAt: now,
      ),
    ];

    for (final event in initialEvents) {
      await createEvent(event);
    }
  }
}

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  final dbInstance = ref.watch(databaseProvider);
  final repo = CalendarRepositoryImpl(dbInstance);
  repo.seedInitialCalendarEvents();
  return repo;
});
