import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../features/steps/data/health_platform_service.dart';
import '../../../features/steps/presentation/controllers/step_controller.dart';

enum HealthConnectScreenState {
  unavailable,
  permissionRequired,
  connected,
  syncing,
  error,
}

final healthConnectScreenProvider =
    NotifierProvider<HealthConnectScreenController, HealthConnectScreenState>(
      HealthConnectScreenController.new,
    );

class HealthConnectScreenController extends Notifier<HealthConnectScreenState> {
  final DefaultHealthPlatformService _service = DefaultHealthPlatformService();

  @override
  HealthConnectScreenState build() {
    Future.microtask(refresh);
    return HealthConnectScreenState.permissionRequired;
  }

  Future<void> refresh() async {
    if (kIsWeb ||
        !Platform.isAndroid ||
        !await _service.isPlatformAvailable()) {
      state = HealthConnectScreenState.unavailable;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('health_connect_steps_enabled') == true
        ? HealthConnectScreenState.connected
        : HealthConnectScreenState.permissionRequired;
  }

  Future<void> connect() async {
    state = HealthConnectScreenState.syncing;
    try {
      final granted = await _service.requestPermissions();
      if (!granted) {
        state = HealthConnectScreenState.permissionRequired;
        return;
      }
      final result = await _service.fetchDailyAggregateSteps(DateTime.now());
      if (result == null) {
        state = HealthConnectScreenState.error;
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('health_connect_steps_enabled', true);
      await prefs.setString(
        'health_connect_last_sync',
        result.synchronizedAt.toIso8601String(),
      );
      await ref
          .read(stepControllerProvider.notifier)
          .refreshFromHealthPlatform();
      state = HealthConnectScreenState.connected;
    } catch (_) {
      state = HealthConnectScreenState.error;
    }
  }

  Future<void> syncNow() async {
    state = HealthConnectScreenState.syncing;
    try {
      final result = await _service.fetchDailyAggregateSteps(DateTime.now());
      if (result == null) {
        state = HealthConnectScreenState.permissionRequired;
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'health_connect_last_sync',
        result.synchronizedAt.toIso8601String(),
      );
      await ref
          .read(stepControllerProvider.notifier)
          .refreshFromHealthPlatform();
      state = HealthConnectScreenState.connected;
    } catch (_) {
      state = HealthConnectScreenState.error;
    }
  }

  Future<void> disconnect() async {
    try {
      await _service.revokePermissions();
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('health_connect_steps_enabled');
      await prefs.remove('health_connect_last_sync');
      state = HealthConnectScreenState.permissionRequired;
    }
  }
}

class HealthConnectSettingsScreen extends ConsumerWidget {
  const HealthConnectSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(healthConnectScreenProvider);
    final controller = ref.read(healthConnectScreenProvider.notifier);
    final theme = Theme.of(context);
    final connected = state == HealthConnectScreenState.connected;
    final busy = state == HealthConnectScreenState.syncing;

    return Scaffold(
      appBar: AppBar(title: const Text('Health Connect')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(
            Icons.health_and_safety_outlined,
            size: 56,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            _title(state),
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Fit Host reads your daily steps from Android Health Connect. '
            'It does not write workouts, meals, hydration, or health records '
            'back to Health Connect.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (state == HealthConnectScreenState.unavailable)
            _InfoCard(
              icon: Icons.info_outline,
              text:
                  'Health Connect is available only on supported Android devices.',
            ),
          if (state == HealthConnectScreenState.error)
            _InfoCard(
              icon: Icons.error_outline,
              text:
                  'Fit Host could not verify Health Connect. Check the provider and try again.',
            ),
          if (connected)
            _InfoCard(
              icon: Icons.check_circle_outline,
              text:
                  'Steps are connected. Calendar, workouts, meals, and hydration remain separate Fit Host records.',
            ),
          if (state == HealthConnectScreenState.permissionRequired)
            FilledButton.icon(
              onPressed: controller.connect,
              icon: const Icon(Icons.link),
              label: const Text('Connect Health Connect'),
            ),
          if (busy)
            const Center(child: CircularProgressIndicator())
          else if (connected) ...[
            FilledButton.icon(
              onPressed: controller.syncNow,
              icon: const Icon(Icons.sync),
              label: const Text('Sync steps now'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: controller.disconnect,
              child: const Text('Disconnect'),
            ),
          ] else if (state == HealthConnectScreenState.error)
            OutlinedButton(
              onPressed: controller.connect,
              child: const Text('Try again'),
            ),
        ],
      ),
    );
  }

  String _title(HealthConnectScreenState state) {
    switch (state) {
      case HealthConnectScreenState.unavailable:
        return 'Health Connect unavailable';
      case HealthConnectScreenState.permissionRequired:
        return 'Connect your health data';
      case HealthConnectScreenState.connected:
        return 'Health Connect connected';
      case HealthConnectScreenState.syncing:
        return 'Syncing health data';
      case HealthConnectScreenState.error:
        return 'Connection needs attention';
    }
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
