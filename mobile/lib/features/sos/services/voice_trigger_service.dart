import 'dart:async';
import 'package:flutter/foundation.dart';

/// On-Device Hands-Free Voice Trigger Service for RoadMate India.
///
/// Designed to run locally on the device (e.g. via Picovoice Porcupine or
/// native platform low-power App Actions / Siri Shortcuts voice trigger).
///
/// PRIVACY & COMPLIANCE RULES:
/// 1. Opt-in only. Disabled by default until user completes the setup explainer.
/// 2. Active ONLY while Riding Mode is active to preserve battery.
/// 3. Zero continuous recording / zero cloud streaming: audio samples are analyzed
///    strictly in an ephemeral, rolling on-device circular buffer to spot the wake
///    acoustic model. Real recording starts ONLY after the phrase triggers.
class VoiceTriggerService {
  static const String defaultWakePhrase = 'Hey RoadMate, I need help';

  bool _isOptedIn = false;
  bool _isRidingModeActive = false;
  bool _isListening = false;
  String _activePhrase = defaultWakePhrase;

  final StreamController<String> _triggerStreamController =
      StreamController<String>.broadcast();

  /// Stream emitting when the hands-free emergency phrase is recognized.
  Stream<String> get onWakePhraseDetected => _triggerStreamController.stream;

  bool get isOptedIn => _isOptedIn;
  bool get isListening => _isListening;
  String get activePhrase => _activePhrase;

  /// Update user opt-in consent status.
  void setOptIn(bool optedIn) {
    _isOptedIn = optedIn;
    _evaluateListeningState();
  }

  /// Sets the custom trigger phrase.
  void setWakePhrase(String phrase) {
    if (phrase.trim().isNotEmpty) {
      _activePhrase = phrase.trim();
    }
  }

  /// Inform the service whether the rider has started a trip / riding mode.
  void setRidingMode(bool isRiding) {
    _isRidingModeActive = isRiding;
    _evaluateListeningState();
  }

  void _evaluateListeningState() {
    if (_isOptedIn && _isRidingModeActive) {
      _startOnDeviceWakeEngine();
    } else {
      _stopOnDeviceWakeEngine();
    }
  }

  /// Starts the low-power on-device acoustic keyword detector.
  void _startOnDeviceWakeEngine() {
    if (_isListening) return;
    _isListening = true;
    debugPrint(
      '[VoiceTriggerService] On-device wake engine ARMED for phrase: "$_activePhrase". '
      'Operating offline with zero audio transmission.',
    );
    // In native runtime, initializes Porcupine / platform native keyword spotter.
  }

  /// Shuts down microphone listening to preserve battery when parked or unmounted.
  void _stopOnDeviceWakeEngine() {
    if (!_isListening) return;
    _isListening = false;
    debugPrint('[VoiceTriggerService] On-device wake engine DISARMED.');
  }

  /// Simulated / platform hook called when the on-device keyword model matches.
  void simulateVoiceTrigger({String? phrase}) {
    if (!_isOptedIn) {
      debugPrint('[VoiceTriggerService] Voice trigger ignored: User has not opted in.');
      return;
    }
    final detected = phrase ?? _activePhrase;
    debugPrint('[VoiceTriggerService] WAKE PHRASE DETECTED: "$detected"');
    _triggerStreamController.add(detected);
  }

  void dispose() {
    _stopOnDeviceWakeEngine();
    _triggerStreamController.close();
  }
}
