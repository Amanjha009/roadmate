import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:roadmate_india/core/map/models/hazard_pin.dart';
import 'package:roadmate_india/core/map/models/rider_telemetry.dart';
import 'package:roadmate_india/core/map/services/position_interpolator.dart';
import 'package:roadmate_india/core/map/services/viewport_hazard_service.dart';

void main() {
  group('HazardPin Model & Auto-Expiry Tests', () {
    test('HazardPin correctly identifies active vs expired pins', () {
      final now = DateTime.now();

      final activePin = HazardPin(
        id: 'hz-1',
        type: HazardType.landslide,
        severity: HazardSeverity.high,
        position: const LatLng(32.3712, 77.2144),
        createdAt: now.subtract(const Duration(minutes: 10)),
        expiresAt: now.add(const Duration(minutes: 50)),
      );

      final expiredPin = HazardPin(
        id: 'hz-2',
        type: HazardType.pothole,
        severity: HazardSeverity.medium,
        position: const LatLng(32.2412, 77.1852),
        createdAt: now.subtract(const Duration(hours: 3)),
        expiresAt: now.subtract(const Duration(minutes: 2)), // expired 2m ago
      );

      expect(activePin.isExpired, isFalse);
      expect(expiredPin.isExpired, isTrue);
      expect(activePin.displayIcon, equals('🚨'));
    });

    test('HazardPin parses JSON from REST backend correctly', () {
      final json = {
        'id': 'a816-test-uuid',
        'hazard_type': 'landslide',
        'severity': 'critical',
        'latitude': 32.3712,
        'longitude': 77.2144,
        'description': 'Massive rockfall on hairpin 4',
        'confidence_score': 0.98,
        'expires_at': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'upvotes': 14,
        'downvotes': 1,
      };

      final pin = HazardPin.fromJson(json);
      expect(pin.id, equals('a816-test-uuid'));
      expect(pin.type, equals(HazardType.landslide));
      expect(pin.severity, equals(HazardSeverity.critical));
      expect(pin.position.latitude, closeTo(32.3712, 0.0001));
      expect(pin.position.longitude, closeTo(77.2144, 0.0001));
      expect(pin.upvotes, equals(14));
      expect(pin.isExpired, isFalse);
    });
  });

  group('RiderTelemetry Model Tests', () {
    test('RiderTelemetry JSON serialization and connection states', () {
      final now = DateTime.now();
      final telemetry = RiderTelemetry(
        riderId: 'rider-007',
        riderName: 'Aman',
        position: const LatLng(32.24, 77.18),
        speedKmh: 84.0,
        headingDegrees: 180.0,
        altitudeMeters: 4280.0,
        timestamp: now,
        connectionState: RiderConnectionState.reconnecting,
      );

      expect(telemetry.isReconnecting, isTrue);
      expect(telemetry.isOffline, isFalse);

      final json = telemetry.toJson();
      expect(json['rider_id'], equals('rider-007'));
      expect(json['speed'], equals(84.0));
      expect(json['lat'], equals(32.24));
    });
  });

  group('Position Interpolator Tests', () {
    test('MarkerInterpolationState interpolates smoothly without snapping', () {
      final initial = const LatLng(32.20, 77.10);
      final target = const LatLng(32.22, 77.12);

      final state = MarkerInterpolationState(
        id: 'rider-1',
        initialPosition: initial,
        initialHeading: 10.0,
      );

      state.animateTo(target: target, heading: 30.0, durationMs: 1000);
      expect(state.isAnimating, isTrue);

      final startMs = DateTime.now().millisecondsSinceEpoch;
      // Tick halfway through (500ms)
      state.tick(startMs + 500);

      // Should be halfway between initial and target
      expect(state.position.latitude, greaterThan(32.20));
      expect(state.position.latitude, lessThan(32.22));
      expect(state.heading, greaterThan(10.0));
      expect(state.heading, lessThan(30.0));

      // Tick at completion (1000ms)
      state.tick(startMs + 1000);
      expect(state.position.latitude, closeTo(32.22, 0.0001));
      expect(state.position.longitude, closeTo(77.12, 0.0001));
      expect(state.heading, closeTo(30.0, 0.1));
      expect(state.isAnimating, isFalse);
    });
  });

  group('HazardLayerState Freshness Label Tests', () {
    test('Formats freshness string accurately', () {
      const stateUnder60s = HazardLayerState(updatedSecondsAgo: 14);
      expect(stateUnder60s.freshnessLabel, equals('Updated 14s ago'));

      const stateOver60s = HazardLayerState(updatedSecondsAgo: 130);
      expect(stateOver60s.freshnessLabel, equals('Updated 2m ago'));
    });
  });
}
