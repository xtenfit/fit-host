import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/data/steps_repository.dart';
import '../domain/step_calculator.dart';

class StepService with WidgetsBindingObserver {
  final StepsRepository repository;
  final Stream<StepCount>? customSensorStream;
  final DateTime Function() clock;
  double strideLengthCm;
  int targetSteps;

  StreamSubscription<StepCount>? _pedometerSub;
  final StreamController<int> _todayStepsController =
      StreamController<int>.broadcast();

  DateTime _currentDate;
  int _todaySteps = 0;
  int? _lastSensorReading;
  int? _sensorBaseAtMidnight;
  int _accumulatedBeforeReboot = 0;
  bool _isListening = false;
  String _tzOffset = '+00:00';

  StepService({
    required this.repository,
    this.customSensorStream,
    DateTime Function()? clock,
    this.strideLengthCm = 70.0,
    this.targetSteps = 10000,
  })  : clock = clock ?? DateTime.now,
        _currentDate = (clock ?? DateTime.now)().toLocal() {
    _computeTzOffset();
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
    init();
  }

  int get todaySteps => _todaySteps;
  DateTime get currentDate => _currentDate;
  Stream<int> get todayStepsStream => _todayStepsController.stream;

  void _computeTzOffset() {
    final now = clock().toLocal();
    final offset = now.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    _tzOffset = '$sign$hours:$minutes';
  }

  Future<void> init() async {
    final now = clock().toLocal();
    _currentDate = DateTime(now.year, now.month, now.day);

    // Seed from local SQLite database first
    final existingSteps = await repository.getDailySteps(_currentDate);
    _todaySteps = math.max(_todaySteps, existingSteps);
    _accumulatedBeforeReboot = _todaySteps;
    if (!_todayStepsController.isClosed) {
      _todayStepsController.add(_todaySteps);
    }

    // Request Activity Recognition on Android before listening to pedometer
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final status = await Permission.activityRecognition.status;
        if (!status.isGranted) {
          await Permission.activityRecognition.request();
        }
      } catch (e) {
        debugPrint('[StepService] ActivityRecognition permission request notice: $e');
      }
    }

    // Start sensor stream
    _startListening();
  }

  void updateStrideAndGoal({double? strideCm, int? goal}) {
    if (strideCm != null && strideCm > 0) strideLengthCm = strideCm;
    if (goal != null && goal > 0) targetSteps = goal;
    _persistToday().ignore();
  }

  void _startListening() {
    if (_isListening) return;

    final stream = customSensorStream ?? _getPlatformSensorStream();
    if (stream == null) return;

    _isListening = true;
    _pedometerSub = stream.listen(
      _onStepCountReceived,
      onError: (error) {
        debugPrint('[StepService] Pedometer stream notice: $error');
      },
      cancelOnError: false,
    );
  }

  Stream<StepCount>? _getPlatformSensorStream() {
    try {
      // In web or desktop test environments, Pedometer is unavailable
      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
        return null;
      }
      return Pedometer.stepCountStream;
    } catch (e) {
      debugPrint('[StepService] Native pedometer initialization notice: $e');
      return null;
    }
  }

  void _onStepCountReceived(StepCount event) {
    onSensorReading(event.steps);
  }

  /// Processes raw cumulative sensor reading with reboot and midnight rollover handling
  Future<void> onSensorReading(int sensorSteps) async {
    final now = clock().toLocal();
    _computeTzOffset();

    // 1. Midnight Rollover Check
    if (now.year != _currentDate.year ||
        now.month != _currentDate.month ||
        now.day != _currentDate.day) {
      await _handleMidnightRollover(now, sensorSteps);
      return;
    }

    // 2. Device Reboot Check (Android cumulative step counter drops)
    if (_lastSensorReading != null && sensorSteps < _lastSensorReading!) {
      debugPrint(
          '[StepService] Device reboot detected: counter dropped from $_lastSensorReading to $sensorSteps');
      _accumulatedBeforeReboot = _todaySteps;
      _sensorBaseAtMidnight = sensorSteps;
    }

    _lastSensorReading = sensorSteps;
    _sensorBaseAtMidnight ??= sensorSteps;

    // 3. Compute Delta Since Midnight / Reboot Baseline
    final stepsSinceBase = sensorSteps - _sensorBaseAtMidnight!;
    final computedToday =
        _accumulatedBeforeReboot + (stepsSinceBase > 0 ? stepsSinceBase : 0);

    // Monotonic advancement (steps never regress)
    if (computedToday > _todaySteps) {
      _todaySteps = computedToday;
      if (!_todayStepsController.isClosed) {
        _todayStepsController.add(_todaySteps);
      }
      await _persistToday();
    }
  }

  Future<void> _handleMidnightRollover(DateTime now, int sensorSteps) async {
    debugPrint(
        '[StepService] Midnight rollover triggered: yesterday=$_currentDate, today=$now');
    // Seal yesterday's record
    await _persistDay(_currentDate, _todaySteps);

    final midnightBase = _lastSensorReading ?? sensorSteps;

    // Start fresh for new day
    _currentDate = DateTime(now.year, now.month, now.day);
    _accumulatedBeforeReboot = 0;
    _sensorBaseAtMidnight = midnightBase;
    _lastSensorReading = sensorSteps;

    final stepsToday = sensorSteps > midnightBase ? (sensorSteps - midnightBase) : 0;
    _todaySteps = stepsToday;

    if (!_todayStepsController.isClosed) {
      _todayStepsController.add(_todaySteps);
    }
    await _persistDay(_currentDate, _todaySteps);
  }

  /// Manually adds steps (used in tests or manual logging)
  Future<void> addSteps(int steps) async {
    if (steps <= 0) return;
    _todaySteps += steps;
    if (!_todayStepsController.isClosed) {
      _todayStepsController.add(_todaySteps);
    }
    await _persistToday();
  }

  Future<void> _persistToday() async {
    await _persistDay(_currentDate, _todaySteps);
  }

  Future<void> _persistDay(DateTime date, int steps) async {
    final distanceKm =
        StepCalculator.distanceKm(steps: steps, strideCm: strideLengthCm);
    final distanceMeters = distanceKm * 1000.0;
    final calories = StepCalculator.estimateCalories(steps);
    final activeMinutes = StepCalculator.estimateActiveMinutes(steps);

    await repository.setDailySteps(
      date,
      steps,
      target: targetSteps,
      distance: distanceMeters,
      calories: calories,
      activeMinutes: activeMinutes,
      tzOffset: _tzOffset,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final now = clock().toLocal();
      if (now.year != _currentDate.year ||
          now.month != _currentDate.month ||
          now.day != _currentDate.day) {
        if (_lastSensorReading != null) {
          _handleMidnightRollover(now, _lastSensorReading!);
        } else {
          _currentDate = DateTime(now.year, now.month, now.day);
          _todaySteps = 0;
          if (!_todayStepsController.isClosed) {
            _todayStepsController.add(0);
          }
        }
      }
    }
  }

  void dispose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    _pedometerSub?.cancel();
    _todayStepsController.close();
  }
}

final stepServiceProvider = Provider<StepService>((ref) {
  final repo = ref.watch(stepsRepositoryProvider);
  final service = StepService(
    repository: repo,
    strideLengthCm: 70.0,
    targetSteps: 10000,
  );
  ref.onDispose(() => service.dispose());
  return service;
});

final todayStepsStreamProvider = StreamProvider<int>((ref) {
  final service = ref.watch(stepServiceProvider);
  return service.todayStepsStream;
});
