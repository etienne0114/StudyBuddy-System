import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

enum ConnectivityStatus { wifi, mobile, none }

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();

  final _controller = StreamController<ConnectivityStatus>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityStatus _lastStatus = ConnectivityStatus.none;
  ConnectivityStatus get lastStatus => _lastStatus;

  void initialize() {
    _subscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      _updateConnectionStatus(result);
    });
    _checkInitialConnection();
  }

  Future<void> _checkInitialConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      _updateConnectionStatus(result);
    } catch (e) {
      if (kDebugMode) {
        print('Error checking initial connection: $e');
      }
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    ConnectivityStatus status;

    switch (result) {
      case ConnectivityResult.wifi:
        status = ConnectivityStatus.wifi;
        break;
      case ConnectivityResult.mobile:
        status = ConnectivityStatus.mobile;
        break;
      default:
        status = ConnectivityStatus.none;
        break;
    }

    if (_lastStatus != status) {
      _lastStatus = status;
      _controller.add(status);

      if (kDebugMode) {
        print('Connectivity status changed to $status');
      }
    }
  }

  Stream<ConnectivityStatus> get statusStream => _controller.stream;

  bool isConnected() {
    return _lastStatus == ConnectivityStatus.wifi ||
           _lastStatus == ConnectivityStatus.mobile;
  }

  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      _updateConnectionStatus(result);
      return result != ConnectivityResult.none;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking connectivity: $e');
      }
      
      return false;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
