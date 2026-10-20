import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/core/services/supabase_service.dart';
import 'package:fit_host/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:fit_host/features/calendar/presentation/widgets/range_aggregation_card.dart';
import 'package:fit_host/features/profile/presentation/widgets/sync_status_indicator.dart';
import 'package:fit_host/features/steps/presentation/screens/steps_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('QA Visual Evidence: Dump Steps Screen widget tree', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final db = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          authStatusProvider.overrideWithValue(AuthStatus.guest),
        ],
        child: const MaterialApp(
          home: Scaffold(body: StepsScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Step Counter & Distance'), findsOneWidget);
    expect(find.text('Distance'), findsOneWidget);
    expect(find.text('Active Time'), findsOneWidget);
    expect(find.text('Calories'), findsOneWidget);
    expect(find.text('7-Day Movement Trend'), findsOneWidget);
    expect(find.text('Today Only'), findsOneWidget);

    debugPrint('=== STEPS SCREEN WIDGET TREE VERIFIED ===');
    await db.close();
  });

  testWidgets('QA Visual Evidence: Dump Calendar Month View & Range Aggregation Panel', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          authStatusProvider.overrideWithValue(AuthStatus.guest),
        ],
        child: const MaterialApp(
          home: CalendarScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Fitness Calendar'), findsOneWidget);
    expect(find.byType(RangeAggregationCard), findsOneWidget);
    expect(find.textContaining('Range Summary'), findsOneWidget);

    debugPrint('=== CALENDAR & RANGE AGGREGATION WIDGET TREE VERIFIED ===');
    await db.close();
  });

  testWidgets('QA Visual Evidence: Dump Sync Status Indicator', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          authStatusProvider.overrideWithValue(AuthStatus.guest),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SyncStatusIndicator(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(SyncStatusIndicator), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    expect(find.text('Offline — changes saved locally'), findsOneWidget);

    debugPrint('=== SYNC STATUS INDICATOR WIDGET TREE VERIFIED ===');
    await db.close();
  });
}
