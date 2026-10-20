import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database.dart';

class DailyDiaryRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  DailyDiaryRepository(this._db);

  Stream<List<DailyDiaryEntry>> watchEntries({String? category, String? searchQuery}) {
    final query = _db.select(_db.dailyDiaryEntries)
      ..where((tbl) => tbl.isDeleted.equals(false));

    if (category != null && category.isNotEmpty && category != 'all') {
      query.where((tbl) => tbl.category.equals(category));
    }

    query.orderBy([(tbl) => drift.OrderingTerm.desc(tbl.entryDate)]);

    return query.watch().map((list) {
      if (searchQuery == null || searchQuery.isEmpty) {
        return list;
      }
      final q = searchQuery.toLowerCase();
      return list.where((item) {
        return item.title.toLowerCase().contains(q) ||
            item.content.toLowerCase().contains(q) ||
            item.mood.toLowerCase().contains(q);
      }).toList();
    });
  }

  Future<void> addEntry({
    required String title,
    required String content,
    required String category,
    required String mood,
    DateTime? entryDate,
    String? voiceMemoPath,
    int? voiceMemoDurationSeconds,
    List<String> tags = const [],
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await _db.into(_db.dailyDiaryEntries).insert(
          DailyDiaryEntriesCompanion.insert(
            id: id,
            title: title,
            content: content,
            category: drift.Value(category),
            mood: drift.Value(mood),
            entryDate: entryDate ?? now,
            voiceMemoPath: drift.Value(voiceMemoPath),
            voiceMemoDurationSeconds: drift.Value(voiceMemoDurationSeconds),
            createdAt: drift.Value(now),
            updatedAt: drift.Value(now),
          ),
        );
  }

  Future<void> updateEntry({
    required String id,
    required String title,
    required String content,
    required String category,
    required String mood,
    String? voiceMemoPath,
    int? voiceMemoDurationSeconds,
  }) async {
    await (_db.update(_db.dailyDiaryEntries)..where((tbl) => tbl.id.equals(id))).write(
      DailyDiaryEntriesCompanion(
        title: drift.Value(title),
        content: drift.Value(content),
        category: drift.Value(category),
        mood: drift.Value(mood),
        voiceMemoPath: drift.Value(voiceMemoPath),
        voiceMemoDurationSeconds: drift.Value(voiceMemoDurationSeconds),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteEntry(String id) async {
    await (_db.update(_db.dailyDiaryEntries)..where((tbl) => tbl.id.equals(id))).write(
      DailyDiaryEntriesCompanion(
        isDeleted: const drift.Value(true),
        deletedAt: drift.Value(DateTime.now()),
      ),
    );
  }
}

final dailyDiaryRepositoryProvider = Provider<DailyDiaryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DailyDiaryRepository(db);
});
