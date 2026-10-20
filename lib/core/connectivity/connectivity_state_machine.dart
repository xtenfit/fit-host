import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../services/supabase_service.dart';

enum ConnectivityStatus {
  checking,
  online,
  offline,
  metered,
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

  ConnectivityStateMachine({
    Connectivity? connectivity,
    InternetConnectionChecker? connectionChecker,
    String? supabaseUrl,
  })  : _connectivity = connectivity ?? Connectivity(),
        _connectionChecker =
            connectionChecker ?? InternetConnectionChecker.createInstance(),
        _supabaseUrl = supabaseUrl ?? getSupabaseUrl() {
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  ConnectivityStatus get currentStatus => _currentStatus;
  Stream<ConnectivityStatus> get statusStream => _controller.stream;

  void _init() {
    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      checkConnectivity();
    });
    checkConnectivity();
    _startHeartbeat();
  }

  Future<ConnectivityStatus> checkConnectivity() async {
    _updateStatus(ConnectivityStatus.checking);
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.contains(ConnectivityResult.none) && results.length == 1) {
        _updateStatus(ConnectivityStatus.offline);
        return ConnectivityStatus.offline;
      }

      final isMetered = results.contains(ConnectivityResult.mobile);

      // Perform reachability check
      final hasInternet = kIsWeb ? true : await _connectionChecker.hasConnection;
      if (!hasInternet) {
        _updateStatus(ConnectivityStatus.offline);
        return ConnectivityStatus.offline;
      }

      final status = isMetered ? ConnectivityStatus.metered : ConnectivityStatus.online;
      _updateStatus(status);
      return status;
    } catch (_) {
      _updateStatus(ConnectivityStatus.offline);
      return ConnectivityStatus.offline;
    }
  }

  /// Pings Supabase health endpoint: ${SUPABASE_URL}/auth/v1/health
  Future<bool> pingSupabaseHealth() async {
    if (kIsWeb) return true;
    if (_supabaseUrl.isEmpty) return false;
    try {
      final uri = Uri.parse('$_supabaseUrl/auth/v1/health');
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);
      final request = await client.getUrl(uri);
      final response = await request.close();
      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (_) {
      return false;
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    if (!_isForegrounded || kIsWeb) return;

    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (!_isForegrounded) return;
      final isHealthy = await pingSupabaseHealth();
      if (!isHealthy && _currentStatus != ConnectivityStatus.offline) {
        // Double check general connectivity
        final hasConnection = await _connectionChecker.hasConnection;
        if (!hasConnection) {
          _updateStatus(ConnectivityStatus.offline);
        }
      } else if (isHealthy && _currentStatus == ConnectivityStatus.offline) {
        _updateStatus(ConnectivityStatus.online);
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
    WidgetsBinding.instance.removeObserver(this);
    _stopHeartbeat();
    _connectivitySub?.cancel();
    _controller.close();
  }
}

final connectivityStateMachineProvider = Provider<ConnectivityStateMachine>((ref) {
  final machine = ConnectivityStateMachine();
  ref.onDispose(() => machine.dispose());
  return machine;
});

final connectivityProvider = StreamProvider<ConnectivityStatus>((ref) {
  final machine = ref.watch(connectivityStateMachineProvider);
  return machine.statusStream;
});
