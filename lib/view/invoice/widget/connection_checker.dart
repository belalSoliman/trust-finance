import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:trust_finiance/utils/networt_service.dart';
import 'dart:async';

class ConnectionChecker {
  static bool? _lastKnownConnectionState;
  static DateTime? _lastCheckTime;

  static Future<bool> isConnected() async {
    try {
      final now = DateTime.now();
      if (_lastCheckTime != null &&
          _lastKnownConnectionState != null &&
          now.difference(_lastCheckTime!).inSeconds < 3) {
        return _lastKnownConnectionState!;
      }

      final isOnline = await NetworkStatusService().checkConnection();

      _lastKnownConnectionState = isOnline;
      _lastCheckTime = now;

      return isOnline;
    } catch (e) {
      debugPrint('ConnectionChecker error: $e');

      return true;
    }
  }

  static final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  static bool _isStreamInitialized = false;

  static Stream<bool> get onConnectivityChanged {
    if (!_isStreamInitialized) {
      final networkService = NetworkStatusService();

      _connectivityController.add(networkService.connectionStatus.value);

      networkService.connectionStatus.addListener(() {
        _connectivityController.add(networkService.connectionStatus.value);
      });

      _isStreamInitialized = true;
    }

    return _connectivityController.stream;
  }

  static Future<bool> refreshConnectionStatus() async {
    _lastCheckTime = null;
    return await NetworkStatusService().checkConnection();
  }

  static bool get currentStatus {
    return NetworkStatusService().connectionStatus.value;
  }
}
