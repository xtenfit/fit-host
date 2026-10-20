import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/home/presentation/widgets/home_streak_date_strip.dart';
import 'package:fit_host/features/home/presentation/controllers/home_dashboard_controller.dart';

void main() {
  testWidgets('HomeStreakDateStrip shows past 3 days, today, and 1 next day',
      (WidgetTester tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expectedDays = List.generate(
      5,
      (index) => today.add(Duration(days: index - 3)).day.toString(),
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: HomeStreakDateStrip(isDark: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify all 5 expected days are rendered
    for (final dayStr in expectedDays) {
      expect(find.text(dayStr), findsWidgets);
    }

    // Verify default selected date is today
    final context = tester.element(find.byType(HomeStreakDateStrip));
    final container = ProviderScope.containerOf(context);
    final selectedDate = container.read(homeDashboardProvider).selectedDate;
    expect(selectedDate.day, equals(now.day));

    // Tap on the first item (today - 3 days)
    final firstDayFinder = find.text(expectedDays[0]).first;
    await tester.tap(firstDayFinder);
    await tester.pumpAndSettle();

    final newSelectedDate = container.read(homeDashboardProvider).selectedDate;
    expect(
      newSelectedDate.day,
      equals(today.add(const Duration(days: -3)).day),
    );
  });
}
