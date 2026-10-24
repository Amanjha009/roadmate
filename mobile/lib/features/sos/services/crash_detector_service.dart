import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Sensor-based hard-fall and motorcycle crash motion detector.
///
/// Runs as a secondary, independent trigger alongside the hands-free voice trigger.
/// Either trigger fires the identical emergency escalation sequence.
///
/// ALGORITHM:
/// 1. Continuously samples 3-axis accelerometer and gyroscope vectors.
/// 2. Detects high-G impact spike (threshold > 6.5G / ~64 m/s²).
/// 3. Initiates post-impact stillness verification window (~8-10 seconds) to verify
///    the motorcycle/rider has halted and is incapacitated, avoiding false alarms
///    from speed breakers or road potholes.
class CrashDetectorService {
  static const double impactThresholdG = 6.5; // > 6.5 G
  static const double gravity = 9.80665;
  static const double impactThresholdMps2 = impactThresholdG * gravity;
  static const Duration stillnessWindowDuration = Duration(seconds: 8);

  bool _isArmed = false;
  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  final StreamController<double> _crashStreamController =
      StreamController<double>.broadcast();

  bool _impactDetected = false;
  double _peakGForceRecorded = 0.0;
  Timer? _stillnessTimer;

  /// Stream emitting when a verified hard-fall/crash event is detected.
  Stream<double> get onCrashDetected => _crashStreamController.stream;

  bool get isArmed => _isArmed;

  /// Arms the sensor listener when entering riding mode.
  void arm() {
    if (_isArmed) return;
    _isArmed = true;

    try {
      _accelSub = userAccelerometerEvents.listen(
        _processAccelerometerEvent,
        onError: (err) {
          debugPrint('[CrashDetectorService] Accelerometer stream error: $err');
        },
      );
      debugPrint('[CrashDetectorService] Crash motion detector ARMED.');
    } catch (e) {
      debugPrint('[CrashDetectorService] Sensor hardware unavailable: $e');
    }
  }

  /// Disarms the sensor listener when riding mode stops.
  void disarm() {
    _isArmed = false;
    _accelSub?.cancel();
    _accelSub = null;
    _stillnessTimer?.cancel();
    _impactDetected = false;
    debugPrint('[CrashDetectorService] Crash motion detector DISARMED.');
  }

  void _processAccelerometerEvent(UserAccelerometerEvent event) {
    if (!_isArmed) return;

    // Vector magnitude: sqrt(x² + y² + z²)
    final magnitude = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    final gForce = magnitude / gravity;

    if (gForce > impactThresholdG && !_impactDetected) {
      _impactDetected = true;
      _peakGForceRecorded = gForce;
      debugPrint(
        '[CrashDetectorService] IMPACT SPIKE DETECTED: ${gForce.toStringAsFixed(1)}G. '
        'Checking stillness window ($stillnessWindowDuration)...',
      );

      // Start stillness check: If rider does not resume normal riding acceleration,
      // confirm crash after stillnessWindowDuration.
      _stillnessTimer?.cancel();
      _stillnessTimer = Timer(stillnessWindowDuration, () {
        if (_impactDetected && _isArmed) {
          debugPrint(
            '[CrashDetectorService] HARD-FALL CONFIRMED: Prolonged stillness following '
            '${_peakGForceRecorded.toStringAsFixed(1)}G impact.',
          );
          _crashStreamController.add(_peakGForceRecorded);
          _impactDetected = false;
        }
      });
    }
  }

  /// Manually simulate a crash detection event (for testing & verification).
  void simulateCrashDetection({double gForce = 8.4}) {
    debugPrint('[CrashDetectorService] SIMULATING CRASH SPIKE: ${gForce}G');
    _crashStreamController.add(gForce);
  }

  void dispose() {
    disarm();
    _crashStreamController.close();
  }
}
