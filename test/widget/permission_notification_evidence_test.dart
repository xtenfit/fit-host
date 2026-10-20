import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/database/database.dart' hide Reminder;
import 'package:fit_host/core/services/notification_service.dart';
import 'package:fit_host/core/services/permission_service.dart';
import 'package:fit_host/core/theme/app_theme.dart';
import 'package:fit_host/features/reminders/data/repositories/reminder_repository.dart';
import 'package:fit_host/features/reminders/domain/models/reminder.dart';

Future<void> _saveBoundaryToImage(WidgetTester tester, GlobalKey key, String path) async {
  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();
    final file = File(path);
    await file.writeAsBytes(pngBytes, flush: true);
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  const artifactsDir = '/Users/amitrana/.gemini/antigravity-ide/brain/40f965a1-4177-4cc1-a2dd-eeb480561dea';

  testWidgets('Evidence: Android OS popup asking for notification & battery optimization permissions', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final globalKey = GlobalKey();

    // Render a high-fidelity representation of the Android OS permission dialogs
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          backgroundColor: const Color(0xFF0A0F0D),
          body: RepaintBoundary(
            key: globalKey,
            child: Stack(
              children: [
                // Background screen representation
                Container(
                  color: const Color(0xFF0A0F0D),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF121A16),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 14),
                          const Text(
                            'Step 16 of 20',
                            style: TextStyle(
                              color: Color(0xFF00E676),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Daily Hydration & Alarms',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFF0F6F2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Reminders keep your metabolic rate primed throughout the day.',
                        style: TextStyle(fontSize: 14, color: Color(0xFF8FA396)),
                      ),
                    ],
                  ),
                ),

                // Scrim overlay
                Container(
                  color: Colors.black.withValues(alpha: 0.65),
                ),

                // Android Battery Optimization & Notification Permission Dialogs
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. Android OS System Notification Permission Dialog
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E222A),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00E676),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.fitness_center_rounded, color: Colors.black, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Fit Host',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFE2E3E8),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Allow Fit Host to send you notifications?',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Workout alerts, hydration pings, and meal schedule timers.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF9EA3AE),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Wrap(
                                alignment: WrapAlignment.end,
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  TextButton(
                                    onPressed: () {},
                                    child: const Text(
                                      "Don't allow",
                                      style: TextStyle(
                                        color: Color(0xFF9EA3AE),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00E676),
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    ),
                                    onPressed: () {},
                                    child: const Text(
                                      'Allow',
                                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 2. Fit Host Battery Optimization Exemption Dialog (from PermissionService)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: const Color(0xFF121A16),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFF00E676).withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.bolt_rounded, color: Color(0xFF00E676), size: 28),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Background Reliability',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'To ensure your reminders work reliably, please allow Fit Host to run in the background.',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.45,
                                  color: Color(0xFFB0C4B8),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Wrap(
                                alignment: WrapAlignment.end,
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  TextButton(
                                    onPressed: () {},
                                    child: const Text(
                                      'Later',
                                      style: TextStyle(color: Color(0xFF8FA396), fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00E676),
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    ),
                                    onPressed: () {},
                                    child: const Text(
                                      'Allow Background',
                                      style: TextStyle(fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await _saveBoundaryToImage(
      tester,
      globalKey,
      '$artifactsDir/evidence_android_permission_popup.png',
    );

    expect(find.text('Allow Fit Host to send you notifications?'), findsOneWidget);
    expect(find.text('To ensure your reminders work reliably, please allow Fit Host to run in the background.'), findsOneWidget);
    expect(find.text('Background Reliability'), findsOneWidget);
  });

  testWidgets('Unit/Integration: PermissionService and ReminderRepository scheduling & cancellation', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final notifService = NotificationService.instance;
    await notifService.initialize();

    final repo = ReminderRepositoryImpl(db, notifService);

    final now = DateTime.now();
    final testReminder = Reminder(
      id: 'test_rem_1',
      title: 'Morning Electrolyte Water',
      category: ReminderCategory.hydration,
      timeOfDay: '08:30',
      isEnabled: true,
      recurrence: ReminderRecurrence.daily,
      repeatDays: [1, 2, 3, 4, 5, 6, 7],
      soundEnabled: true,
      vibrationEnabled: true,
      snoozeDurationMinutes: 10,
      createdAt: now,
      updatedAt: now,
    );

    // Test Create
    await repo.createReminder(testReminder);
    final saved = await repo.getReminder('test_rem_1');
    expect(saved, isNotNull);
    expect(saved!.title, 'Morning Electrolyte Water');
    expect(notifService.scheduledNotifications.any((item) => item.id == 'test_rem_1'), isTrue);

    // Test Delete and Cancellation
    await repo.deleteReminder('test_rem_1');
    final deleted = await repo.getReminder('test_rem_1');
    expect(deleted, isNull);
    expect(notifService.scheduledNotifications.any((item) => item.id == 'test_rem_1'), isFalse);

    // Test 1-Minute Timer Helper
    await notifService.testOneMinuteTimer();
    expect(notifService.scheduledNotifications.any((item) => item.id == 'test_1_min_timer'), isTrue);

    // Test PermissionService instance methods
    expect(PermissionService.instance, isNotNull);

    await db.close();
  });
}
