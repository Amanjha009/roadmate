import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// Tracks smooth interpolation state for a single marker.
class MarkerInterpolationState extends ChangeNotifier {
  final String id;
  LatLng _currentPosition;
  double _currentHeading;

  LatLng _startPosition;
  LatLng _targetPosition;
  double _startHeading;
  double _targetHeading;

  int _startTimeMs = 0;
  int _durationMs = 3000;
  bool _isAnimating = false;

  MarkerInterpolationState({
    required this.id,
    required LatLng initialPosition,
    double initialHeading = 0.0,
  })  : _currentPosition = initialPosition,
        _currentHeading = initialHeading,
        _startPosition = initialPosition,
        _targetPosition = initialPosition,
        _startHeading = initialHeading,
        _targetHeading = initialHeading;

  LatLng get position => _currentPosition;
  double get heading => _currentHeading;
  bool get isAnimating => _isAnimating;

  /// Update target coordinates.
  /// Smoothly interpolates from the current animated position to the new target.
  void animateTo({
    required LatLng target,
    required double heading,
    int durationMs = 3500,
  }) {
    _startPosition = _currentPosition;
    _targetPosition = target;
    _startHeading = _currentHeading;
    _targetHeading = heading;
    _durationMs = durationMs > 0 ? durationMs : 3000;
    _startTimeMs = DateTime.now().millisecondsSinceEpoch;
    _isAnimating = true;
  }

  /// Update tick called by the interpolator loop (e.g. ~60fps).
  bool tick(int nowMs) {
    if (!_isAnimating) return false;

    final elapsed = nowMs - _startTimeMs;
    final double rawProgress = (elapsed / _durationMs).clamp(0.0, 1.0);

    // Smooth cubic curve for natural touring bike movement
    final double curvedProgress = Curves.easeInOut.transform(rawProgress);

    // Linear interpolation of coordinates
    final double newLat = _startPosition.latitude +
        (_targetPosition.latitude - _startPosition.latitude) * curvedProgress;
    final double newLng = _startPosition.longitude +
        (_targetPosition.longitude - _startPosition.longitude) * curvedProgress;

    // Smooth angle interpolation handling 0°-360° wrap
    final double newHeading = _lerpAngle(_startHeading, _targetHeading, curvedProgress);

    _currentPosition = LatLng(newLat, newLng);
    _currentHeading = newHeading;

    notifyListeners();

    if (rawProgress >= 1.0) {
      _isAnimating = false;
      return false;
    }
    return true;
  }

  /// Shortest-path angle lerp to avoid snapping when crossing 0°/360° north.
  double _lerpAngle(double a, double b, double t) {
    double diff = (b - a) % 360;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return (a + diff * t) % 360;
  }
}

/// Central animation manager that ticks active marker interpolations.
/// Prevents full map redraws by updating only targeted marker listeners.
class PositionInterpolatorManager {
  final Map<String, MarkerInterpolationState> _states = {};
  Timer? _ticker;

  PositionInterpolatorManager();

  /// Get or create an interpolation state for a rider.
  MarkerInterpolationState getOrCreate(String riderId, LatLng initialPosition, [double heading = 0.0]) {
    return _states.putIfAbsent(
      riderId,
      () => MarkerInterpolationState(
        id: riderId,
        initialPosition: initialPosition,
        initialHeading: heading,
      ),
    );
  }

  /// Push an updated coordinate to interpolate towards.
  void updateTarget(String riderId, LatLng target, double heading, {int durationMs = 3500}) {
    final state = getOrCreate(riderId, target, heading);
    state.animateTo(target: target, heading: heading, durationMs: durationMs);
    _ensureTickerRunning();
  }

  void _ensureTickerRunning() {
    if (_ticker != null && _ticker!.isActive) return;

    // 60fps tick (16ms)
    _ticker = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final now = DateTime.now().millisecondsSinceEpoch;
      bool hasActiveAnimations = false;

      for (final state in _states.values) {
        if (state.tick(now)) {
          hasActiveAnimations = true;
        }
      }

      // Pause ticker if all markers reached target to save battery
      if (!hasActiveAnimations) {
        _ticker?.cancel();
        _ticker = null;
      }
    });
  }

  void removeRider(String riderId) {
    _states.remove(riderId)?.dispose();
  }

  void dispose() {
    _ticker?.cancel();
    _ticker = null;
    for (final state in _states.values) {
      state.dispose();
    }
    _states.clear();
  }
}
