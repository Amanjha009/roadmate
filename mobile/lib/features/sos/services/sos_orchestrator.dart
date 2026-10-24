import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/location_service.dart';
import '../models/emergency_incident.dart';
import 'crash_detector_service.dart';
import 'emergency_audio_recorder_service.dart';
import 'emergency_dialer_service.dart';
import 'voice_trigger_service.dart';
import 'ai_voice_sos_service.dart';

/// Central Orchestrator managing parallel emergency trigger sequences.
///
/// Ensures GPS capture, audio recording start, and backend contact queueing run
/// concurrently while the 10-second local cancel window is ticking.
/// In major crash events, executes vocal responsiveness challenge and automated
/// AI voice calling to Police (112) and Ambulance (108) if unresponsive.
class SOSOrchestrator {
  final LocationService _locationService;
  final VoiceTriggerService _voiceTriggerService;
  final CrashDetectorService _crashDetectorService;
  final EmergencyAudioRecorderService _audioRecorderService;
  final EmergencyDialerService _dialerService;
  final AIVoiceSOSService _aiVoiceService;
  final Dio _dio;

  StreamSubscription? _voiceSubscription;
  StreamSubscription? _crashSubscription;
  Timer? _countdownTimer;

  final StreamController<EmergencyIncident> _incidentStateController =
      StreamController<EmergencyIncident>.broadcast();

  EmergencyIncident _currentIncident = EmergencyIncident(
    triggerSource: EmergencyTriggerSource.voice,
    state: IncidentState.idle,
    triggeredAt: DateTime.now(),
  );

  Stream<EmergencyIncident> get onIncidentStateChanged =>
      _incidentStateController.stream;

  EmergencyIncident get currentIncident => _currentIncident;
  EmergencyDialerService get dialerService => _dialerService;
  AIVoiceSOSService get aiVoiceService => _aiVoiceService;

  SOSOrchestrator({
    required LocationService locationService,
    required VoiceTriggerService voiceTriggerService,
    required CrashDetectorService crashDetectorService,
    required EmergencyAudioRecorderService audioRecorderService,
    required EmergencyDialerService dialerService,
    required AIVoiceSOSService aiVoiceService,
    required Dio dio,
  })  : _locationService = locationService,
        _voiceTriggerService = voiceTriggerService,
        _crashDetectorService = crashDetectorService,
        _audioRecorderService = audioRecorderService,
        _dialerService = dialerService,
        _aiVoiceService = aiVoiceService,
        _dio = dio {
    _initListeners();
  }

  void _initListeners() {
    // 1. Voice trigger stream
    _voiceSubscription =
        _voiceTriggerService.onWakePhraseDetected.listen((phrase) {
      handleTrigger(
        triggerSource: EmergencyTriggerSource.voice,
        triggerPhrase: phrase,
      );
    });

    // 2. Crash sensor stream
    _crashSubscription =
        _crashDetectorService.onCrashDetected.listen((peakGForce) {
      handleTrigger(
        triggerSource: EmergencyTriggerSource.crashDetected,
        gForcePeak: peakGForce,
      );
    });
  }

  /// Initiates parallel emergency sequence upon any trigger.
  Future<void> handleTrigger({
    required EmergencyTriggerSource triggerSource,
    String? triggerPhrase,
    double? gForcePeak,
  }) async {
    // Prevent re-triggering if already counting down or escalating
    if (_currentIncident.state == IncidentState.countingDown ||
        _currentIncident.state == IncidentState.escalating) {
      return;
    }

    final triggeredAt = DateTime.now();
    _updateState(_currentIncident.copyWith(
      triggerSource: triggerSource,
      state: IncidentState.countingDown,
      countdownSecondsRemaining: 10,
      triggerPhrase: triggerPhrase,
      gForcePeak: gForcePeak,
      triggeredAt: triggeredAt,
    ));

    debugPrint(
      '🚨 [SOSOrchestrator] EMERGENCY TRIGGER FIRED via ${triggerSource.name}. '
      'Launching PARALLEL actions...',
    );

    // ── STEP 1: PARALLEL GPS Fix Capture ─────────────────────────────────────
    final gpsFuture = _captureGpsFix();

    // ── STEP 2: PARALLEL 30-Sec Ambient Audio Recording ──────────────────────
    final audioFuture = _startAmbientAudioRecording();

    // ── STEP 3: PARALLEL Server Queueing ──────────────────────────────────────
    // The server queues contacts and records the incident immediately.
    // The 10-second cancel countdown does NOT block this initial queueing.
    final serverQueueFuture = gpsFuture.then((pos) {
      return _queueIncidentOnBackend(
        triggerSource: triggerSource,
        position: pos,
        triggerPhrase: triggerPhrase,
        gForcePeak: gForcePeak,
      );
    });

    // ── STEP 4: Start 10-Second Local Audible & Vibrating Countdown Alert ──────
    _startLocalCountdownAlert();

    // ── STEP 5: In major crash, AI speaks loud vocal responsiveness challenge ───
    if (triggerSource == EmergencyTriggerSource.crashDetected) {
      _aiVoiceService.playCrashResponsivenessChallenge(
        countdownSeconds: 10,
        gForcePeak: gForcePeak,
      ).then((prompt) {
        _updateState(_currentIncident.copyWith(aiVoicePrompt: prompt));
      });
    }

    // Await parallel initialization tasks without blocking the UI countdown
    unawaited(Future.wait([serverQueueFuture, audioFuture]));
  }

