import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkStatusService {
  static final NetworkStatusService _instance =
      NetworkStatusService._internal();
  factory NetworkStatusService() => _instance;
  NetworkStatusService._internal();

  // State variables
  bool _forceOnline = false;
  bool _pluginFunctional = true;
  final ValueNotifier<bool> connectionStatus = ValueNotifier<bool>(true);

  // Initialize and test plugin
  Future<void> initialize() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _pluginFunctional = true;
      debugPrint(
          'NetworkStatusService: Plugin working, initial status: $result');

      // Set initial status
      _updateConnectionStatus(result != ConnectivityResult.none);

      // Listen to changes - Updated to handle List<ConnectivityResult>
      Connectivity()
          .onConnectivityChanged
          .listen((List<ConnectivityResult> results) {
        // Check if any result indicates connectivity
        final hasConnectivity =
            results.any((result) => result != ConnectivityResult.none);
        debugPrint('NetworkStatusService: Connectivity changed to $results');
        _verifyInternetConnection(hasConnectivity);
      });
    } catch (e) {
      debugPrint(
          'NetworkStatusService: Plugin not working, using fallback: $e');
      _pluginFunctional = false;
      // Try direct internet check
      _manualInternetCheck();
    }
  }

  // Force online mode for testing/development
  void setForceOnline(bool value) {
    _forceOnline = value;
    if (value) {
      connectionStatus.value = true;
    } else {
      _checkConnection();
    }
  }

  // Manual check when needed
  Future<bool> checkConnection() async {
    if (_forceOnline) return true;
    return await _checkConnection();
  }

  // Internal check implementation
  Future<bool> _checkConnection() async {
    if (_pluginFunctional) {
      try {
        final results = await Connectivity().checkConnectivity();
        // For connectivity_plus 4.0+, result could be a list
        final hasConnectivity = results is List
            ? (results as List<ConnectivityResult>)
                .any((r) => r != ConnectivityResult.none)
            : results != ConnectivityResult.none;

        if (!hasConnectivity) {
          _updateConnectionStatus(false);
          return false;
        } else {
          return await _verifyInternetConnection(true);
        }
      } catch (e) {
        debugPrint('NetworkStatusService: Plugin failed during check: $e');
        _pluginFunctional = false;
        return await _manualInternetCheck();
      }
    } else {
      return await _manualInternetCheck();
    }
  }

  // Try actual internet connection
  Future<bool> _verifyInternetConnection(bool connectedToNetwork) async {
    if (!connectedToNetwork) {
      _updateConnectionStatus(false);
      return false;
    }

    return await _manualInternetCheck();
  }

  // Manual internet check using DNS lookup
  Future<bool> _manualInternetCheck() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      final isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      _updateConnectionStatus(isConnected);
      return isConnected;
    } on SocketException catch (_) {
      _updateConnectionStatus(false);
      return false;
    } catch (e) {
      debugPrint('NetworkStatusService: Manual check failed: $e');
      // If everything fails, assume online to prevent app lockup
      _updateConnectionStatus(true);
      return true;
    }
  }

  void _updateConnectionStatus(bool isConnected) {
    if (connectionStatus.value != isConnected) {
      connectionStatus.value = isConnected;
      debugPrint(
          'NetworkStatusService: Connection status updated to ${isConnected ? "ONLINE" : "OFFLINE"}');
    }
  }
}
