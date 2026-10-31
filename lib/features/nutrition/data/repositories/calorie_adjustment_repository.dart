import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/database/database.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/models/calorie_adjustment.dart';

abstract class CalorieAdjustmentRepository {
  Future<List<CalorieAdjustment>> getAdjustmentsForDate(DateTime date);
  Future<List<CalorieAdjustment>> getAdjustmentsForRange(
    DateTime start,
    DateTime end,
  );
  Future<void> addAdjustment(CalorieAdjustment adjustment);
  Future<void> updateAdjustment(CalorieAdjustment adjustment);
  Future<void> deleteAdjustment(String adjustmentId);
}

class CalorieAdjustmentRepositoryImpl implements CalorieAdjustmentRepository {
  final AppDatabase db;
  final String userId;
  final SupabaseClient? supabaseClient;
  bool _tableEnsured = false;

  CalorieAdjustmentRepositoryImpl({
    required this.db,
    this.userId = 'guest',
    this.supabaseClient,
  });

  Future<void> _ensureTable() async {
    if (_tableEnsured) return;
    try {
      await db.customStatement('''
        CREATE TABLE IF NOT EXISTS calorie_adjustments (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          date TEXT NOT NULL,
          calories_burned INTEGER NOT NULL,
          title TEXT NOT NULL,
          note TEXT,
          source TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          sync_status TEXT NOT NULL
        );
      ''');
      await db.customStatement('''
        CREATE INDEX IF NOT EXISTS idx_calorie_adj_user_date 
        ON calorie_adjustments (user_id, date, deleted_at);
      ''');
      _tableEnsured = true;
    } catch (e) {
      debugPrint('[CalorieAdjustmentRepo] table creation warning: $e');
    }
  }