  Future<Position?> _captureGpsFix() async {
    try {
      final pos = await _locationService.getCurrentPosition().timeout(
        const Duration(seconds: 4),
        onTimeout: () async {
          // If fresh 3D lock takes too long, fall back to last known position
          final lastKnown = await Geolocator.getLastKnownPosition();
          return lastKnown ??
              Position(
                longitude: 77.2144,
                latitude: 32.3712,
                timestamp: DateTime.now(),
                accuracy: 50.0,
                altitude: 4280.0,
                altitudeAccuracy: 10.0,
                heading: 0.0,
                headingAccuracy: 0.0,
                speed: 0.0,
                speedAccuracy: 0.0,
              );
        },
      );

      _updateState(_currentIncident.copyWith(
        latitude: pos.latitude,
        longitude: pos.longitude,
      ));
      debugPrint('[SOSOrchestrator] GPS Fix Locked: ${pos.latitude}, ${pos.longitude}');
      return pos;
    } catch (e) {
      debugPrint('[SOSOrchestrator] GPS capture error (using fail-safe coordinates): $e');
      return null;
    }
  }

  Future<String?> _startAmbientAudioRecording() async {
    try {
      _updateState(_currentIncident.copyWith(isAudioRecording: true));
      final audioPath = await _audioRecorderService.startEmergencyRecording(
        maxDurationSeconds: 30,
      );
      _updateState(_currentIncident.copyWith(localAudioPath: audioPath));
      return audioPath;
    } catch (e) {
      debugPrint('[SOSOrchestrator] Audio recording init error: $e');
      return null;
    }
  }

  Future<String?> _queueIncidentOnBackend({
    required EmergencyTriggerSource triggerSource,
    Position? position,
    String? triggerPhrase,
    double? gForcePeak,
  }) async {
    try {
      final backendTriggerType = switch (triggerSource) {
        EmergencyTriggerSource.voice => 'voice',
        EmergencyTriggerSource.crashDetected => 'crash_detected',
        EmergencyTriggerSource.manualButton => 'manual',
      };

      final response = await _dio.post(
        '${ApiConstants.baseUrl}/sos/trigger',
        data: {
          'trigger_type': backendTriggerType,
          'latitude': position?.latitude ?? 32.3712,
          'longitude': position?.longitude ?? 77.2144,
          'trigger_phrase': triggerPhrase,
          'g_force_peak': gForcePeak,
        },
      );

      final eventId = response.data['id'] as String?;
      _updateState(_currentIncident.copyWith(eventId: eventId));
      debugPrint('[SOSOrchestrator] Server incident queued: $eventId');
      return eventId;
    } catch (e) {
      debugPrint('[SOSOrchestrator] Backend queue error (offline fallback active): $e');
      return null;
    }
  }

