import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/services/location_service.dart';
import '../models/emergency_incident.dart';
import '../services/ai_voice_sos_service.dart';
import '../services/crash_detector_service.dart';
import '../services/emergency_audio_recorder_service.dart';
import '../services/emergency_dialer_service.dart';
import '../services/sos_orchestrator.dart';
import '../services/voice_trigger_service.dart';

/// Singleton on-device voice trigger service provider.
final voiceTriggerServiceProvider = Provider<VoiceTriggerService>((ref) {
  final service = VoiceTriggerService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Singleton AI Voice SOS service provider.
final aiVoiceSOSServiceProvider = Provider<AIVoiceSOSService>((ref) {
  final service = AIVoiceSOSService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Singleton crash motion detector provider.
final crashDetectorServiceProvider = Provider<CrashDetectorService>((ref) {
  final service = CrashDetectorService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Singleton emergency audio recorder provider.
final audioRecorderServiceProvider =
    Provider<EmergencyAudioRecorderService>((ref) {
  final service = EmergencyAudioRecorderService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Emergency dialer provider.
final emergencyDialerServiceProvider = Provider<EmergencyDialerService>((ref) {
  return EmergencyDialerService();
});

/// Central SOS orchestrator provider.
final sosOrchestratorProvider = Provider<SOSOrchestrator>((ref) {
  final orchestrator = SOSOrchestrator(
    locationService: ref.watch(locationServiceProvider),
    voiceTriggerService: ref.watch(voiceTriggerServiceProvider),
    crashDetectorService: ref.watch(crashDetectorServiceProvider),
    audioRecorderService: ref.watch(audioRecorderServiceProvider),
    dialerService: ref.watch(emergencyDialerServiceProvider),
    aiVoiceService: ref.watch(aiVoiceSOSServiceProvider),
    dio: ref.watch(apiClientProvider),
  );
  ref.onDispose(() => orchestrator.dispose());
  return orchestrator;
});

/// Live stream provider for the active emergency incident state.
final activeIncidentStreamProvider = StreamProvider<EmergencyIncident>((ref) {
  final orchestrator = ref.watch(sosOrchestratorProvider);
  return orchestrator.onIncidentStateChanged;
});

/// Holds voice SOS user preferences.
class VoiceSOSSettings {
  final bool isVoiceOptedIn;
  final bool isCrashDetectionArmed;
  final String wakePhrase;

  const VoiceSOSSettings({
    this.isVoiceOptedIn = false,
    this.isCrashDetectionArmed = true,
    this.wakePhrase = VoiceTriggerService.defaultWakePhrase,
  });

  VoiceSOSSettings copyWith({
    bool? isVoiceOptedIn,
    bool? isCrashDetectionArmed,
    String? wakePhrase,
  }) {
    return VoiceSOSSettings(
      isVoiceOptedIn: isVoiceOptedIn ?? this.isVoiceOptedIn,
      isCrashDetectionArmed:
          isCrashDetectionArmed ?? this.isCrashDetectionArmed,
      wakePhrase: wakePhrase ?? this.wakePhrase,
    );
  }
}

/// State notifier managing Voice & Crash SOS configuration.
class VoiceSOSNotifier extends StateNotifier<VoiceSOSSettings> {
  final VoiceTriggerService _voiceService;
  final CrashDetectorService _crashService;

  VoiceSOSNotifier(this._voiceService, this._crashService)
      : super(const VoiceSOSSettings()) {
    // Automatically arm crash detector by default for rider safety
    _crashService.arm();
  }

  void setVoiceOptIn(bool optedIn) {
    _voiceService.setOptIn(optedIn);
    state = state.copyWith(isVoiceOptedIn: optedIn);
  }

  void setWakePhrase(String phrase) {
    _voiceService.setWakePhrase(phrase);
    state = state.copyWith(wakePhrase: phrase);
  }

  void toggleCrashDetection(bool armed) {
    if (armed) {
      _crashService.arm();
    } else {
      _crashService.disarm();
    }
    state = state.copyWith(isCrashDetectionArmed: armed);
  }
}

final voiceSOSSettingsProvider =
    StateNotifierProvider<VoiceSOSNotifier, VoiceSOSSettings>((ref) {
  return VoiceSOSNotifier(
    ref.watch(voiceTriggerServiceProvider),
    ref.watch(crashDetectorServiceProvider),
  );
});
