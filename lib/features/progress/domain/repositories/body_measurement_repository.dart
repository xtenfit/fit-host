import 'package:fit_host/features/progress/domain/models/body_measurement.dart';
import 'package:fit_host/features/progress/domain/models/progress_photo.dart';

abstract class BodyMeasurementRepository {
  /// Stream all measurements for user ordered by measuredAt descending
  Stream<List<BodyMeasurement>> watchMeasurements({String? userId});

  /// Fetch list of measurements for user ordered by measuredAt descending
  Future<List<BodyMeasurement>> getAllMeasurements({String? userId});

  /// Get most recent measurement
  Future<BodyMeasurement?> getLatestMeasurement({String? userId});

  /// Record a new measurement
  Future<void> recordMeasurement(BodyMeasurement measurement);

  /// Update an existing measurement
  Future<void> updateMeasurement(BodyMeasurement measurement);

  /// Soft-delete or hard-delete measurement
  Future<void> deleteMeasurement(String id);

  /// Stream progress photos, optionally filtered by pose type
  Stream<List<ProgressPhoto>> watchProgressPhotos({
    String? userId,
    PhotoPoseType? poseType,
  });

  /// Fetch all progress photos
  Future<List<ProgressPhoto>> getAllProgressPhotos({
    String? userId,
    PhotoPoseType? poseType,
  });

  /// Add a new progress photo
  Future<void> addProgressPhoto(ProgressPhoto photo);

  /// Delete a progress photo
  Future<void> deleteProgressPhoto(String id);

  /// Fetch remote measurements from Supabase and synchronize to local cache
  Future<void> fetchRemoteAndSaveMeasurements() async {}
}
