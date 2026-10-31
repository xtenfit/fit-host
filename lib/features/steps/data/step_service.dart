import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/home_widget_service.dart';
import '../../../core/data/steps_repository.dart';
import '../domain/step_calculator.dart';
import 'health_platform_service.dart';

class StepService with WidgetsBindingObserver {
  final StepsRepository repository;
  final HealthPlatformService? healthPlatformService;
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
  StepDataSource _currentSource = StepDataSource.hardwareSensor;
  DateTime? _lastSyncedAt;

  StepService({
    required this.repository,
    this.healthPlatformService,
    this.customSensorStream,
    DateTime Function()? clock,
    this.strideLengthCm = 70.0,
    this.targetSteps = 10000,
  }) : clock = clock ?? DateTime.now,
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
  StepDataSource get currentSource => _currentSource;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  void _computeTzOffset() {
    final now = clock().toLocal();
    final offset = now.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    _tzOffset = '$sign$hours:$minutes';
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadSavedBaseline() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _dateKey(_currentDate);
      final savedBase = prefs.getInt('step_sensor_base_$key');
      final savedReboot = prefs.getInt('step_accumulated_reboot_$key');
      if (savedBase != null) {
        _sensorBaseAtMidnight = savedBase;
      }
      if (savedReboot != null) {
        _accumulatedBeforeReboot = math.max(
          _accumulatedBeforeReboot,
          savedReboot,
        );
      }
    } catch (e) {
      debugPrint('[StepService] Failed to load saved step baseline: $e');
    }
  }

  Future<void> _saveBaseline() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _dateKey(_currentDate);
      if (_sensorBaseAtMidnight != null) {
        await prefs.setInt('step_sensor_base_$key', _sensorBaseAtMidnight!);
      }
      await prefs.setInt(
        'step_accumulated_reboot_$key',
        _accumulatedBeforeReboot,
      );
    } catch (e) {
      debugPrint('[StepService] Failed to save step baseline: $e');
    }
  }

  Future<void> init() async {
    final now = clock().toLocal();
    _currentDate = DateTime(now.year, now.month, now.day);

    // Seed from local SQLite database first
    final existingSteps = await repository.getDailySteps(_currentDate);
    _todaySteps = math.max(_todaySteps, existingSteps);
    _accumulatedBeforeReboot = _todaySteps;

    // Load persisted sensor base and accumulated before reboot
    await _loadSavedBaseline();

    if (!_todayStepsController.isClosed) {
      _todayStepsController.add(_todaySteps);
    }

    // Try synchronizing with Health Connect or HealthKit first
    await syncHealthPlatform();

    // Request Activity Recognition on Android before listening to pedometer
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final status = await Permission.activityRecognition.status;
        if (!status.isGranted) {
          await Permission.activityRecognition.request();
        }
      } catch (e) {
        debugPrint(
          '[StepService] ActivityRecognition permission request notice: $e',
        );
      }
    }

    // Start sensor stream as fallback if health platform is not actively updating
    _startListening();
  }

  /// Attempts to pull aggregated daily steps from OS Health Platform (Health Connect / HealthKit)
  Future<bool> syncHealthPlatform() async {
    if (healthPlatformService == null) return false;
    try {
      final result = await healthPlatformService!.fetchDailyAggregateSteps(
        _currentDate,
      );
      if (result != null) {
        _todaySteps = result.steps;
        _currentSource = result.source;
        _lastSyncedAt = result.synchronizedAt;
        if (!_todayStepsController.isClosed) {
          _todayStepsController.add(_todaySteps);
        }
        await _persistToday();
        return true;
      }
    } catch (e) {
      debugPrint('[StepService] Health platform sync notice: $e');
    }
    return false;
  }

  /// Imports the available daily step aggregates so the app's history matches
  /// the connected health provider instead of only showing today's value.
  Future<int> syncHealthPlatformHistory({int days = 30}) async {
    if (healthPlatformService == null || days <= 0) return 0;
    var imported = 0;
    final today = DateTime(
      _currentDate.year,
      _currentDate.month,
      _currentDate.day,
    );
    for (var offset = days - 1; offset >= 0; offset--) {
      final date = today.subtract(Duration(days: offset));
      try {
        final result = await healthPlatformService!.fetchDailyAggregateSteps(
          date,
        );
        if (result == null) continue;
        await repository.setDailySteps(
          date,
          result.steps,
          target: targetSteps,
          distance: StepCalculator.distanceKm(
            steps: result.steps,
            strideCm: strideLengthCm,
          ),
          calories: StepCalculator.estimateCalories(result.steps),
          activeMinutes: StepCalculator.estimateActiveMinutes(result.steps),
        );
        imported++;
      } catch (e) {
        debugPrint('[StepService] Historical health sync notice: $e');
      }
    }
    return imported;
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
    // If an OS health platform provides authoritative aggregate steps, avoid double counting
    if (_currentSource == StepDataSource.healthConnect ||
        _currentSource == StepDataSource.appleHealthKit) {
      return;
    }

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
        '[StepService] Device reboot detected: counter dropped from $_lastSensorReading to $sensorSteps',
      );
      _accumulatedBeforeReboot = _todaySteps;
      _sensorBaseAtMidnight = sensorSteps;
      await _saveBaseline();
    }

    _lastSensorReading = sensorSteps;
    if (_sensorBaseAtMidnight == null) {
      if (_todaySteps > 0 && sensorSteps >= _todaySteps) {
        _sensorBaseAtMidnight = sensorSteps - _todaySteps;
      } else {
        _sensorBaseAtMidnight = sensorSteps;
      }
      await _saveBaseline();
    }

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
      await _saveBaseline();
    }
  }

  Future<void> _handleMidnightRollover(DateTime now, int sensorSteps) async {
    debugPrint(
      '[StepService] Midnight rollover triggered: yesterday=$_currentDate, today=$now',
    );
    // Seal yesterday's record
    await _persistDay(_currentDate, _todaySteps);

    final midnightBase = _lastSensorReading ?? sensorSteps;

    // Start fresh for new day
    _currentDate = DateTime(now.year, now.month, now.day);
    _accumulatedBeforeReboot = 0;
    _sensorBaseAtMidnight = midnightBase;
    _lastSensorReading = sensorSteps;
    await _saveBaseline();

    final stepsToday = sensorSteps > midnightBase
        ? (sensorSteps - midnightBase)
        : 0;
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
    final distanceKm = StepCalculator.distanceKm(
      steps: steps,
      strideCm: strideLengthCm,
    );
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

    // Sync to Android AppWidget and iOS Widget
    HomeWidgetService.instance
        .syncData(steps: steps, stepGoal: targetSteps, calories: calories)
        .ignore();
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
  final healthService = ref.watch(healthPlatformServiceProvider);
  final service = StepService(
    repository: repo,
    healthPlatformService: healthService,
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
