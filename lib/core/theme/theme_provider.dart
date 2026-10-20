import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _prefKey = 'fit_host_theme_mode';
  final _storage = const FlutterSecureStorage();

  @override
  ThemeMode build() {
    _loadPersistedMode();
    return ThemeMode.dark;
  }

  Future<void> _loadPersistedMode() async {
    try {
      final saved = await _storage.read(key: _prefKey);
      if (saved != null) {
        if (saved == 'light') {
          state = ThemeMode.light;
        } else if (saved == 'dark') {
          state = ThemeMode.dark;
        } else if (saved == 'system') {
          state = ThemeMode.system;
        }
      }
    } catch (_) {}
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    try {
      await _storage.write(key: _prefKey, value: mode.name);
    } catch (_) {}
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
