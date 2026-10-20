import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/features/calendar/presentation/screens/calendar_screen.dart';

void main() {
  testWidgets('CalendarScreen renders header, view modes, and event agenda',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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

    // Verify Range bar & View Mode options
    expect(find.text('Custom'), findsOneWidget);
    expect(find.text('Month'), findsNWidgets(2)); // Range control + View mode
    expect(find.text('Week'), findsNWidgets(2));  // Range control + View mode
    expect(find.text('Day'), findsOneWidget);

    // Verify Range Summary Card
    expect(find.textContaining('Range Summary'), findsOneWidget);

    // Verify Filter Chips
    expect(find.text('All Activities'), findsOneWidget);
    expect(find.text('Workout'), findsOneWidget);

    // Tap Week view mode (the second one)
    await tester.tap(find.text('Week').last);
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
