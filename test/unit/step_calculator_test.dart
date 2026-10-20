import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/steps/domain/step_calculator.dart';

void main() {
  group('Part 3: StepCalculator Unit Tests', () {
    test('StepCalculator.distanceKm(steps: 10000, strideCm: 70) == 7.0', () {
      final distance = StepCalculator.distanceKm(steps: 10000, strideCm: 70);
      expect(distance, equals(7.0));
    });

    test('StepCalculator estimates stride length correctly for walking and running', () {
      const height = 180.0;
      // Walking: height * 0.415 = 74.7 cm
      final walkingStride = StepCalculator.estimateStrideCm(heightCm: height, isRunning: false);
      expect(walkingStride, closeTo(74.7, 0.01));

      // Running: height * 0.45 = 81.0 cm
      final runningStride = StepCalculator.estimateStrideCm(heightCm: height, isRunning: true);
      expect(runningStride, closeTo(81.0, 0.01));
    });

    test('formatDistance accurately formats < 1000 m to meters and >= 1000 m to km with 2 decimals', () {
      // < 1000 m
      expect(StepCalculator.formatDistance(0.820), equals('820 m'));
      expect(StepCalculator.formatDistance(0.050), equals('50 m'));
      expect(StepCalculator.formatDistance(0.999), equals('999 m'));

      // >= 1000 m
      expect(StepCalculator.formatDistance(1.000), equals('1.00 km'));
      expect(StepCalculator.formatDistance(3.421), equals('3.42 km'));
      expect(StepCalculator.formatDistance(10.567), equals('10.57 km'));
    });

    test('estimateCalories and estimateActiveMinutes produce standard metabolic outputs', () {
      expect(StepCalculator.estimateActiveMinutes(1000, cadence: 100), equals(10));
      expect(StepCalculator.estimateActiveMinutes(5000, cadence: 100), equals(50));

      final kcal = StepCalculator.estimateCalories(10000, weightKg: 70.0);
      expect(kcal, equals(400));
    });
  });
}
