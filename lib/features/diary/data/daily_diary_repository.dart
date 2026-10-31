import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/sync/sync_utils.dart';

class DailyDiaryRepository {
  final AppDatabase _db;
  final String userId;
  final SupabaseClient? supabase;
  static const _uuid = Uuid();

  DailyDiaryRepository(this._db, {this.userId = 'guest', this.supabase});

  Stream<List<DailyDiaryEntry>> watchEntries({
    String? category,
    String? searchQuery,
  }) {
    final query = _db.select(_db.dailyDiaryEntries)
      ..where((tbl) => tbl.userId.equals(userId) & tbl.isDeleted.equals(false));

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
    final effectiveEntryDate = entryDate ?? now;

    await _db
        .into(_db.dailyDiaryEntries)
        .insert(
          DailyDiaryEntriesCompanion.insert(
            id: id,
            userId: drift.Value(userId),
            title: title,
            content: content,
            category: drift.Value(category),
            mood: drift.Value(mood),
            entryDate: effectiveEntryDate,
            voiceMemoPath: drift.Value(voiceMemoPath),
            voiceMemoDurationSeconds: drift.Value(voiceMemoDurationSeconds),
            createdAt: drift.Value(now),
            updatedAt: drift.Value(now),
          ),
        );

    if (isValidUuid(userId)) {
      final payload = {
        'id': id,
        'user_id': userId,
        'title': title,
        'content': content,
        'category': category,
        'mood': mood,
        'entry_date': effectiveEntryDate.toUtc().toIso8601String(),
        'voice_memo_path': voiceMemoPath,
        'voice_memo_duration_seconds': voiceMemoDurationSeconds,
        'created_at': now.toUtc().toIso8601String(),
        'updated_at': now.toUtc().toIso8601String(),
        'is_deleted': false,
      };

      if (supabase != null) {
        try {
          await supabase!
              .from('daily_diary_entries')
              .upsert(payload, onConflict: 'id');
          return;
        } catch (e) {
          debugPrint('[DailyDiaryRepository] Direct cloud upsert notice: $e');
        }
      }

      await _db
          .into(_db.syncQueue)
          .insertOnConflictUpdate(
            SyncQueueCompanion.insert(
              id: 'sync_diary_$id',
              userId: drift.Value(userId),
              entityType: 'daily_diary_entries',
              entityId: id,
              operation: 'upsert',
              payload: jsonEncode(payload),
              createdAt: DateTime.now().toUtc(),
              clientTimestamp: drift.Value(DateTime.now().toUtc()),
              status: const drift.Value('queued'),
            ),
          );
    }
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
    final now = DateTime.now();
    await (_db.update(
      _db.dailyDiaryEntries,
    )..where((tbl) => tbl.id.equals(id) & tbl.userId.equals(userId))).write(
      DailyDiaryEntriesCompanion(
        title: drift.Value(title),
        content: drift.Value(content),
        category: drift.Value(category),
        mood: drift.Value(mood),
        voiceMemoPath: drift.Value(voiceMemoPath),
        voiceMemoDurationSeconds: drift.Value(voiceMemoDurationSeconds),
        updatedAt: drift.Value(now),
      ),
    );

    if (isValidUuid(userId)) {
      final payload = {
        'id': id,
        'user_id': userId,
        'title': title,
        'content': content,
        'category': category,
        'mood': mood,
        'voice_memo_path': voiceMemoPath,
        'voice_memo_duration_seconds': voiceMemoDurationSeconds,
        'updated_at': now.toUtc().toIso8601String(),
      };

      if (supabase != null) {
        try {
          await supabase!
              .from('daily_diary_entries')
              .upsert(payload, onConflict: 'id');
          return;
        } catch (e) {
          debugPrint('[DailyDiaryRepository] Direct cloud update notice: $e');
        }
      }

      await _db
          .into(_db.syncQueue)
          .insertOnConflictUpdate(
            SyncQueueCompanion.insert(
              id: 'sync_diary_$id',
              userId: drift.Value(userId),
              entityType: 'daily_diary_entries',
              entityId: id,
              operation: 'upsert',
              payload: jsonEncode(payload),
              createdAt: DateTime.now().toUtc(),
              clientTimestamp: drift.Value(DateTime.now().toUtc()),
              status: const drift.Value('queued'),
            ),
          );
    }
  }

