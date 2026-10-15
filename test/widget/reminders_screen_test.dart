import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/features/workouts/presentation/controllers/workout_providers.dart';
import 'package:fit_host/features/reminders/presentation/screens/reminders_screen.dart';

void main() {
  testWidgets('RemindersScreen renders alarms summary, category filters, and cards',
      (WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());

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