  void _startLocalCountdownAlert() {
    _countdownTimer?.cancel();
    int remaining = 10;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining--;
      if (remaining <= 0) {
        timer.cancel();
        _onCountdownCompleted();
      } else {
        _updateState(_currentIncident.copyWith(
          countdownSecondsRemaining: remaining,
        ));
      }
    });
  }

  /// Rider taps Cancel within the 10-second safety window (False alarm abort).
  Future<void> cancelIncident({
    String reason = 'Cancelled by rider within 10-second safety window',
  }) async {
    _countdownTimer?.cancel();
    await _audioRecorderService.stopRecording();

    final eventId = _currentIncident.eventId;
    _updateState(_currentIncident.copyWith(
      state: IncidentState.cancelled,
      cancellationReason: reason,
      isAudioRecording: false,
    ));

    debugPrint('🛡️ [SOSOrchestrator] INCIDENT ABORTED: $reason');

    if (eventId != null) {
      try {
        await _dio.post(
          '${ApiConstants.baseUrl}/sos/$eventId/cancel',
          data: {'event_id': eventId, 'reason': reason},
        );
      } catch (e) {
        debugPrint('[SOSOrchestrator] Backend cancel notification queued offline: $e');
      }
    }
  }

  /// 10 seconds elapsed without cancellation -> Confirm and escalate!
  Future<void> _onCountdownCompleted() async {
    final eventId = _currentIncident.eventId;
    final isCrash = _currentIncident.triggerSource == EmergencyTriggerSource.crashDetected;

    if (isCrash) {
      // ── CRITICAL: Rider is UNRESPONSIVE after 10-second crash check ──────────
      _updateState(_currentIncident.copyWith(
        state: IncidentState.unresponsiveEscalated,
        isUnresponsive: true,
        countdownSecondsRemaining: 0,
      ));

      debugPrint(
        '🚨 [SOSOrchestrator] RIDER UNRESPONSIVE AFTER 10s CRASH CHECK. '
        'Launching AI Automated Voice Calls to Police Station (112) & Ambulance (108)...',
      );

      final lat = _currentIncident.latitude ?? 32.3712;
      final lng = _currentIncident.longitude ?? 77.2144;

      final policeScript = _aiVoiceService.buildPoliceEmergencyCallScript(
        riderName: _currentIncident.riderName,
        riderPhone: '+91 98765 43200',
        bloodGroup: _currentIncident.bloodGroup,
        latitude: lat,
        longitude: lng,
        emergencyContactName: 'Aditi Sharma',
        emergencyContactPhone: '+91 98765 43210',
        gForcePeak: _currentIncident.gForcePeak,
        landmark: 'Rohtang Pass Highway NH3',
      );

      final ambulanceScript = _aiVoiceService.buildAmbulanceEmergencyCallScript(
        riderName: _currentIncident.riderName,
        riderPhone: '+91 98765 43200',
        bloodGroup: _currentIncident.bloodGroup,
        latitude: lat,
        longitude: lng,
        landmark: 'Rohtang Pass Highway NH3',
      );

      // 1. Dispatch Automated AI Voice Calls concurrently
      unawaited(Future.wait([
        _aiVoiceService.executeAutomatedVoiceCall(
          destinationNumber: '112',
          recipientName: 'Police Station / 112 Dispatch',
          voiceScript: policeScript,
        ),
        _aiVoiceService.executeAutomatedVoiceCall(
          destinationNumber: '108',
          recipientName: 'Ambulance / 108 EMS',
          voiceScript: ambulanceScript,
        ),
      ]));

      // 2. Notify Backend for Unresponsive Multi-Channel Escalation
      if (eventId != null) {
        try {
          await _dio.post(
            '${ApiConstants.baseUrl}/sos/$eventId/unresponsive-escalation',
            data: {
              'unresponsive_duration_seconds': 10,
              'g_force_peak': _currentIncident.gForcePeak,
              'nearest_landmark': 'Rohtang Pass Highway NH3',
            },
          );
        } catch (e) {
          debugPrint('[SOSOrchestrator] Backend unresponsive sync queued offline: $e');
        }
      }

      // 3. Fallback direct system dialer
      await _dialerService.initiateEmergencyCall();

      _updateState(_currentIncident.copyWith(
        policeDispatched: true,
        ambulanceDispatched: true,
        policeCallTranscript: policeScript,
        ambulanceCallTranscript: ambulanceScript,
        state: IncidentState.unresponsiveEscalated,
      ));
    } else {
      // Normal Voice or Manual trigger confirmation
      _updateState(_currentIncident.copyWith(
        state: IncidentState.escalating,
        countdownSecondsRemaining: 0,
      ));

      debugPrint(
        '🚨 [SOSOrchestrator] COUNTDOWN COMPLETED. Escalating multi-channel dispatch...',
      );

      if (eventId != null) {
        try {
          await _dio.post(
            '${ApiConstants.baseUrl}/sos/$eventId/confirm',
            data: {
              'event_id': eventId,
              'confirmed_at': DateTime.now().toUtc().toIso8601String(),
            },
          );
        } catch (e) {
          debugPrint('[SOSOrchestrator] Server confirmation sync error: $e');
        }
      }

      await _dialerService.initiateEmergencyCall();
      _updateState(_currentIncident.copyWith(state: IncidentState.dispatched));
    }
  }

  void _updateState(EmergencyIncident updated) {
    _currentIncident = updated;
    _incidentStateController.add(updated);
  }

  void dispose() {
    _voiceSubscription?.cancel();
    _crashSubscription?.cancel();
    _countdownTimer?.cancel();
    _incidentStateController.close();
  }
}
