import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Provides the singleton [LocationService].
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Thin wrapper around [Geolocator] for GPS access.
///
/// Handles permission requests and provides both one-shot and
/// streaming position APIs.
class LocationService {
  /// Checks and requests location permission if needed.
  ///
  /// Returns `true` when permission is granted (either already or
  /// after the user accepts the system dialog).
  Future<bool> ensurePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Gets the current device position.
  ///
  /// Throws a [GeolocatorPlatform] exception if permission is not
  /// granted or location services are disabled.
  Future<Position> getCurrentPosition() {
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  /// Returns a continuous stream of position updates.
  Stream<Position> getPositionStream({
    int distanceFilterMeters = 10,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
      ),
    );
  }
}
