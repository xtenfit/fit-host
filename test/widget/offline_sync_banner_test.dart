import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/connectivity/connectivity_state_machine.dart';
import 'package:fit_host/features/profile/presentation/widgets/sync_status_indicator.dart';

void main() {
  group('OfflineSyncBanner Widget Tests', () {
    testWidgets('Renders offline warning banner when connectivity is offline', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityProvider.overrideWith((ref) => Stream.value(ConnectivityStatus.offline)),
            pendingSyncCountProvider.overrideWith((ref) => Stream.value(0)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: OfflineSyncBanner(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Offline — changes are saved on this device.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    });

    testWidgets('Shows pending count when offline mutations are queued', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityProvider.overrideWith((ref) => Stream.value(ConnectivityStatus.offline)),
            pendingSyncCountProvider.overrideWith((ref) => Stream.value(3)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: OfflineSyncBanner(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Offline — 3 changes saved on this device.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('Hides banner when online with normal authenticated session and no offlineGrace', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityProvider.overrideWith((ref) => Stream.value(ConnectivityStatus.online)),
            pendingSyncCountProvider.overrideWith((ref) => Stream.value(0)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: OfflineSyncBanner(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Offline — changes are saved on this device.'), findsNothing);
      expect(find.byType(OfflineSyncBanner), findsOneWidget);
      expect(find.byType(Container), findsNothing);
    });
  });
}
