import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/database.dart';
import '../../domain/models/exercise_submission.dart';
import '../../domain/repositories/exercise_submission_repository.dart';

final exerciseSubmissionRepositoryProvider =
    Provider<ExerciseSubmissionRepository>((ref) {
      final db = ref.watch(databaseProvider);
      SupabaseClient? client;
      try {
        client = Supabase.instance.client;
      } catch (_) {}
      return ExerciseSubmissionRepositoryImpl(db, supabase: client);
    });

class ExerciseSubmissionRepositoryImpl implements ExerciseSubmissionRepository {
  final AppDatabase _db;
  final SupabaseClient? _supabase;
  final Uuid _uuid;

  ExerciseSubmissionRepositoryImpl(this._db, {this._supabase, Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  SupabaseClient? get supabase => _supabase;

  @override
  Future<ExerciseSubmission> createSubmission(
    ExerciseSubmission submission,
  ) async {
    final hash = ExerciseSubmission.generateHash(
      type: submission.submissionType,
      targetExerciseId: submission.targetExerciseId,
      name: submission.name,
      equipment: submission.equipment,
    );

    // Duplicate submission prevention
    final isDuplicate = await hasPendingDuplicate(
      type: submission.submissionType,
      targetExerciseId: submission.targetExerciseId,
      name: submission.name,
      equipment: submission.equipment,
    );

    if (isDuplicate) {
      throw StateError(
        'A pending contribution for "${submission.name}" with equipment "${submission.equipment}" already exists in the moderation queue.',
      );
    }

    final subId = submission.id.isNotEmpty ? submission.id : _uuid.v4();
    final now = DateTime.now().toUtc();

    final companion = ExerciseSubmissionsCompanion.insert(
      id: subId,
      submissionType: Value(submission.submissionType.toDbString()),
      targetExerciseId: Value(submission.targetExerciseId),
      name: submission.name.trim(),
      category: submission.category,
      equipment: submission.equipment,
      targetMuscle: submission.targetMuscle,
      secondaryMuscles: Value(jsonEncode(submission.secondaryMuscles)),
      instructions: submission.instructions.trim(),
      safetyNotes: Value(submission.safetyNotes?.trim()),
      difficultyLevel: Value(submission.difficultyLevel),
      movementType: Value(submission.movementType),
      audienceSuitability: Value(submission.audienceSuitability),
      suggestedRationale: Value(submission.suggestedRationale.trim()),
      status: const Value('pending'),
      moderatorNotes: const Value(null),
      submittedBy: Value(submission.submittedBy),
      createdAt: Value(now),
      updatedAt: Value(now),
      duplicateHash: hash,
      syncStatus: const Value('pending'),
    );

    await _db.into(_db.exerciseSubmissions).insert(companion);

    // Queue for cloud sync
    try {
      await _db
          .into(_db.syncQueue)
          .insert(
            SyncQueueCompanion(
              id: Value(_uuid.v4()),
              userId: Value(submission.submittedBy),
              entityType: const Value('exercise_submission'),
              entityId: Value(subId),
              operation: const Value('insert'),
              payload: Value(
                jsonEncode(
                  submission
                      .copyWith(
                        id: subId,
                        status: ModerationStatus.pending,
                        duplicateHash: hash,
                        createdAt: now,
                        updatedAt: now,
                      )
                      .toJson(),
                ),
              ),
              createdAt: Value(now),
              clientTimestamp: Value(now),
              status: const Value('queued'),
            ),
          );
    } catch (_) {}

    return submission.copyWith(
      id: subId,
      status: ModerationStatus.pending,
      duplicateHash: hash,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<bool> hasPendingDuplicate({
    required SubmissionType type,
    String? targetExerciseId,
    required String name,
    required String equipment,
  }) async {
    final hash = ExerciseSubmission.generateHash(
      type: type,
      targetExerciseId: targetExerciseId,
      name: name,
      equipment: equipment,
    );

    final query = _db.select(_db.exerciseSubmissions)
      ..where(
        (t) =>
            t.duplicateHash.equals(hash) &
            t.status.equals('pending') &
            t.isDeleted.equals(false),
      );

    final matches = await query.get();
    return matches.isNotEmpty;
  }

  @override
  Future<List<ExerciseSubmission>> getMySubmissions({String? userId}) async {
    final targetUser = userId ?? 'guest';
    final query = _db.select(_db.exerciseSubmissions)
      ..where(
        (t) => t.submittedBy.equals(targetUser) & t.isDeleted.equals(false),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

    final rows = await query.get();
    return rows.map(_fromData).toList();
  }

  @override
  Stream<List<ExerciseSubmission>> watchMySubmissions({String? userId}) {
    final targetUser = userId ?? 'guest';
    final query = _db.select(_db.exerciseSubmissions)
      ..where(
        (t) => t.submittedBy.equals(targetUser) & t.isDeleted.equals(false),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

    return query.watch().map((rows) => rows.map(_fromData).toList());
  }

  @override
  Future<List<ExerciseSubmission>> getApprovedSubmissions() async {
    final query = _db.select(_db.exerciseSubmissions)
      ..where((t) => t.status.equals('approved') & t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.reviewedAt)]);

    final rows = await query.get();
    return rows.map(_fromData).toList();
  }

  @override
  Stream<List<ExerciseSubmission>> watchApprovedSubmissions() {
    final query = _db.select(_db.exerciseSubmissions)
      ..where((t) => t.status.equals('approved') & t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.reviewedAt)]);

    return query.watch().map((rows) => rows.map(_fromData).toList());
  }

  @override
  Future<void> reviewSubmission({
    required String submissionId,
    required ModerationStatus newStatus,
    required String moderatorId,
    String? notes,
  }) async {
    final now = DateTime.now().toUtc();

    await _db.transaction(() async {
      await (_db.update(
        _db.exerciseSubmissions,
      )..where((t) => t.id.equals(submissionId))).write(
        ExerciseSubmissionsCompanion(
          status: Value(newStatus.toDbString()),
          moderatorNotes: Value(notes),
          reviewedAt: Value(now),
          reviewedBy: Value(moderatorId),
          updatedAt: Value(now),
          syncStatus: const Value('pending'),
        ),
      );

      final logId = _uuid.v4();
      await _db
          .into(_db.exerciseModerationLogs)
          .insert(
            ExerciseModerationLogsCompanion.insert(
              id: logId,
              submissionId: submissionId,
              moderatorId: moderatorId,
              action: newStatus.toDbString(),
              notes: Value(notes),
              timestamp: Value(now),
            ),
          );
    });
  }

  @override
  Future<List<ExerciseModerationLog>> getModerationLogs(
    String submissionId,
  ) async {
    final query = _db.select(_db.exerciseModerationLogs)
      ..where((t) => t.submissionId.equals(submissionId))
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]);

    final rows = await query.get();
    return rows
        .map(
          (r) => ExerciseModerationLog(
            id: r.id,
            submissionId: r.submissionId,
            moderatorId: r.moderatorId,
            action: r.action,
            notes: r.notes,
            timestamp: r.timestamp,
          ),
        )
        .toList();
  }

  ExerciseSubmission _fromData(ExerciseSubmissionData data) {
    List<String> sec = [];
    try {
      final decoded = jsonDecode(data.secondaryMuscles);
      if (decoded is List) sec = decoded.map((e) => e.toString()).toList();
    } catch (_) {}

    return ExerciseSubmission(
      id: data.id,
      submissionType: SubmissionType.fromDbString(data.submissionType),
      targetExerciseId: data.targetExerciseId,
      name: data.name,
      category: data.category,
      equipment: data.equipment,
      targetMuscle: data.targetMuscle,
      secondaryMuscles: sec,
      instructions: data.instructions,
      safetyNotes: data.safetyNotes,
      difficultyLevel: data.difficultyLevel,
      movementType: data.movementType,
      audienceSuitability: data.audienceSuitability,
      suggestedRationale: data.suggestRationaleSafe,
      status: ModerationStatus.fromDbString(data.status),
      moderatorNotes: data.moderatorNotes,
      submittedBy: data.submittedBy,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      reviewedAt: data.reviewedAt,
      reviewedBy: data.reviewedBy,
      duplicateHash: data.duplicateHash,
    );
  }
}

extension on ExerciseSubmissionData {
  String get suggestRationaleSafe => suggestedRationale;
}
