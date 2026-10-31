import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';

enum StepDataSource { healthConnect, appleHealthKit, hardwareSensor, manual }

extension StepDataSourceX on StepDataSource {
  String get displayName {
    switch (this) {
      case StepDataSource.healthConnect:
        return 'Android Health Connect';
      case StepDataSource.appleHealthKit:
        return 'Apple HealthKit';
      case StepDataSource.hardwareSensor:
        return 'Device Hardware Pedometer';
      case StepDataSource.manual:
        return 'Manual Entry';
    }
  }

  String get dbValue {
    switch (this) {
      case StepDataSource.healthConnect:
        return 'health_connect';
      case StepDataSource.appleHealthKit:
        return 'health_kit';
      case StepDataSource.hardwareSensor:
        return 'hardware_sensor';
      case StepDataSource.manual:
        return 'manual';
    }
  }

  static StepDataSource fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'health_connect':
        return StepDataSource.healthConnect;
      case 'health_kit':
      case 'healthkit':
        return StepDataSource.appleHealthKit;
      case 'manual':
        return StepDataSource.manual;
      case 'hardware_sensor':
      default:
        return StepDataSource.hardwareSensor;
    }
  }
}

class HealthDataSyncResult {
  final int steps;
  final StepDataSource source;
  final DateTime synchronizedAt;
  final bool isAggregated;

  const HealthDataSyncResult({
    required this.steps,
    required this.source,
    required this.synchronizedAt,
    this.isAggregated = true,
  });
}

abstract class HealthPlatformService {
  StepDataSource get preferredSource;
  Future<bool> isPlatformAvailable();
  Future<bool> requestPermissions();
  Future<bool> hasPermissions();
  Future<HealthDataSyncResult?> fetchDailyAggregateSteps(DateTime localDate);
}

class DefaultHealthPlatformService implements HealthPlatformService {
  final Future<int?> Function(DateTime start, DateTime end)?
  customAggregateFetcher;
  final Health _health;
  bool _configured = false;

  DefaultHealthPlatformService({this.customAggregateFetcher, Health? health})
    : _health = health ?? Health();

  @override
  StepDataSource get preferredSource {
    if (!kIsWeb && Platform.isAndroid) return StepDataSource.healthConnect;
    if (!kIsWeb && Platform.isIOS) return StepDataSource.appleHealthKit;
    return StepDataSource.hardwareSensor;
  }

  @override
  Future<bool> isPlatformAvailable() async {
    if (kIsWeb) return false;
    if (!Platform.isAndroid) return false;
    await _configure();
    return await _health.getHealthConnectSdkStatus() ==
        HealthConnectSdkStatus.sdkAvailable;
  }

  @override
  Future<bool> requestPermissions() async {
    await _configure();
    if (!await isPlatformAvailable()) return false;
    return _health.requestAuthorization(
      [HealthDataType.STEPS],
      permissions: [HealthDataAccess.READ],
    );
  }

  @override
  Future<bool> hasPermissions() async {
    if (!await isPlatformAvailable()) return false;
    await _configure();
    try {
      final hasPerm = await _health.hasPermissions(
        [HealthDataType.STEPS],
        permissions: [HealthDataAccess.READ],
      );
      return hasPerm == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> revokePermissions() async {
    if (!await isPlatformAvailable()) return;
    await _configure();
    await _health.revokePermissions();
  }

  @override
  Future<HealthDataSyncResult?> fetchDailyAggregateSteps(
    DateTime localDate,
  ) async {
    final startOfDay = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
      0,
      0,
      0,
    );
    final endOfDay = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
      23,
      59,
      59,
      999,
    );

    if (customAggregateFetcher != null) {
      final steps = await customAggregateFetcher!(startOfDay, endOfDay);
      if (steps != null) {
        return HealthDataSyncResult(
          steps: steps,
          source: preferredSource,
          synchronizedAt: DateTime.now(),
          isAggregated: true,
        );
      }
    }

    if (!await isPlatformAvailable()) return null;
    await _configure();
    final hasPermission = await _health.hasPermissions(
      [HealthDataType.STEPS],
      permissions: [HealthDataAccess.READ],
    );
    if (hasPermission != true) return null;

    final steps = await _health.getTotalStepsInInterval(startOfDay, endOfDay);
    if (steps == null) return null;
    return HealthDataSyncResult(
      steps: steps,
      source: StepDataSource.healthConnect,
      synchronizedAt: DateTime.now(),
    );
  }

  Future<void> _configure() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }
}

final healthPlatformServiceProvider = Provider<HealthPlatformService>((ref) {
  return DefaultHealthPlatformService();
});
