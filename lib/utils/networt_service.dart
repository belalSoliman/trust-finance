import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkStatusService {
  static final NetworkStatusService _instance =
      NetworkStatusService._internal();
  factory NetworkStatusService() => _instance;
  NetworkStatusService._internal();

  bool _forceOnline = false;
  bool _pluginFunctional = true;
  final ValueNotifier<bool> connectionStatus = ValueNotifier<bool>(true);

  Future<void> initialize() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _pluginFunctional = true;
      debugPrint(
          'NetworkStatusService: Plugin working, initial status: $result');

      final hasConnectivity = result.any((r) => r != ConnectivityResult.none);
      _updateConnectionStatus(hasConnectivity);

      Connectivity()
          .onConnectivityChanged
          .listen((List<ConnectivityResult> results) {
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

  void setForceOnline(bool value) {
    _forceOnline = value;
    if (value) {
      connectionStatus.value = true;
    } else {
      _checkConnection();
    }
  }

  Future<bool> checkConnection() async {
    if (_forceOnline) return true;
    return await _checkConnection();
  }

  Future<bool> _checkConnection() async {
    if (_pluginFunctional) {
      try {
        final results = await Connectivity().checkConnectivity();
        final hasConnectivity =
            results.any((r) => r != ConnectivityResult.none);

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

  Future<bool> _verifyInternetConnection(bool connectedToNetwork) async {
    if (!connectedToNetwork) {
      _updateConnectionStatus(false);
      return false;
    }

    return await _manualInternetCheck();
  }

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
