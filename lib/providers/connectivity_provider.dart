import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  ConnectivityProvider() {
    _init();
  }

  Future<void> _init() async {
    final connectivity = Connectivity();
    
    // Check initial status
    final List<ConnectivityResult> result = await connectivity.checkConnectivity();
    _updateStatus(result);

    // Listen for changes
    connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateStatus(results);
    });
  }

  void _updateStatus(List<ConnectivityResult> results) {
    // If any of the results is none, it means we might be offline. 
    // In many real-world scenarios, a single 'none' among multiple (like wifi+mobile) 
    // is rare, but here we check if we have ANY valid connection.
    final bool currentlyOnline = !results.contains(ConnectivityResult.none);
    
    if (_isOnline != currentlyOnline) {
      _isOnline = currentlyOnline;
      notifyListeners();
    }
  }
}