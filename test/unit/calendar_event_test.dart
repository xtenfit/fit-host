import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/calendar/domain/models/calendar_event.dart';

void main() {
  group('CalendarEvent Model Unit Tests', () {
    test('Calculates status correctly for Today, Completed, and Missed', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final tomorrow = today.add(const Duration(days: 1));

      final todayEvent = CalendarEvent(
        id: '1',
        title: 'Today Workout',
        eventType: CalendarEventType.workout,
        scheduledDate: today,
        createdAt: now,
        updatedAt: now,
      );
      expect(todayEvent.isToday, isTrue);
      expect(todayEvent.statusDisplay, 'Today');

      final completedEvent = todayEvent.copyWith(isCompleted: true);
      expect(completedEvent.statusDisplay, 'Completed');

      final missedEvent = CalendarEvent(
        id: '2',
        title: 'Missed Yesterday Workout',
        eventType: CalendarEventType.workout,
        scheduledDate: yesterday,
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      );
      expect(missedEvent.isPast, isTrue);
      expect(missedEvent.statusDisplay, 'Missed');

      final upcomingEvent = CalendarEvent(
        id: '3',
        title: 'Tomorrow Session',
        eventType: CalendarEventType.workout,
        scheduledDate: tomorrow,
        createdAt: now,
        updatedAt: now,
      );
      expect(upcomingEvent.isToday, isFalse);
      expect(upcomingEvent.isPast, isFalse);
      expect(upcomingEvent.statusDisplay, 'Upcoming');
    });

    test('Serializes target metrics accurately', () {
      final now = DateTime.now();
      final event = CalendarEvent(
        id: '4',
        title: 'Target Workout',
        eventType: CalendarEventType.workout,
        scheduledDate: now,
        targetMetrics: {'calories': 500, 'durationMinutes': 60},
        createdAt: now,
        updatedAt: now,
      );

      final companion = event.toCompanion();
      expect(companion.targetMetrics.value, contains('calories'));
      expect(companion.targetMetrics.value, contains('500'));
    });
  });
}
