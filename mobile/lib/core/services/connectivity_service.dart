import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emits `true` when the device has an active network connection.
final connectivityProvider = StreamProvider<bool>((ref) {
  return ConnectivityService().onConnectivityChanged;
});

/// Wraps [Connectivity] to provide a simple online / offline stream.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Stream that emits `true` when online, `false` when offline.
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((results) {
      return results.any((r) => r != ConnectivityResult.none);
    });
  }

  /// One-shot check for current connectivity.
  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }
}