  Future<void> deleteEntry(String id) async {
    final now = DateTime.now();
    await (_db.update(
      _db.dailyDiaryEntries,
    )..where((tbl) => tbl.id.equals(id) & tbl.userId.equals(userId))).write(
      DailyDiaryEntriesCompanion(
        isDeleted: const drift.Value(true),
        deletedAt: drift.Value(now),
        updatedAt: drift.Value(now),
      ),
    );

    if (isValidUuid(userId)) {
      if (supabase != null) {
        try {
          await supabase!
              .from('daily_diary_entries')
              .update({
                'is_deleted': true,
                'deleted_at': now.toUtc().toIso8601String(),
                'updated_at': now.toUtc().toIso8601String(),
              })
              .match({'id': id, 'user_id': userId});
          return;
        } catch (e) {
          debugPrint('[DailyDiaryRepository] Direct cloud delete notice: $e');
        }
      }

      await _db
          .into(_db.syncQueue)
          .insertOnConflictUpdate(
            SyncQueueCompanion.insert(
              id: 'delete_diary_$id',
              userId: drift.Value(userId),
              entityType: 'daily_diary_entries',
              entityId: id,
              operation: 'DELETE',
              payload: jsonEncode({'id': id, 'user_id': userId}),
              createdAt: DateTime.now().toUtc(),
              clientTimestamp: drift.Value(DateTime.now().toUtc()),
              status: const drift.Value('queued'),
            ),
          );
    }
  }

  Future<void> refreshFromCloud() async {
    if (supabase == null || !isValidUuid(userId)) return;
    try {
      final rows = await supabase!
          .from('daily_diary_entries')
          .select()
          .match({'user_id': userId})
          .isFilter('deleted_at', null);

      for (final r in rows) {
        await _db
            .into(_db.dailyDiaryEntries)
            .insertOnConflictUpdate(
              DailyDiaryEntriesCompanion.insert(
                id: r['id'] as String,
                userId: drift.Value(userId),
                title: r['title'] as String,
                content: r['content'] as String,
                category: drift.Value(r['category'] as String? ?? 'personal'),
                mood: drift.Value(r['mood'] as String? ?? 'focused'),
                entryDate: DateTime.parse(r['entry_date'] as String),
                voiceMemoPath: drift.Value(r['voice_memo_path'] as String?),
                voiceMemoDurationSeconds: drift.Value(
                  r['voice_memo_duration_seconds'] as int?,
                ),
                createdAt: drift.Value(
                  DateTime.parse(r['created_at'] as String),
                ),
                updatedAt: drift.Value(
                  DateTime.parse(r['updated_at'] as String),
                ),
                isDeleted: drift.Value(r['is_deleted'] as bool? ?? false),
                syncStatus: const drift.Value('synced'),
              ),
            );
      }
    } catch (e) {
      debugPrint('[DailyDiaryRepository] refreshFromCloud notice: $e');
    }
  }
}

final dailyDiaryRepositoryProvider = Provider<DailyDiaryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final authState = ref.watch(authProvider);
  final user = authState.user;
  final userId = (authState.status == AuthStatus.authenticated && user != null)
      ? user.id
      : 'guest';

  SupabaseClient? client;
  if (authState.status == AuthStatus.authenticated && user != null) {
    try {
      client = Supabase.instance.client;
    } catch (_) {}
  }

  final repo = DailyDiaryRepository(db, userId: userId, supabase: client);
  if (client != null && isValidUuid(userId)) {
    repo.refreshFromCloud().ignore();
  }
  return repo;
});
