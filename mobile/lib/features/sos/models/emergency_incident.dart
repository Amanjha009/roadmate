import 'package:flutter/foundation.dart';

/// Method by which the emergency incident was triggered.
enum EmergencyTriggerSource {
  /// Hands-free wake phrase: "Hey RoadMate, I need help"
  voice,

  /// Accelerometer / gyroscope impact spike followed by sudden stillness.
  crashDetected,

  /// Manual slide-to-activate 80dp button on screen.
  manualButton,
}

/// Status of the active SOS incident lifecycle.
enum IncidentState {
  /// System is idle and armed in riding mode.
  idle,

  /// 10-second local audible/vibrating cancel countdown is ticking with active AI voice check.
  countingDown,

  /// Countdown elapsed without cancellation; external multi-channel escalation in progress.
  escalating,

  /// Dispatched to emergency contacts (push/SMS/Telegram) and 112 call launched.
  dispatched,

  /// Critical crash: Rider was unresponsive for 10s. AI Voice placed automated calls to Police Station & Ambulance.
  unresponsiveEscalated,

  /// Cancelled by rider during the 10-second safety countdown window.
  cancelled,
}

/// Represents an emergency incident state snapshot.
@immutable
class EmergencyIncident {
  final String? eventId;
  final EmergencyTriggerSource triggerSource;
  final IncidentState state;
  final double? latitude;
  final double? longitude;
  final String? triggerPhrase;
  final double? gForcePeak;
  final int countdownSecondsRemaining;
  final bool isAudioRecording;
  final String? localAudioPath;
  final String? remoteAudioUrl;
  final DateTime triggeredAt;
  final String? cancellationReason;
  final bool isUnresponsive;
  final bool policeDispatched;
  final bool ambulanceDispatched;
  final String? policeCallTranscript;
  final String? ambulanceCallTranscript;
  final String? aiVoicePrompt;
  final String riderName;
  final String bloodGroup;

  const EmergencyIncident({
    this.eventId,
    required this.triggerSource,
    this.state = IncidentState.idle,
    this.latitude,
    this.longitude,
    this.triggerPhrase,
    this.gForcePeak,
    this.countdownSecondsRemaining = 10,
    this.isAudioRecording = false,
    this.localAudioPath,
    this.remoteAudioUrl,
    required this.triggeredAt,
    this.cancellationReason,
    this.isUnresponsive = false,
    this.policeDispatched = false,
    this.ambulanceDispatched = false,
    this.policeCallTranscript,
    this.ambulanceCallTranscript,
    this.aiVoicePrompt,
    this.riderName = 'Aman Jha',
    this.bloodGroup = 'O+',
  });

  EmergencyIncident copyWith({
    String? eventId,
    EmergencyTriggerSource? triggerSource,
    IncidentState? state,
    double? latitude,
    double? longitude,
    String? triggerPhrase,
    double? gForcePeak,
    int? countdownSecondsRemaining,
    bool? isAudioRecording,
    String? localAudioPath,
    String? remoteAudioUrl,
    DateTime? triggeredAt,
    String? cancellationReason,
    bool? isUnresponsive,
    bool? policeDispatched,
    bool? ambulanceDispatched,
    String? policeCallTranscript,
    String? ambulanceCallTranscript,
    String? aiVoicePrompt,
    String? riderName,
    String? bloodGroup,
  }) {
    return EmergencyIncident(
      eventId: eventId ?? this.eventId,
      triggerSource: triggerSource ?? this.triggerSource,
      state: state ?? this.state,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      triggerPhrase: triggerPhrase ?? this.triggerPhrase,
      gForcePeak: gForcePeak ?? this.gForcePeak,
      countdownSecondsRemaining:
          countdownSecondsRemaining ?? this.countdownSecondsRemaining,
      isAudioRecording: isAudioRecording ?? this.isAudioRecording,
      localAudioPath: localAudioPath ?? this.localAudioPath,
      remoteAudioUrl: remoteAudioUrl ?? this.remoteAudioUrl,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      isUnresponsive: isUnresponsive ?? this.isUnresponsive,
      policeDispatched: policeDispatched ?? this.policeDispatched,
      ambulanceDispatched: ambulanceDispatched ?? this.ambulanceDispatched,
      policeCallTranscript: policeCallTranscript ?? this.policeCallTranscript,
      ambulanceCallTranscript:
          ambulanceCallTranscript ?? this.ambulanceCallTranscript,
      aiVoicePrompt: aiVoicePrompt ?? this.aiVoicePrompt,
      riderName: riderName ?? this.riderName,
      bloodGroup: bloodGroup ?? this.bloodGroup,
    );
  }
}
