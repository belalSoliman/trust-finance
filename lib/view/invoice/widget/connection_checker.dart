import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:trust_finiance/utils/networt_service.dart';
import 'dart:async'; // Add this import for StreamController

/// Helper class for checking network connectivity with improved reliability
class ConnectionChecker {
  // Cache the last known connection state to avoid too frequent checks
  static bool? _lastKnownConnectionState;
  static DateTime? _lastCheckTime;

  /// Checks if the device is connected to the internet
  ///
  /// Returns true if a connection is available, false otherwise
  static Future<bool> isConnected() async {
    try {
      // If we checked recently (within 3 seconds), return the cached result
      final now = DateTime.now();
      if (_lastCheckTime != null &&
          _lastKnownConnectionState != null &&
          now.difference(_lastCheckTime!).inSeconds < 3) {
        return _lastKnownConnectionState!;
      }

      // Use the centralized network service
      final isOnline = await NetworkStatusService().checkConnection();

      // Cache the result for a short time
      _lastKnownConnectionState = isOnline;
      _lastCheckTime = now;

      return isOnline;
    } catch (e) {
      debugPrint('ConnectionChecker error: $e');
      // If any error occurs, assume we're online (safer default)
      return true;
    }
  }

  // Stream controller to broadcast connectivity changes
  static final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  // Stream initialization flag
  static bool _isStreamInitialized = false;

  /// Listens for connectivity changes
  ///
  /// Returns a Stream that emits true when connected, false when disconnected
  static Stream<bool> get onConnectivityChanged {
    // Initialize the stream if not already done
    if (!_isStreamInitialized) {
      final networkService = NetworkStatusService();

      // Add initial value
      _connectivityController.add(networkService.connectionStatus.value);

      // Listen to changes from ValueNotifier
      networkService.connectionStatus.addListener(() {
        _connectivityController.add(networkService.connectionStatus.value);
      });

      _isStreamInitialized = true;
    }

    return _connectivityController.stream;
  }

  /// Force a refresh of connection status
  static Future<bool> refreshConnectionStatus() async {
    _lastCheckTime = null; // Clear cache
    return await NetworkStatusService().checkConnection();
  }

  /// Current connection status (synchronous, cached value)
  static bool get currentStatus {
    return NetworkStatusService().connectionStatus.value;
  }
}
