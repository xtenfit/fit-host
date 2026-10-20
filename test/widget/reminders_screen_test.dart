import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/database/database.dart' hide Reminder;
import 'package:fit_host/core/services/notification_service.dart';
import 'package:fit_host/features/reminders/data/repositories/reminder_repository.dart';
import 'package:fit_host/features/reminders/domain/models/reminder.dart';
import 'package:fit_host/features/reminders/presentation/screens/reminders_screen.dart';

void main() {
  testWidgets('RemindersScreen renders alarms summary, category filters, and cards',
      (WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final reminderRepo = ReminderRepositoryImpl(db, NotificationService());
    await reminderRepo.createReminder(
      Reminder(
        id: 'test-alarm-1',
        title: 'Morning Workout & Mobility',
        category: ReminderCategory.workout,
        timeOfDay: '07:30',
        isEnabled: true,
        recurrence: ReminderRecurrence.daily,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(
          home: RemindersScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Reminders & Alarms'), findsOneWidget);

    // Verify Filter Chips
    expect(find.text('All Categories'), findsOneWidget);

    // Verify Alarm cards have rendered with switches
    expect(find.byType(Switch), findsWidgets);

    await db.close();
  });
}
