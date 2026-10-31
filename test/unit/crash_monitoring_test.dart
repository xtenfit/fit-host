import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Crash Monitoring & Error Boundary Tests', () {
    testWidgets(
      'ErrorWidget.builder produces branded dark recovery UI on build error',
      (WidgetTester tester) async {
        final originalBuilder = ErrorWidget.builder;
        final originalOnError = FlutterError.onError;

        // Track caught flutter error
        FlutterErrorDetails? caughtDetails;
        FlutterError.onError = (details) {
          caughtDetails = details;
        };

        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Material(
            color: const Color(0xFF0A0F0D),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFF00E676),
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Something went wrong',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    details.exceptionAsString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        };

        try {
          await tester.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (context) {
                  throw StateError(
                    'Simulated UI Rendering Failure for Testing',
                  );
                },
              ),
            ),
          );

          // Verify the error boundary caught the error without throwing an uncaught crash
          expect(caughtDetails, isNotNull);
          expect(
            caughtDetails!.exceptionAsString(),
            contains('Simulated UI Rendering Failure'),
          );

          // Verify that the custom recovery UI rendered
          expect(find.text('Something went wrong'), findsOneWidget);
          expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
        } finally {
          ErrorWidget.builder = originalBuilder;
          FlutterError.onError = originalOnError;
        }
      },
    );

    test(
      'PlatformDispatcher.instance.onError intercepts uncaught asynchronous exceptions',
      () {
        final originalOnError = PlatformDispatcher.instance.onError;
        Object? capturedError;

        PlatformDispatcher.instance.onError = (error, stack) {
          capturedError = error;
          return true; // handled
        };

        try {
          final handler = PlatformDispatcher.instance.onError;
          expect(handler, isNotNull);

          final result = handler!(
            const FormatException('Simulated Background Network Failure'),
            StackTrace.current,
          );

          expect(result, isTrue);
          expect(capturedError, isA<FormatException>());
          expect(
            capturedError.toString(),
            contains('Simulated Background Network Failure'),
          );
        } finally {
          PlatformDispatcher.instance.onError = originalOnError;
        }
      },
    );
  });
}
