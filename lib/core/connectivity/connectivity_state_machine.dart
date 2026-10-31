import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../services/supabase_service.dart';

enum ConnectivityStatus { checking, online, offline, metered }

ConnectivityStatus connectivityStatusFor({
  required List<ConnectivityResult> results,
  required bool hasInternet,
}) {
  if (results.isEmpty ||
      (results.contains(ConnectivityResult.none) && results.length == 1) ||
      !hasInternet) {
    return ConnectivityStatus.offline;
  }
  return results.contains(ConnectivityResult.mobile)
      ? ConnectivityStatus.metered
      : ConnectivityStatus.online;
}

class ConnectivityStateMachine with WidgetsBindingObserver {
  final Connectivity _connectivity;
  final InternetConnectionChecker _connectionChecker;
  final String _supabaseUrl;

  final StreamController<ConnectivityStatus> _controller =
      StreamController<ConnectivityStatus>.broadcast();
  ConnectivityStatus _currentStatus = ConnectivityStatus.checking;
  Timer? _heartbeatTimer;
  StreamSubscription? _connectivitySub;
  bool _isForegrounded = true;
  bool _isDisposed = false;
  int _checkGeneration = 0;

  ConnectivityStateMachine({
    Connectivity? connectivity,
    InternetConnectionChecker? connectionChecker,
    String? supabaseUrl,
  }) : _connectivity = connectivity ?? Connectivity(),
       _connectionChecker =
           connectionChecker ?? InternetConnectionChecker.createInstance(),
       _supabaseUrl = supabaseUrl ?? getSupabaseUrl() {
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  ConnectivityStatus get currentStatus => _currentStatus;
  Stream<ConnectivityStatus> get statusStream => _controller.stream;

  void _init() {
    _connectivitySub = _connectivity.onConnectivityChanged.listen(
      (results) {
        checkConnectivity();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint(
          '[ConnectivityStateMachine] Connectivity stream error: $error',
        );
        _updateStatus(ConnectivityStatus.offline);
      },
    );
    checkConnectivity();
    _startHeartbeat();
  }

  Future<ConnectivityStatus> checkConnectivity() async {
    final generation = ++_checkGeneration;
    _updateStatus(ConnectivityStatus.checking);
    try {
      final results = await _connectivity.checkConnectivity();
      final hasInternet = kIsWeb
          ? true
          : await _connectionChecker.hasConnection;
      final status = connectivityStatusFor(
        results: results,
        hasInternet: hasInternet,
      );
      if (generation == _checkGeneration && !_isDisposed) {
        _updateStatus(status);
      }
      return status;
    } catch (error, stackTrace) {
      debugPrint(
        '[ConnectivityStateMachine] Connectivity check failed: $error\n$stackTrace',
      );
      if (generation == _checkGeneration && !_isDisposed) {
        _updateStatus(ConnectivityStatus.offline);
      }
      return ConnectivityStatus.offline;
    }
  }

  /// Pings Supabase health endpoint: ${SUPABASE_URL}/auth/v1/health
  Future<bool> pingSupabaseHealth() async {
    if (kIsWeb) return true;
    if (_supabaseUrl.isEmpty) return false;
    final client = HttpClient();
    try {
      final uri = Uri.parse('$_supabaseUrl/auth/v1/health');
      client.connectionTimeout = const Duration(seconds: 4);
      final request = await client.getUrl(uri);
      final response = await request.close();
      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (error, stackTrace) {
      debugPrint(
        '[ConnectivityStateMachine] Supabase health check failed: $error\n$stackTrace',
      );
      return false;
    } finally {
      client.close(force: true);
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    if (!_isForegrounded || kIsWeb) return;

    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (!_isForegrounded || _isDisposed) return;
      final isHealthy = await pingSupabaseHealth();
      if (!_isForegrounded || _isDisposed) return;
      if (!isHealthy && _currentStatus != ConnectivityStatus.offline) {
        // Double check general connectivity
        final hasConnection = await _connectionChecker.hasConnection;
        if (!hasConnection && !_isDisposed) {
          _updateStatus(ConnectivityStatus.offline);
        }
      } else if (isHealthy && _currentStatus == ConnectivityStatus.offline) {
        await checkConnectivity();
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _updateStatus(ConnectivityStatus status) {
    _currentStatus = status;
    if (!_controller.isClosed) {
      _controller.add(status);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isForegrounded = true;
      checkConnectivity();
      _startHeartbeat();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _isForegrounded = false;
      _stopHeartbeat();
    }
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _checkGeneration++;
    WidgetsBinding.instance.removeObserver(this);
    _stopHeartbeat();
    _connectivitySub?.cancel();
    _controller.close();
  }
}

final connectivityStateMachineProvider = Provider<ConnectivityStateMachine>((
  ref,
) {
  final machine = ConnectivityStateMachine();
  ref.onDispose(() => machine.dispose());
  return machine;
});

final connectivityProvider = StreamProvider<ConnectivityStatus>((ref) {
  final machine = ref.watch(connectivityStateMachineProvider);
  return machine.statusStream;
});
