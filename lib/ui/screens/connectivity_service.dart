import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

enum ConnectivityStatus { wifi, mobile, none }

class ConnectivityService {
  // Singleton pattern
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();
  
  final Connectivity _connectivity = Connectivity();
  
  // Stream controller for connectivity status
  final _controller = StreamController<ConnectivityStatus>.broadcast();
<<<<<<< HEAD
  StreamSubscription<List<ConnectivityResult>>? _subscription;
=======
  StreamSubscription<ConnectivityResult>? _subscription;
>>>>>>> parent of e81812a (Initial commit)
  
  // Current status
  ConnectivityStatus _lastStatus = ConnectivityStatus.none;
  ConnectivityStatus get lastStatus => _lastStatus;
  
  // Initialize the service
  void initialize() {
<<<<<<< HEAD
    _subscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      for (var result in results) {
        _updateConnectionStatus(result);
      }
    });
=======
    _subscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
>>>>>>> parent of e81812a (Initial commit)
    _checkInitialConnection();
  }
  
  // Check connectivity status on startup
  Future<void> _checkInitialConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      if (kDebugMode) {
        print('Error checking initial connection: $e');
      }
    }
  }
  
  // Update status based on connectivity result
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
    
    // Only update and notify if status changed
    if (_lastStatus != status) {
      _lastStatus = status;
      _controller.add(status);
      
      if (kDebugMode) {
        print('Connectivity status changed to $status');
      }
    }
  }
  
  // Get connectivity status stream
  Stream<ConnectivityStatus> get statusStream => _controller.stream;
  
  // Check if device is connected
  bool isConnected() {
    return _lastStatus == ConnectivityStatus.wifi || 
           _lastStatus == ConnectivityStatus.mobile;
  }
  
  // Check connectivity on demand
  Future<bool> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
      return result != ConnectivityResult.none;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking connectivity: $e');
      }
      return false;
    }
  }
  
  // Dispose resources
  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}