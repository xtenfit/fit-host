import 'package:flutter/foundation.dart';
import 'package:fit_host/features/progress/domain/models/body_measurement.dart';

@immutable
class MeasurementProgressDelta {
  final BodyMeasurement baseline;
  final BodyMeasurement latest;

  const MeasurementProgressDelta({
    required this.baseline,
    required this.latest,
  });

  int get elapsedDays =>
      latest.measuredAt.difference(baseline.measuredAt).inDays;

  double? get weightDeltaKg {
    if (baseline.weightKg == null || latest.weightKg == null) return null;
    return latest.weightKg! - baseline.weightKg!;
  }

  double? get bodyFatDelta {
    if (baseline.bodyFatPercentage == null ||
        latest.bodyFatPercentage == null) {
      return null;
    }
    return latest.bodyFatPercentage! - baseline.bodyFatPercentage!;
  }

  double? get waistDeltaCm {
    if (baseline.waistCm == null || latest.waistCm == null) return null;
    return latest.waistCm! - baseline.waistCm!;
  }

  double? get chestDeltaCm {
    if (baseline.chestCm == null || latest.chestCm == null) return null;
    return latest.chestCm! - baseline.chestCm!;
  }

  double? get hipsDeltaCm {
    if (baseline.hipsCm == null || latest.hipsCm == null) return null;
    return latest.hipsCm! - baseline.hipsCm!;
  }

  double? get armsDeltaCm {
    if (baseline.armsCm == null || latest.armsCm == null) return null;
    return latest.armsCm! - baseline.armsCm!;
  }

  double? get thighsDeltaCm {
    if (baseline.thighsCm == null || latest.thighsCm == null) return null;
    return latest.thighsCm! - baseline.thighsCm!;
  }

  double? get calvesDeltaCm {
    if (baseline.calvesCm == null || latest.calvesCm == null) return null;
    return latest.calvesCm! - baseline.calvesCm!;
  }

  double? get neckDeltaCm {
    if (baseline.neckCm == null || latest.neckCm == null) return null;
    return latest.neckCm! - baseline.neckCm!;
  }

  double? get shouldersDeltaCm {
    if (baseline.shouldersCm == null || latest.shouldersCm == null) return null;
    return latest.shouldersCm! - baseline.shouldersCm!;
  }

  /// Calculates total inches/cm lost or gained across major circumference areas
  double get totalCircumferenceDeltaCm {
    double total = 0.0;
    if (waistDeltaCm != null) total += waistDeltaCm!;
    if (chestDeltaCm != null) total += chestDeltaCm!;
    if (hipsDeltaCm != null) total += hipsDeltaCm!;
    if (armsDeltaCm != null) total += armsDeltaCm!;
    if (thighsDeltaCm != null) total += thighsDeltaCm!;
    return total;
  }
}
