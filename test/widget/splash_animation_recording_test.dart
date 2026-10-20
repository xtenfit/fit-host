import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/theme/app_theme.dart';
import 'package:fit_host/features/onboarding/presentation/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '.',
    );
  });

  const framesDir = '/Users/amitrana/.gemini/antigravity-ide/brain/40f965a1-4177-4cc1-a2dd-eeb480561dea/scratch/frames';

  testWidgets('Record splash screen animation frames', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final globalKey = GlobalKey();

    final fontFile = File('/System/Library/Fonts/Supplemental/Arial Bold.ttf');
    if (fontFile.existsSync()) {
      final bytes = fontFile.readAsBytesSync();
      final fontData = ByteData.view(bytes.buffer);
      final loader = FontLoader('Arial')..addFont(Future.value(fontData));
      await loader.load();
    }

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            backgroundColor: const Color(0xFF0A0F0D),
            body: RepaintBoundary(
              key: globalKey,
              child: const SplashScreen(autoNavigate: false),
            ),
          ),
        ),
      ),
    );

    // Initial frame
    await tester.pump(Duration.zero);

    // Capture frames over 3.5 seconds at ~15 fps (every ~66ms -> 53 frames)
    int frameIndex = 0;
    const totalFrames = 50;
    const frameInterval = Duration(milliseconds: 70);

    for (int i = 0; i < totalFrames; i++) {
      await tester.runAsync(() async {
        final boundary = globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1.5);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final bytes = byteData!.buffer.asUint8List();

        final fileName = '$framesDir/frame_${frameIndex.toString().padLeft(3, '0')}.png';
        await File(fileName).writeAsBytes(bytes, flush: true);
      });

      frameIndex++;
      await tester.pump(frameInterval);
    }

    // Save key milestone screenshots for documentation
    final artifactsDir = '/Users/amitrana/.gemini/antigravity-ide/brain/40f965a1-4177-4cc1-a2dd-eeb480561dea';
    await tester.runAsync(() async {
      final boundary = globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      await File('$artifactsDir/evidence_splash_screen.png').writeAsBytes(bytes, flush: true);
    });

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('FIT HOST'), findsOneWidget);
    expect(find.text('PERFORMANCE & LONGEVITY'), findsOneWidget);
  });
}
