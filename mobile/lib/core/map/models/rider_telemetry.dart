import 'dart:math';
import 'package:latlong2/latlong.dart';

/// Connection state of a rider in the ride room.
enum RiderConnectionState {
  online,
  reconnecting,
  offline,
}

/// Honest location freshness state strictly based on physical telemetry age.
enum ConvoyFreshness {
  /// <= 15s ago — Green badge
  live,

  /// 16s–90s ago — Amber badge showing exact age
  delayed,

  /// > 90s ago or disconnected — Grey/Red badge with last known coordinates
  offline,

  /// No fix received yet
  unknown,
}

/// Telemetry frame representing a rider's live position and status.
class RiderTelemetry {
  final String riderId;
  final String riderName;
  final LatLng position;
  final double speedKmh;
  final double headingDegrees;
  final double? altitudeMeters;
  final DateTime timestamp;
  final RiderConnectionState connectionState;
  final DateTime? lastSeen;
  final String? bikeModel;

  const RiderTelemetry({
    required this.riderId,
    required this.riderName,
    required this.position,
    this.speedKmh = 0.0,
    this.headingDegrees = 0.0,
    this.altitudeMeters,
    required this.timestamp,
    this.connectionState = RiderConnectionState.online,
    this.lastSeen,
    this.bikeModel,
  });

  bool get isReconnecting => connectionState == RiderConnectionState.reconnecting;
  bool get isOffline => connectionState == RiderConnectionState.offline || freshness == ConvoyFreshness.offline;

  /// Duration since the last received telemetry update.
  Duration get age => DateTime.now().difference(timestamp);

  /// Evaluates honest location freshness strictly from valid timestamp age.
  ConvoyFreshness get freshness {
    final seconds = age.inSeconds;
    if (seconds <= 15) return ConvoyFreshness.live;
    if (seconds <= 90) return ConvoyFreshness.delayed;
    return ConvoyFreshness.offline;
  }

  /// User-facing badge label: "LIVE", "42s ago", or "OFFLINE (Last known NH3)"
  String get freshnessDisplay {
    switch (freshness) {
      case ConvoyFreshness.live:
        return 'LIVE';
      case ConvoyFreshness.delayed:
        return '${age.inSeconds}s ago';
      case ConvoyFreshness.offline:
        return 'OFFLINE (${(age.inMinutes > 0 ? "${age.inMinutes}m" : "${age.inSeconds}s")} ago)';
      case ConvoyFreshness.unknown:
        return 'UNKNOWN';
    }
  }

  RiderTelemetry copyWith({
    String? riderId,
    String? riderName,
    LatLng? position,
    double? speedKmh,
    double? headingDegrees,
    double? altitudeMeters,
    DateTime? timestamp,
    RiderConnectionState? connectionState,
    DateTime? lastSeen,
    String? bikeModel,
  }) {
    return RiderTelemetry(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      position: position ?? this.position,
      speedKmh: speedKmh ?? this.speedKmh,
      headingDegrees: headingDegrees ?? this.headingDegrees,
      altitudeMeters: altitudeMeters ?? this.altitudeMeters,
      timestamp: timestamp ?? this.timestamp,
      connectionState: connectionState ?? this.connectionState,
      lastSeen: lastSeen ?? this.lastSeen,
      bikeModel: bikeModel ?? this.bikeModel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rider_id': riderId,
      'rider_name': riderName,
      'lat': position.latitude,
      'lng': position.longitude,
      'speed': speedKmh,
      'heading': headingDegrees,
      'altitude': altitudeMeters,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory RiderTelemetry.fromJson(Map<String, dynamic> json) {
    return RiderTelemetry(
      riderId: json['rider_id'] as String? ?? 'unknown',
      riderName: json['rider_name'] as String? ?? 'Rider',
      position: LatLng(
        (json['lat'] as num?)?.toDouble() ?? 0.0,
        (json['lng'] as num?)?.toDouble() ?? 0.0,
      ),
      speedKmh: (json['speed'] as num?)?.toDouble() ?? 0.0,
      headingDegrees: (json['heading'] as num?)?.toDouble() ?? 0.0,
      altitudeMeters: (json['altitude'] as num?)?.toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      connectionState: RiderConnectionState.online,
    );
  }
}

/// Hysteresis Separation Monitor to prevent alert fatigue in mountain hairpins.
class SeparationMonitor {
  static const double triggerThresholdMeters = 1500.0;
  static const double clearThresholdMeters = 1100.0;
  static const Duration sustainedDuration = Duration(seconds: 45);
  static const Duration alertCooldown = Duration(seconds: 180);

  DateTime? _separationStartTime;
  DateTime? _lastAlertTime;
  bool _alertActive = false;

  bool get isAlertActive => _alertActive;

  /// Evaluates pack separation between rider and lead.
  /// Returns non-null advisory string if a fresh separation alert should be displayed.
  String? evaluate({
    required LatLng riderPosition,
    required LatLng leadPosition,
  }) {
    final dist = const Distance().as(
      LengthUnit.Meter,
      riderPosition,
      leadPosition,
    );

    final now = DateTime.now();

    if (dist >= triggerThresholdMeters) {
      _separationStartTime ??= now;
      final elapsed = now.difference(_separationStartTime!);

      if (elapsed >= sustainedDuration) {
        final canAlert = _lastAlertTime == null ||
            now.difference(_lastAlertTime!) >= alertCooldown;

        if (canAlert && !_alertActive) {
          _alertActive = true;
          _lastAlertTime = now;
          return 'Pack separation > 1.5 km (${(dist / 1000).toStringAsFixed(1)} km) sustained for ${elapsed.inSeconds}s — Suggest Convoy Check-In';
        }
      }
    } else if (dist < clearThresholdMeters) {
      // Clear hysteresis
      _separationStartTime = null;
      _alertActive = false;
    }

    return null;
  }

  void reset() {
    _separationStartTime = null;
    _lastAlertTime = null;
    _alertActive = false;
  }
}
