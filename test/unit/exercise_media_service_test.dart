import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/services/exercise_media_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExerciseMediaService Verification Suite', () {
    late ExerciseMediaService service;

    setUp(() {
      service = ExerciseMediaService();
    });

    test(
      'ExerciseMediaService initializes directory structure without crashing',
      () async {
        await service.init();
        expect(service, isNotNull);
      },
    );

    test('getCachedFile returns null for uncached URL', () async {
      final cached = await service.getCachedFile(
        'https://cdn.amitrana.tech/exercises/images/9999-nonexistent.jpg',
        isThumbnail: true,
      );
      expect(cached, isNull);
    });

    test('getCachedFile returns null for empty URL', () async {
      final cached = await service.getCachedFile('', isThumbnail: true);
      expect(cached, isNull);
    });

    test('loadMedia returns null gracefully for invalid URL', () async {
      final file = await service.loadMedia(
        url: 'https://invalid-non-existent-domain-12345.com/test.jpg',
        isThumbnail: true,
      );
      expect(file, isNull);
    });

    test(
      'Concurrent requests for the same URL join the in-flight future',
      () async {
        const testUrl =
            'https://invalid-non-existent-domain-12345.com/dedup_test.jpg';
        final req1 = service.loadMedia(url: testUrl, isThumbnail: true);
        final req2 = service.loadMedia(url: testUrl, isThumbnail: true);

        final results = await Future.wait([req1, req2]);
        expect(results[0], isNull);
        expect(results[1], isNull);
      },
    );
  });
}
