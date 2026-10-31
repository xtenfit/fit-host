import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/core/services/supabase_service.dart';
import 'package:fit_host/core/services/supabase_storage_service.dart';
import 'package:fit_host/features/progress/domain/models/body_measurement.dart';
import 'package:fit_host/features/progress/domain/models/progress_photo.dart';
import 'package:fit_host/features/progress/domain/models/measurement_delta.dart';
import 'package:fit_host/features/progress/domain/repositories/body_measurement_repository.dart';
import 'package:fit_host/features/progress/data/repositories/body_measurement_repository_impl.dart';

final bodyMeasurementRepositoryProvider = Provider<BodyMeasurementRepository>((
  ref,
) {
  final db = ref.watch(databaseProvider);
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id ?? 'guest';
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (_) {}
  final storageService = ref.watch(supabaseFileStorageServiceProvider);
  return BodyMeasurementRepositoryImpl(
    db,
    userId: userId,
    supabase: client,
    storageService: storageService,
  );
});

final bodyMeasurementsStreamProvider =
    StreamProvider.autoDispose<List<BodyMeasurement>>((ref) {
      final repo = ref.watch(bodyMeasurementRepositoryProvider);
      return repo.watchMeasurements();
    });

final latestMeasurementProvider = Provider.autoDispose<BodyMeasurement?>((ref) {
  final measurementsAsync = ref.watch(bodyMeasurementsStreamProvider);
  return measurementsAsync.maybeWhen(
    data: (list) => list.isNotEmpty ? list.first : null,
    orElse: () => null,
  );
});

final progressPhotosStreamProvider = StreamProvider.autoDispose
    .family<List<ProgressPhoto>, PhotoPoseType?>((ref, poseType) {
      final repo = ref.watch(bodyMeasurementRepositoryProvider);
      return repo.watchProgressPhotos(poseType: poseType);
    });

final allProgressPhotosStreamProvider =
    StreamProvider.autoDispose<List<ProgressPhoto>>((ref) {
      final repo = ref.watch(bodyMeasurementRepositoryProvider);
      return repo.watchProgressPhotos();
    });

final measurementProgressDeltaProvider =
    Provider.autoDispose<MeasurementProgressDelta?>((ref) {
      final measurementsAsync = ref.watch(bodyMeasurementsStreamProvider);
      return measurementsAsync.maybeWhen(
        data: (list) {
          if (list.length < 2) return null;
          // List is ordered descending (newest first, oldest last)
          final latest = list.first;
          final baseline = list.last;
          return MeasurementProgressDelta(baseline: baseline, latest: latest);
        },
        orElse: () => null,
      );
    });
