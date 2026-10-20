import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

abstract class ConnectivityService {
  Future<bool> hasInternetConnection();
  Stream<bool> get onConnectivityChanged;
}

class ConnectivityServiceImpl implements ConnectivityService {
  final Connectivity _connectivity;
  final InternetConnectionChecker _connectionChecker;
  StreamController<bool>? _controller;

  ConnectivityServiceImpl({
    Connectivity? connectivity,
    InternetConnectionChecker? connectionChecker,
  })  : _connectivity = connectivity ?? Connectivity(),
        _connectionChecker =
            connectionChecker ?? InternetConnectionChecker.createInstance();

  @override
  Future<bool> hasInternetConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.contains(ConnectivityResult.none) && results.length == 1) {
        return false;
      }
      if (kIsWeb) return true;
      return await _connectionChecker.hasConnection;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<bool> get onConnectivityChanged {
    _controller ??= StreamController<bool>.broadcast(
      onListen: () {
        _connectivity.onConnectivityChanged.listen((_) async {
          final connected = await hasInternetConnection();
          if (!(_controller?.isClosed ?? true)) {
            _controller?.add(connected);
          }
        });
      },
    );
    return _controller!.stream;
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityServiceImpl();
});

final isOnlineStreamProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onConnectivityChanged;
});
