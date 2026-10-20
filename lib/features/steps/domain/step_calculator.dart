class StepCalculator {
  /// Calculates distance in kilometers from steps and stride length in cm:
  /// distance_km = steps * stride_cm / 100000
  static double distanceKm({required int steps, required double strideCm}) {
    if (steps <= 0 || strideCm <= 0) return 0.0;
    return (steps * strideCm) / 100000.0;
  }

  /// Calculates distance in meters from steps and stride length in cm:
  /// distance_m = steps * stride_cm / 100
  static double distanceMeters({required int steps, required double strideCm}) {
    if (steps <= 0 || strideCm <= 0) return 0.0;
    return (steps * strideCm) / 100.0;
  }

  /// Estimates stride length in cm from user height:
  /// stride_cm = height_cm * 0.415 (walking) or * 0.45 (running)
  static double estimateStrideCm({required double heightCm, bool isRunning = false}) {
    if (heightCm <= 0) return 70.0;
    final factor = isRunning ? 0.45 : 0.415;
    return heightCm * factor;
  }

  /// Formats distance according to requirement:
  /// < 1000 m -> "820 m"
  /// >= 1000 m -> "3.42 km" (2 decimals)
  static String formatDistance(double km) {
    if (km <= 0) return '0 m';
    final meters = km * 1000.0;
    if (meters < 1000.0) {
      return '${meters.round()} m';
    } else {
      return '${km.toStringAsFixed(2)} km';
    }
  }

  /// Estimates active minutes from steps (standard ~100 steps/min cadence)
  static int estimateActiveMinutes(int steps, {int cadence = 100}) {
    if (steps <= 0) return 0;
    return steps ~/ cadence;
  }

  /// Estimates active calories burned based on body weight
  static int estimateCalories(int steps, {double weightKg = 70.0}) {
    if (steps <= 0) return 0;
    final calPerStep = (weightKg / 70.0) * 0.04;
    return (steps * calPerStep).round();
  }
}
