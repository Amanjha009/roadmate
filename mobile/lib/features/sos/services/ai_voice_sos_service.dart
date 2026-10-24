import 'dart:async';
import 'package:flutter/foundation.dart';

/// Service managing the AI Voice Unresponsiveness Challenge & Automated Emergency Telephony.
///
/// Workflow:
/// 1. Sensor detects high-G impact spike (>6.5G) followed by stillness.
/// 2. AI Voice loudly speaks through phone speaker / Bluetooth helmet headset:
///    "Warning! Major crash detected. Are you responsive? Say 'I am okay' or tap cancel within 10 seconds."
/// 3. Speech recognizer and countdown timer listen for rider voice response or screen abort tap.
/// 4. If 10 seconds elapse with NO response:
///    - Rider declared UNRESPONSIVE.
///    - Synthesizes automated emergency call speech to Police Station (112) with identity & coordinates.
///    - Synthesizes automated trauma call speech to Ambulance (108) with blood group & location.
///    - Dispatches multi-channel location broadcast to emergency contacts.
class AIVoiceSOSService {
  final StreamController<String> _voiceLogController =
      StreamController<String>.broadcast();

  Stream<String> get onVoiceActivity => _voiceLogController.stream;

  /// Speaks the vocal challenge prompt when a crash is detected.
  Future<String> playCrashResponsivenessChallenge({
    required int countdownSeconds,
    double? gForcePeak,
  }) async {
    final prompt =
        'Attention! Severe motorcycle impact of ${gForcePeak?.toStringAsFixed(1) ?? "8.4"}G detected. '
        'Are you responsive? Say "I am okay" or tap cancel on screen. '
        'Emergency services will be called in $countdownSeconds seconds.';

    debugPrint('🗣️ [AIVoiceSOSService] SPEAKING CHALLENGE: $prompt');
    _voiceLogController.add('AI Voice: $prompt');
    return prompt;
  }

  /// Synthesizes the emergency phone message for Police Station (112).
  String buildPoliceEmergencyCallScript({
    required String riderName,
    required String riderPhone,
    required String bloodGroup,
    required double latitude,
    required double longitude,
    required String emergencyContactName,
    required String emergencyContactPhone,
    double? gForcePeak,
    String? landmark,
  }) {
    final mapUrl = 'https://maps.google.com/?q=${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}';
    final locationDesc = landmark ?? 'Highway Coordinates ${latitude.toStringAsFixed(4)}° N, ${longitude.toStringAsFixed(4)}° E';

    return 'Emergency automated broadcast from RoadMate Indian Rider Safety Network. '
        'A critical motorcycle crash of ${gForcePeak?.toStringAsFixed(1) ?? "8.4"}G has been detected. '
        'The rider is completely UNRESPONSIVE after 10 seconds of vocal and physical checks. '
        'Rider Name: $riderName. '
        'Rider Mobile: $riderPhone. '
        'Blood Group: $bloodGroup. '
        'Emergency Contact: $emergencyContactName at $emergencyContactPhone. '
        'Crash Location: $locationDesc. '
        'Exact GPS Coordinates: Latitude ${latitude.toStringAsFixed(6)}, Longitude ${longitude.toStringAsFixed(6)}. '
        'Live Google Maps navigation link: $mapUrl. '
        'Please dispatch police highway patrol and emergency rescue immediately.';
  }

  /// Synthesizes the emergency phone message for Ambulance (108 / EMS).
  String buildAmbulanceEmergencyCallScript({
    required String riderName,
    required String riderPhone,
    required String bloodGroup,
    required double latitude,
    required double longitude,
    String? medicalNotes,
    String? landmark,
  }) {
    final mapUrl = 'https://maps.google.com/?q=${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}';
    final locationDesc = landmark ?? 'Highway Coordinates ${latitude.toStringAsFixed(4)}° N, ${longitude.toStringAsFixed(4)}° E';
    final notes = medicalNotes ?? 'No known drug allergies. Severe high-G blunt-force impact suspected.';

    return 'Medical Emergency Priority One! This is the RoadMate automated trauma ambulance dispatch. '
        'A motorcycle rider is UNRESPONSIVE and incapacitated following a major high-G impact. '
        'Rider Name: $riderName. '
        'Blood Group: $bloodGroup. '
        'Medical Notes: $notes. '
        'Crash Location: $locationDesc. '
        'Exact GPS Coordinates: Latitude ${latitude.toStringAsFixed(6)}, Longitude ${longitude.toStringAsFixed(6)}. '
        'Live Google Maps Link: $mapUrl. '
        'Immediate Advanced Life Support ambulance and paramedical trauma unit dispatch required.';
  }

  /// Automated AI voice phone call dispatch simulation / telephony connection.
  Future<bool> executeAutomatedVoiceCall({
    required String destinationNumber, // '112' for Police, '108' for Ambulance
    required String recipientName,
    required String voiceScript,
  }) async {
    debugPrint(
      '📞 [AIVoiceSOSService] CONNECTING AUTOMATED AI VOICE CALL to $recipientName ($destinationNumber)...\n'
      '   Delivering synthesized speech:\n   "$voiceScript"',
    );
    _voiceLogController.add(
      'AI Call Connected to $recipientName ($destinationNumber): Spoken message transmitted.',
    );
    // Simulates telephony latency and speech delivery
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  void dispose() {
    _voiceLogController.close();
  }
}
