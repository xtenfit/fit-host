import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/core/database/tables.dart';
import 'package:fit_host/core/sync/sync_utils.dart';
import 'dart:io';
import 'package:fit_host/core/services/supabase_storage_service.dart';
import 'package:fit_host/features/progress/domain/models/body_measurement.dart';
import 'package:fit_host/features/progress/domain/models/progress_photo.dart';
import 'package:fit_host/features/progress/domain/repositories/body_measurement_repository.dart';

class BodyMeasurementRepositoryImpl implements BodyMeasurementRepository {
  final AppDatabase db;
  final String userId;
  final SupabaseClient? supabase;
  final SupabaseFileStorageService? storageService;
  final _uuid = const Uuid();

  BodyMeasurementRepositoryImpl(
    this.db, {
    this.userId = 'guest',
    this.supabase,
    this.storageService,
  }) {
    if (userId != 'guest' && isValidUuid(userId) && supabase != null) {
      fetchRemoteAndSaveMeasurements().ignore();
    }
  }

  String _resolveUser(String? explicit) {
    final raw = explicit ?? userId;
    if (raw == 'guest_user' || raw.isEmpty) return 'guest';
    return raw;
  }

  Expression<bool> _userFilter(BodyMeasurements t, String uid) {
    if (uid == 'guest') {
      return (t.userId.equals('guest') | t.userId.equals('guest_user')) &
          t.isDeleted.equals(false);
    }
    return t.userId.equals(uid) & t.isDeleted.equals(false);
  }

  @override
  Stream<List<BodyMeasurement>> watchMeasurements({String? userId}) {
    final uid = _resolveUser(userId);
    final query = db.select(db.bodyMeasurements)
      ..where((t) => _userFilter(t, uid))
      ..orderBy([(t) => OrderingTerm.desc(t.measuredAt)]);

    return query.watch().map((rows) => rows.map(_mapMeasurementRow).toList());
  }

  @override
  Future<List<BodyMeasurement>> getAllMeasurements({String? userId}) async {
    final uid = _resolveUser(userId);
    final rows =
        await (db.select(db.bodyMeasurements)
              ..where((t) => _userFilter(t, uid))
              ..orderBy([(t) => OrderingTerm.desc(t.measuredAt)]))
            .get();

    return rows.map(_mapMeasurementRow).toList();
  }

  @override
  Future<BodyMeasurement?> getLatestMeasurement({String? userId}) async {
    final uid = _resolveUser(userId);
    final rows =
        await (db.select(db.bodyMeasurements)
              ..where((t) => _userFilter(t, uid))
              ..orderBy([(t) => OrderingTerm.desc(t.measuredAt)])
              ..limit(1))
            .get();

    if (rows.isEmpty) return null;
    return _mapMeasurementRow(rows.first);
  }

  @override
  Future<void> recordMeasurement(BodyMeasurement measurement) async {
    final now = DateTime.now().toUtc();
    final uid = _resolveUser(measurement.userId);
    final entryId = measurement.id.isEmpty ? _uuid.v4() : measurement.id;

    await db
        .into(db.bodyMeasurements)
        .insert(
          BodyMeasurementsCompanion(
            id: Value(entryId),
            userId: Value(uid),
            measuredAt: Value(measurement.measuredAt.toUtc()),
            weightKg: Value(measurement.weightKg),
            bodyFatPercentage: Value(measurement.bodyFatPercentage),
            waistCm: Value(measurement.waistCm),
            chestCm: Value(measurement.chestCm),
            hipsCm: Value(measurement.hipsCm),
            armsCm: Value(measurement.armsCm),
            thighsCm: Value(measurement.thighsCm),
            calvesCm: Value(measurement.calvesCm),
            neckCm: Value(measurement.neckCm),
            shouldersCm: Value(measurement.shouldersCm),
            notes: Value(measurement.notes),
            createdAt: Value(now),
            updatedAt: Value(now),
            isDeleted: const Value(false),
          ),
          mode: InsertMode.insertOrReplace,
        );

    // Enqueue for cloud sync
    await _enqueueSync(
      entityType: 'body_measurement',
      entityId: entryId,
      operation: 'upsert',
      payload: measurement.copyWith(id: entryId, userId: uid).toJson(),
    );
  }