  String _formatDate(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

  @override
  Future<List<CalorieAdjustment>> getAdjustmentsForDate(DateTime date) async {
    await _ensureTable();
    final dateStr = _formatDate(date);
    final rows = await db
        .customSelect(
          'SELECT * FROM calorie_adjustments WHERE user_id = ? AND date = ? AND deleted_at IS NULL ORDER BY created_at ASC',
          variables: [
            drift.Variable.withString(userId),
            drift.Variable.withString(dateStr),
          ],
        )
        .get();

    return rows.map((r) {
      return CalorieAdjustment(
        id: r.read<String>('id'),
        userId: r.read<String>('user_id'),
        date: DateTime.parse(r.read<String>('date')),
        caloriesBurned: r.read<int>('calories_burned'),
        title: r.read<String>('title'),
        note: r.readNullable<String>('note'),
        source: r.read<String>('source'),
        createdAt: DateTime.parse(r.read<String>('created_at')),
        updatedAt: DateTime.parse(r.read<String>('updated_at')),
        deletedAt: r.readNullable<String>('deleted_at') != null
            ? DateTime.parse(r.read<String>('deleted_at'))
            : null,
        syncStatus: r.read<String>('sync_status'),
      );
    }).toList();
  }

  @override
  Future<List<CalorieAdjustment>> getAdjustmentsForRange(
    DateTime start,
    DateTime end,
  ) async {
    await _ensureTable();
    final startStr = _formatDate(start);
    final endStr = _formatDate(end);
    final rows = await db
        .customSelect(
          'SELECT * FROM calorie_adjustments WHERE user_id = ? AND date >= ? AND date <= ? AND deleted_at IS NULL ORDER BY date ASC, created_at ASC',
          variables: [
            drift.Variable.withString(userId),
            drift.Variable.withString(startStr),
            drift.Variable.withString(endStr),
          ],
        )
        .get();

    return rows.map((r) {
      return CalorieAdjustment(
        id: r.read<String>('id'),
        userId: r.read<String>('user_id'),
        date: DateTime.parse(r.read<String>('date')),
        caloriesBurned: r.read<int>('calories_burned'),
        title: r.read<String>('title'),
        note: r.readNullable<String>('note'),
        source: r.read<String>('source'),
        createdAt: DateTime.parse(r.read<String>('created_at')),
        updatedAt: DateTime.parse(r.read<String>('updated_at')),
        deletedAt: r.readNullable<String>('deleted_at') != null
            ? DateTime.parse(r.read<String>('deleted_at'))
            : null,
        syncStatus: r.read<String>('sync_status'),
      );
    }).toList();
  }

  @override
  Future<void> addAdjustment(CalorieAdjustment adjustment) async {
    await _ensureTable();
    final dateStr = _formatDate(adjustment.date);
    await db.customStatement(
      '''
      INSERT OR REPLACE INTO calorie_adjustments (
        id, user_id, date, calories_burned, title, note, source,
        created_at, updated_at, deleted_at, sync_status
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        adjustment.id,
        userId,
        dateStr,
        adjustment.caloriesBurned,
        adjustment.title,
        adjustment.note,
        adjustment.source,
        adjustment.createdAt.toIso8601String(),
        adjustment.updatedAt.toIso8601String(),
        adjustment.deletedAt?.toIso8601String(),
        adjustment.syncStatus,
      ],
    );

    _pushToSupabase(adjustment);
  }

  @override
  Future<void> updateAdjustment(CalorieAdjustment adjustment) async {
    await _ensureTable();
    final dateStr = _formatDate(adjustment.date);
    final now = DateTime.now();
    await db.customStatement(
      '''
      UPDATE calorie_adjustments 
      SET calories_burned = ?, title = ?, note = ?, date = ?, updated_at = ?, sync_status = 'pending'
      WHERE id = ? AND user_id = ?
      ''',
      [
        adjustment.caloriesBurned,
        adjustment.title,
        adjustment.note,
        dateStr,
        now.toIso8601String(),
        adjustment.id,
        userId,
      ],
    );

    _pushToSupabase(adjustment.copyWith(updatedAt: now));
  }

  @override
  Future<void> deleteAdjustment(String adjustmentId) async {
    await _ensureTable();
    final now = DateTime.now();
    await db.customStatement(
      '''
      UPDATE calorie_adjustments 
      SET deleted_at = ?, updated_at = ?, sync_status = 'pending'
      WHERE id = ? AND user_id = ?
      ''',
      [now.toIso8601String(), now.toIso8601String(), adjustmentId, userId],
    );

    if (userId != 'guest' && supabaseClient != null) {
      try {
        await supabaseClient!
            .from('calorie_adjustments')
            .update({
              'deleted_at': now.toIso8601String(),
              'updated_at': now.toIso8601String(),
            })
            .eq('id', adjustmentId)
            .eq('user_id', userId);
      } catch (e) {
        debugPrint('[CalorieAdjustmentRepo] Cloud delete warning: $e');
      }
    }
  }

  Future<void> _pushToSupabase(CalorieAdjustment adjustment) async {
    if (userId == 'guest' || supabaseClient == null) return;
    try {
      await supabaseClient!.from('calorie_adjustments').upsert({
        'id': adjustment.id,
        'user_id': userId,
        'date': _formatDate(adjustment.date),
        'calories_burned': adjustment.caloriesBurned,
        'title': adjustment.title,
        'note': adjustment.note,
        'source': adjustment.source,
        'created_at': adjustment.createdAt.toIso8601String(),
        'updated_at': adjustment.updatedAt.toIso8601String(),
        'deleted_at': adjustment.deletedAt?.toIso8601String(),
      });
    } catch (e) {
      debugPrint('[CalorieAdjustmentRepo] Cloud upsert warning: $e');
    }
  }
}

final calorieAdjustmentRepositoryProvider =
    Provider<CalorieAdjustmentRepository>((ref) {
      final db = ref.watch(databaseProvider);
      final authStatus = ref.watch(authStatusProvider);
      final user = ref.watch(currentUserProvider);
      final userId = (authStatus == AuthStatus.authenticated && user != null)
          ? user.id
          : 'guest';

      SupabaseClient? supabase;
      try {
        supabase = Supabase.instance.client;
      } catch (_) {}

      return CalorieAdjustmentRepositoryImpl(
        db: db,
        userId: userId,
        supabaseClient: supabase,
      );
    });
