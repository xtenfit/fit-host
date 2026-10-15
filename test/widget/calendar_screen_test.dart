import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/features/workouts/presentation/controllers/workout_providers.dart';
import 'package:fit_host/features/calendar/presentation/screens/calendar_screen.dart';

void main() {
  testWidgets('CalendarScreen renders header, view modes, and event agenda',
      (WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(
          home: CalendarScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & Today shortcut
    expect(find.text('Fitness Calendar'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Today'), findsOneWidget);

    // Verify View Mode options (Month, Week, Day)
    expect(find.text('Month'), findsOneWidget);
    expect(find.text('Week'), findsOneWidget);
    expect(find.text('Day'), findsOneWidget);

    // Verify Filter Chips
    expect(find.text('All Activities'), findsOneWidget);
    expect(find.text('Workout'), findsOneWidget);

    // Tap Week view mode
    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();

    // Tap Day view mode
    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();

    // Tap Today shortcut
    await tester.tap(find.widgetWithText(TextButton, 'Today'));
    await tester.pumpAndSettle();

    await db.close();
  });
}
