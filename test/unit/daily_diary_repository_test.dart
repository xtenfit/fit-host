import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/features/diary/data/daily_diary_repository.dart';

void main() {
  group('DailyDiaryRepository SQLite Persistence & Reactive Streams', () {
    late AppDatabase database;
    late DailyDiaryRepository repository;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      repository = DailyDiaryRepository(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('addEntry persists an entry and watchEntries emits it', () async {
      await repository.addEntry(
        title: 'Morning Sprint Planning',
        content: 'Completed roadmap review and architectural hardening.',
        category: 'work',
        mood: 'energized',
        voiceMemoPath: '/data/audio/memo_1.m4a',
        voiceMemoDurationSeconds: 45,
      );

      final entries = await repository.watchEntries().first;
      expect(entries.length, 1);
      final first = entries.first;
      expect(first.title, 'Morning Sprint Planning');
      expect(first.content, 'Completed roadmap review and architectural hardening.');
      expect(first.category, 'work');
      expect(first.mood, 'energized');
      expect(first.voiceMemoPath, '/data/audio/memo_1.m4a');
      expect(first.voiceMemoDurationSeconds, 45);
      expect(first.isDeleted, isFalse);
    });

    test('filters entries by category correctly', () async {
      await repository.addEntry(
        title: 'Career milestone reached',
        content: 'Promoted to Staff Engineer',
        category: 'career',
        mood: 'proud',
      );
      await repository.addEntry(
        title: 'Leg day workout completed',
        content: 'Squats and Romanian deadlifts',
        category: 'fitness',
        mood: 'energized',
      );
      await repository.addEntry(
        title: 'Gratitude evening',
        content: 'Walked in the park with family',
        category: 'personal',
        mood: 'calm',
      );

      final careerEntries = await repository.watchEntries(category: 'career').first;
      expect(careerEntries.length, 1);
      expect(careerEntries.first.title, 'Career milestone reached');

      final fitnessEntries = await repository.watchEntries(category: 'fitness').first;
      expect(fitnessEntries.length, 1);
      expect(fitnessEntries.first.title, 'Leg day workout completed');

      final allEntries = await repository.watchEntries(category: 'all').first;
      expect(allEntries.length, 3);
    });

    test('searches entries across title, content and mood', () async {
      await repository.addEntry(
        title: 'Hydration milestone',
        content: 'Drank 3.5 liters today',
        category: 'fitness',
        mood: 'energized',
      );
      await repository.addEntry(
        title: 'Design review',
        content: 'Polished Apple UX guidelines',
        category: 'work',
        mood: 'focused',
      );

      final searchByContent = await repository.watchEntries(searchQuery: 'liters').first;
      expect(searchByContent.length, 1);
      expect(searchByContent.first.title, 'Hydration milestone');

      final searchByMood = await repository.watchEntries(searchQuery: 'focused').first;
      expect(searchByMood.length, 1);
      expect(searchByMood.first.title, 'Design review');
    });

    test('updateEntry updates content and fields', () async {
      await repository.addEntry(
        title: 'Initial Note',
        content: 'Draft content',
        category: 'personal',
        mood: 'neutral',
      );

      final initialList = await repository.watchEntries().first;
      final entryId = initialList.first.id;

      await repository.updateEntry(
        id: entryId,
        title: 'Updated Note',
        content: 'Revised and polished content',
        category: 'life',
        mood: 'happy',
      );

      final updatedList = await repository.watchEntries().first;
      expect(updatedList.first.title, 'Updated Note');
      expect(updatedList.first.content, 'Revised and polished content');
      expect(updatedList.first.category, 'life');
      expect(updatedList.first.mood, 'happy');
    });

    test('deleteEntry soft-deletes entry so it is excluded from watchEntries', () async {
      await repository.addEntry(
        title: 'Temporary Idea',
        content: 'Discard soon',
        category: 'personal',
        mood: 'neutral',
      );

      var entries = await repository.watchEntries().first;
      expect(entries.length, 1);
      final id = entries.first.id;

      await repository.deleteEntry(id);

      entries = await repository.watchEntries().first;
      expect(entries.isEmpty, isTrue);
    });
  });
}