  @override
  Future<void> updateMeasurement(BodyMeasurement measurement) async {
    final now = DateTime.now().toUtc();
    final uid = _resolveUser(measurement.userId);

    await (db.update(
      db.bodyMeasurements,
    )..where((t) => t.id.equals(measurement.id))).write(
      BodyMeasurementsCompanion(
        weightKg: Value(measurement.weightKg),
        bodyFatPercentage: Value(measurement.bodyFatPercentage),
        waistCm: Value(measurement.waistCm),
        chestCm: Value(measurement.chestCm),
        hipsCm: Value(measurement.hipsCm),
        armsCm: Value(measurement.armsCm),
        thighsCm: Value(measurement.thighsCm),
        calvesCm: Value(measurement.calvesCm),
        neckCm: Value(measurement.neckCm),
        shouldersCm: Value(measurement.shouldersCm),
        notes: Value(measurement.notes),
        updatedAt: Value(now),
      ),
    );

    await _enqueueSync(
      entityType: 'body_measurement',
      entityId: measurement.id,
      operation: 'upsert',
      payload: measurement.copyWith(userId: uid).toJson(),
    );
  }

  @override
  Future<void> deleteMeasurement(String id) async {
    final now = DateTime.now().toUtc();
    await (db.update(db.bodyMeasurements)..where((t) => t.id.equals(id))).write(
      BodyMeasurementsCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    await _enqueueSync(
      entityType: 'body_measurement',
      entityId: id,
      operation: 'DELETE',
      payload: {'id': id, 'deleted_at': now.toIso8601String()},
    );
  }

  @override
  Stream<List<ProgressPhoto>> watchProgressPhotos({
    String? userId,
    PhotoPoseType? poseType,
  }) {
    final uid = _resolveUser(userId);
    final query = db.select(db.progressPhotos)
      ..where((t) {
        var predicate = t.userId.equals(uid) & t.isDeleted.equals(false);
        if (poseType != null) {
          predicate = predicate & t.poseType.equals(poseType.value);
        }
        return predicate;
      })
      ..orderBy([(t) => OrderingTerm.desc(t.takenAt)]);

    return query.watch().map((rows) => rows.map(_mapPhotoRow).toList());
  }

  @override
  Future<List<ProgressPhoto>> getAllProgressPhotos({
    String? userId,
    PhotoPoseType? poseType,
  }) async {
    final uid = _resolveUser(userId);
    final rows =
        await (db.select(db.progressPhotos)
              ..where((t) {
                var predicate =
                    t.userId.equals(uid) & t.isDeleted.equals(false);
                if (poseType != null) {
                  predicate = predicate & t.poseType.equals(poseType.value);
                }
                return predicate;
              })
              ..orderBy([(t) => OrderingTerm.desc(t.takenAt)]))
            .get();

    return rows.map(_mapPhotoRow).toList();
  }

  @override
  Future<void> addProgressPhoto(ProgressPhoto photo) async {
    final now = DateTime.now().toUtc();
    final uid = _resolveUser(photo.userId);
    final photoId = photo.id.isEmpty ? _uuid.v4() : photo.id;

    String remoteStoragePath = photo.photoPath;
    final localFile = File(photo.photoPath);
    if (localFile.existsSync() && uid != 'guest' && isValidUuid(uid)) {
      try {
        final storage = storageService ?? SupabaseFileStorageService(supabase);
        final uploaded = await storage.uploadProgressPhoto(
          sourceFile: localFile,
          userId: uid,
          customId: photoId,
          poseType: photo.poseType.value,
        );
        if (uploaded != null) {
          remoteStoragePath = uploaded.storagePath;
        }
      } catch (e) {
        debugPrint('[BodyMeasurementRepo] Photo upload notice: $e');
      }
    }

    await db
        .into(db.progressPhotos)
        .insert(
          ProgressPhotosCompanion(
            id: Value(photoId),
            userId: Value(uid),
            takenAt: Value(photo.takenAt.toUtc()),
            photoPath: Value(photo.photoPath),
            poseType: Value(photo.poseType.value),
            associatedMeasurementId: Value(photo.associatedMeasurementId),
            weightKgAtPhoto: Value(photo.weightKgAtPhoto),
            notes: Value(photo.notes),
            createdAt: Value(now),
            updatedAt: Value(now),
            isDeleted: const Value(false),
          ),
          mode: InsertMode.insertOrReplace,
        );

    final syncPayload = photo
        .copyWith(id: photoId, userId: uid, photoPath: remoteStoragePath)
        .toJson();

    await _enqueueSync(
      entityType: 'progress_photo',
      entityId: photoId,
      operation: 'upsert',
      payload: syncPayload,
    );
  }

  @override
  Future<void> deleteProgressPhoto(String id) async {
    final now = DateTime.now().toUtc();
    final existing = await (db.select(
      db.progressPhotos,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    await (db.update(db.progressPhotos)..where((t) => t.id.equals(id))).write(
      ProgressPhotosCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    if (existing != null && userId != 'guest' && isValidUuid(userId)) {
      try {
        final storage = storageService ?? SupabaseFileStorageService(supabase);
        final pose = existing.poseType;
        final storagePath = '$userId/${pose}_${existing.id}.webp';
        await storage.deleteFile(
          bucket: StorageBuckets.progressPhotos,
          storagePath: storagePath,
          userId: userId,
        );
      } catch (e) {
        debugPrint('[BodyMeasurementRepo] Photo delete notice: $e');
      }
    }

    await _enqueueSync(
      entityType: 'progress_photo',
      entityId: id,
      operation: 'DELETE',
      payload: {'id': id, 'deleted_at': now.toIso8601String()},
    );
  }

  @override
  Future<void> fetchRemoteAndSaveMeasurements() async {
    if (supabase == null || userId == 'guest' || !isValidUuid(userId)) return;
    try {
      final rows = await supabase!
          .from('body_measurements')
          .select()
          .match({'user_id': userId})
          .isFilter('deleted_at', null)
          .order('measured_at', ascending: false);

      for (final r in rows) {
        final id = r['id'] as String;
        final measuredAt = DateTime.parse(r['measured_at'] as String);
        final createdAt = r['created_at'] != null
            ? DateTime.parse(r['created_at'] as String)
            : DateTime.now().toUtc();
        final updatedAt = r['updated_at'] != null
            ? DateTime.parse(r['updated_at'] as String)
            : DateTime.now().toUtc();

        await db
            .into(db.bodyMeasurements)
            .insert(
              BodyMeasurementsCompanion(
                id: Value(id),
                userId: Value(userId),
                measuredAt: Value(measuredAt),
                weightKg: Value((r['weight_kg'] as num?)?.toDouble()),
                bodyFatPercentage: Value(
                  (r['body_fat_percentage'] as num?)?.toDouble(),
                ),
                waistCm: Value((r['waist_cm'] as num?)?.toDouble()),
                chestCm: Value((r['chest_cm'] as num?)?.toDouble()),
                hipsCm: Value((r['hips_cm'] as num?)?.toDouble()),
                armsCm: Value((r['arms_cm'] as num?)?.toDouble()),
                thighsCm: Value((r['thighs_cm'] as num?)?.toDouble()),
                calvesCm: Value((r['calves_cm'] as num?)?.toDouble()),
                neckCm: Value((r['neck_cm'] as num?)?.toDouble()),
                shouldersCm: Value((r['shoulders_cm'] as num?)?.toDouble()),
                notes: Value(r['notes'] as String?),
                createdAt: Value(createdAt),
                updatedAt: Value(updatedAt),
                isDeleted: const Value(false),
                syncStatus: const Value('synced'),
              ),
              mode: InsertMode.insertOrReplace,
            );
      }
    } catch (e) {
      debugPrint('[BodyMeasurementRepo] fetchRemote notice: $e');
    }
  }

  Future<void> _enqueueSync({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final cleanPayload = Map<String, dynamic>.from(payload);
      cleanPayload.remove('sync_status');
      cleanPayload.remove('syncStatus');
      await db
          .into(db.syncQueue)
          .insert(
            SyncQueueCompanion(
              id: Value(_uuid.v4()),
              userId: Value(userId),
              entityType: Value(entityType),
              entityId: Value(entityId),
              operation: Value(operation),
              payload: Value(jsonEncode(cleanPayload)),
              createdAt: Value(DateTime.now().toUtc()),
              clientTimestamp: Value(DateTime.now().toUtc()),
              status: const Value('queued'),
            ),
          );
    } catch (_) {
      // Outbox failure should not block local offline write
    }
  }

  BodyMeasurement _mapMeasurementRow(BodyMeasurementData row) {
    return BodyMeasurement(
      id: row.id,
      userId: row.userId,
      measuredAt: row.measuredAt,
      weightKg: row.weightKg,
      bodyFatPercentage: row.bodyFatPercentage,
      waistCm: row.waistCm,
      chestCm: row.chestCm,
      hipsCm: row.hipsCm,
      armsCm: row.armsCm,
      thighsCm: row.thighsCm,
      calvesCm: row.calvesCm,
      neckCm: row.neckCm,
      shouldersCm: row.shouldersCm,
      notes: row.notes,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      isDeleted: row.isDeleted,
      syncStatus: row.syncStatus,
    );
  }

  ProgressPhoto _mapPhotoRow(ProgressPhotoData row) {
    return ProgressPhoto(
      id: row.id,
      userId: row.userId,
      takenAt: row.takenAt,
      photoPath: row.photoPath,
      poseType: PhotoPoseType.fromString(row.poseType),
      associatedMeasurementId: row.associatedMeasurementId,
      weightKgAtPhoto: row.weightKgAtPhoto,
      notes: row.notes,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      isDeleted: row.isDeleted,
      syncStatus: row.syncStatus,
    );
  }
}
