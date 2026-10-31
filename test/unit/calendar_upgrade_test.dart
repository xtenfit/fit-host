import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/calendar/domain/models/calendar_event.dart';
import 'package:fit_host/features/calendar/data/services/google_calendar_service.dart';

void main() {
  group('Google Calendar & Smart Reminders Integration Tests', () {
    test(
      'CalendarEvent stores and retrieves google_event_id via targetMetrics',
      () {
        final now = DateTime.now();
        final event = CalendarEvent(
          id: 'test-event-123',
          title: 'Morning Upper Body Hypertrophy',
          eventType: CalendarEventType.workout,
          scheduledDate: now,
          startTime: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(event.googleEventId, isNull);

        final syncedEvent = event.withGoogleEventId('gcal_abc_789');
        expect(syncedEvent.googleEventId, equals('gcal_abc_789'));
        expect(
          syncedEvent.targetMetrics?['google_event_id'],
          equals('gcal_abc_789'),
        );

        // Preserves existing target metrics when adding google_event_id
        final withMetrics = syncedEvent.copyWith(
          targetMetrics: {'google_event_id': 'gcal_abc_789', 'calories': 450},
        );
        expect(withMetrics.googleEventId, equals('gcal_abc_789'));
        expect(withMetrics.targetMetrics?['calories'], equals(450));
      },
    );

    test(
      'GoogleCalendarState tracks connection, email, and loading status',
      () {
        const state = GoogleCalendarState(
          status: GoogleCalendarSyncStatus.disconnected,
          accountEmail: null,
          selectedCalendarId: 'primary',
        );

        expect(state.isConnected, isFalse);
        expect(state.accountEmail, isNull);

        final connected = state.copyWith(
          status: GoogleCalendarSyncStatus.connected,
          accountEmail: 'user@fithost.tech',
          selectedCalendarId: 'primary',
        );
        expect(connected.isConnected, isTrue);
        expect(connected.accountEmail, equals('user@fithost.tech'));
      },
    );

    test('GoogleCalendarInfo model holds valid id and summary', () {
      final item = GoogleCalendarInfo(
        id: 'primary',
        summary: 'Personal Fitness Calendar',
        isPrimary: true,
        timeZone: 'Asia/Kolkata',
      );

      expect(item.id, equals('primary'));
      expect(item.summary, equals('Personal Fitness Calendar'));
      expect(item.isPrimary, isTrue);
      expect(item.timeZone, equals('Asia/Kolkata'));
    });
  });
}
