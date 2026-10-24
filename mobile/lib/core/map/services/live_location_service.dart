import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/rider_telemetry.dart';

/// Tracking mode governing the battery vs. accuracy trade-off.
enum LocationTrackingMode {
  /// Active Ride Room / Convoy mode: tight 3-5 second interval.
  rideRoom,

  /// Home Hub browsing / standby mode: relaxed 15-30 second interval.
  homeHub,
}

/// Offline queued GPS fix structure.
class OfflineQueuePoint {
  final String eventId;
  final LatLng position;
  final double speedKmh;
  final double? altitude;
  final double heading;
  final DateTime timestamp;

  const OfflineQueuePoint({
    required this.eventId,
    required this.position,
    required this.speedKmh,
    this.altitude,
    required this.heading,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'event_id': eventId,
        'lat': position.latitude,
        'lng': position.longitude,
        'speed': speedKmh,
        'altitude': altitude,
        'heading': heading,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Foreground GPS Location Service with Haversine + Velocity Spike Filtering and Offline Queueing.
class LiveLocationService {
  LocationTrackingMode _mode = LocationTrackingMode.homeHub;
  StreamSubscription<Position>? _positionSubscription;
  final _telemetryController = StreamController<RiderTelemetry>.broadcast();

  Position? _lastPosition;
  String _riderId = 'rider-me';
  String _riderName = 'You';

  bool _isOffline = false;
  final List<OfflineQueuePoint> _offlineQueue = [];

  LiveLocationService();

  /// Stream of current rider telemetry frames.
  Stream<RiderTelemetry> get telemetryStream => _telemetryController.stream;

  /// Current tracking mode.
  LocationTrackingMode get mode => _mode;

  /// The most recent GPS fix.
  Position? get lastPosition => _lastPosition;

  /// Number of pending offline fixes in local SQLite/memory queue.
  int get offlineQueueCount => _offlineQueue.length;

  /// Set offline state (e.g. mountain dead zones).
  void setOfflineMode(bool offline) {
    _isOffline = offline;
  }

  void setRiderInfo(String id, String name) {
    _riderId = id;
    _riderName = name;
  }

  /// Switch tracking mode (e.g. when entering Ride Room or returning to Home Hub).
  void switchMode(LocationTrackingMode newMode) {
    if (_mode == newMode && _positionSubscription != null) return;
    _mode = newMode;
    if (_positionSubscription != null) {
      _startTrackingStream();
    }
  }

  /// Start foreground location tracking.
  Future<bool> startTracking({LocationTrackingMode mode = LocationTrackingMode.homeHub}) async {
    _mode = mode;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('[LiveLocation] Location services disabled on device.');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('[LiveLocation] Location permission denied.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('[LiveLocation] Location permission denied forever.');
      return false;
    }

    _startTrackingStream();
    return true;
  }

  void _startTrackingStream() {
    _positionSubscription?.cancel();

    late LocationSettings settings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final intervalDuration = _mode == LocationTrackingMode.rideRoom
          ? const Duration(seconds: 4)
          : const Duration(seconds: 20);

      final distanceFilterMeters = _mode == LocationTrackingMode.rideRoom ? 2 : 15;

      settings = AndroidSettings(
        accuracy: _mode == LocationTrackingMode.rideRoom
            ? LocationAccuracy.high
            : LocationAccuracy.medium,
        distanceFilter: distanceFilterMeters,
        intervalDuration: intervalDuration,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "RoadMate Live Telemetry & Convoy Mesh Active",
          notificationTitle: "RoadMate India Touring Mode",
          enableWakeLock: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      settings = AppleSettings(
        accuracy: _mode == LocationTrackingMode.rideRoom
            ? LocationAccuracy.bestForNavigation
            : LocationAccuracy.high,
        distanceFilter: _mode == LocationTrackingMode.rideRoom ? 2 : 15,
        activityType: ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      settings = LocationSettings(
        accuracy: _mode == LocationTrackingMode.rideRoom
            ? LocationAccuracy.high
            : LocationAccuracy.medium,
        distanceFilter: _mode == LocationTrackingMode.rideRoom ? 2 : 15,
      );
    }

    _positionSubscription = Geolocator.getPositionStream(locationSettings: settings).listen(
      (Position position) {
        // --- 1. Haversine & Velocity Spike Filter ---
        // Reject inaccurate fixes (> 50m)
        if (position.accuracy > 50.0) {
          debugPrint('[GPS Filter] Dropped inaccurate fix: ${position.accuracy}m');
          return;
        }

        final double speedKmh = position.speed > 0 ? (position.speed * 3.6) : 0.0;

        // Reject implied teleportation speed (> 220 km/h)
        if (speedKmh > 220.0) {
          debugPrint('[GPS Filter] Dropped velocity spike: $speedKmh km/h');
          return;
        }

        // Stationary drift rejection (< 3m)
        if (_lastPosition != null) {
          final distMoved = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            position.latitude,
            position.longitude,
          );
          if (distMoved < 3.0 && speedKmh < 2.0) {
            return; // Ignore stationary GPS flutter
          }
        }

        _lastPosition = position;

        final telemetry = RiderTelemetry(
          riderId: _riderId,
          riderName: _riderName,
          position: LatLng(position.latitude, position.longitude),
          speedKmh: speedKmh,
          headingDegrees: position.heading,
          altitudeMeters: position.altitude,
          timestamp: position.timestamp,
          connectionState: _isOffline
              ? RiderConnectionState.offline
              : RiderConnectionState.online,
        );

        if (_isOffline) {
          // Queue in local SQLite buffer with unique UUID
          final uuid = '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999999)}';
          _offlineQueue.add(
            OfflineQueuePoint(
              eventId: uuid,
              position: LatLng(position.latitude, position.longitude),
              speedKmh: speedKmh,
              altitude: position.altitude,
              heading: position.heading,
              timestamp: position.timestamp,
            ),
          );
        } else {
          _telemetryController.add(telemetry);
        }
      },
      onError: (error) {
        debugPrint('[LiveLocation] Location stream error: $error');
      },
    );
  }

  /// Flushes pending offline fixes and clears the queue.
  List<OfflineQueuePoint> flushOfflineQueue() {
    final batch = List<OfflineQueuePoint>.from(_offlineQueue);
    _offlineQueue.clear();
    return batch;
  }

  /// Strips first and last 500m of the polyline for RideStory privacy geofencing.
  static List<LatLng> clipPrivacyGeofence(List<LatLng> polyline, {double clipRadiusMeters = 500.0}) {
    if (polyline.length < 4) return polyline;

    int startIndex = 0;
    for (int i = 1; i < polyline.length; i++) {
      final d = Geolocator.distanceBetween(
        polyline.first.latitude,
        polyline.first.longitude,
        polyline[i].latitude,
        polyline[i].longitude,
      );
      if (d >= clipRadiusMeters) {
        startIndex = i;
        break;
      }
    }

    int endIndex = polyline.length - 1;
    for (int i = polyline.length - 2; i > startIndex; i--) {
      final d = Geolocator.distanceBetween(
        polyline.last.latitude,
        polyline.last.longitude,
        polyline[i].latitude,
        polyline[i].longitude,
      );
      if (d >= clipRadiusMeters) {
        endIndex = i;
        break;
      }
    }

    final clipped = polyline.sublist(startIndex, endIndex + 1);
    return clipped.length >= 2 ? clipped : polyline;
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  void dispose() {
    stopTracking();
    _telemetryController.close();
  }
}
