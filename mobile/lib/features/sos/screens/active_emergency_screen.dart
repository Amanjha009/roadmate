import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/roadmate_button.dart';
import '../models/emergency_incident.dart';
import '../providers/sos_provider.dart';

/// Full-screen high-contrast Emergency Cockpit HUD for active SOS incidents.
///
/// Displayed immediately when Voice trigger ("Hey RoadMate, I need help"),
/// Hard-Fall motion spike, or manual SOS button fires.
///
/// Features:
/// 1. 10-second audible/visual safety countdown to prevent accidental false alarms.
/// 2. Parallel telemetry snapshot (GPS fix status, 30-sec ambient audio recording).
/// 3. OS-compliant 112 emergency dialer trigger (auto-focused high-contrast action).
/// 4. Prominent one-tap Cancel button to abort false triggers.
class ActiveEmergencyScreen extends ConsumerWidget {
  const ActiveEmergencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orchestrator = ref.watch(sosOrchestratorProvider);
    final incidentAsync = ref.watch(activeIncidentStreamProvider);

    final incident = incidentAsync.value ?? orchestrator.currentIncident;
    final isCountingDown = incident.state == IncidentState.countingDown;
    final isDispatched = incident.state == IncidentState.dispatched;
    final isUnresponsive = incident.state == IncidentState.unresponsiveEscalated || incident.isUnresponsive;
    final isCancelled = incident.state == IncidentState.cancelled;

    final triggerLabel = switch (incident.triggerSource) {
      EmergencyTriggerSource.voice =>
        "🎙️ VOICE TRIGGER: '${incident.triggerPhrase ?? 'Hey RoadMate, I need help'}'",
      EmergencyTriggerSource.crashDetected =>
        "💥 MAJOR CRASH DETECTED: ${incident.gForcePeak?.toStringAsFixed(1) ?? '8.4'}G Impact Spike",
      EmergencyTriggerSource.manualButton => "🚨 MANUAL BUTTON ACTIVATED",
    };

    return PopScope(
      canPop: isCancelled,
      child: Scaffold(
        backgroundColor: const Color(0xFF140303),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Top Header / Alert Banner ────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.statusRed.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.statusRed),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.statusRed, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            triggerLabel,
                            style: const TextStyle(
                              color: AppColors.statusRed,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (isCountingDown && incident.triggerSource == EmergencyTriggerSource.crashDetected) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A1505),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.brandOrange),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.mic, color: AppColors.brandOrange, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'AI Voice Checking Rider Consciousness: Speak "I am okay" or tap Abort within 10s',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brandOrange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (isUnresponsive) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF330909),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.statusRed, width: 2),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.emergency, color: AppColors.statusRed, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'RIDER UNRESPONSIVE (10s TIMEOUT)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.statusRed,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            'AI automated voice calls placed to Police Station (112) & Ambulance (108) with coordinates and rider passport.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── Center Countdown Ring / Status ────────────────────────────
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulsing outer halo
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.statusRed.withOpacity(0.12),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x66F44336),
                                blurRadius: 30,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        // Circular Progress
                        SizedBox(
                          width: 175,
                          height: 175,
                          child: CircularProgressIndicator(
                            value: isCountingDown
                                ? incident.countdownSecondsRemaining / 10.0
                                : ((isDispatched || isUnresponsive) ? 1.0 : 0.0),
                            strokeWidth: 10,
                            backgroundColor: const Color(0xFF331111),
                            color: isUnresponsive ? AppColors.statusRed : AppColors.statusRed,
                          ),
                        ),
                        // Number / Text
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isCountingDown) ...[
                              Text(
                                '${incident.countdownSecondsRemaining}',
                                style: const TextStyle(
                                  fontSize: 60,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                  fontFamily: 'Inter',
                                  height: 1,
                                ),
                              ),
                              const Text(
                                'SECONDS REMAINING',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 1,
                                ),
                              ),
                            ] else if (isUnresponsive) ...[
                              const Icon(Icons.support_agent_rounded,
                                  color: AppColors.statusRed, size: 48),
                              const SizedBox(height: 4),
                              const Text(
                                'AI AUTO CALLS',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.statusRed,
                                  letterSpacing: 1,
                                ),
                              ),
                              const Text(
                                'POLICE + AMBULANCE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ] else if (isDispatched) ...[
                              const Icon(Icons.check_circle_rounded,
                                  color: AppColors.statusGreen, size: 54),
                              const SizedBox(height: 6),
                              const Text(
                                'DISPATCHED',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.statusGreen,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ] else if (isCancelled) ...[
                              const Icon(Icons.cancel_rounded,
                                  color: AppColors.textTertiary, size: 54),
                              const SizedBox(height: 6),
                              const Text(
                                'CANCELLED',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ] else ...[
                              const CircularProgressIndicator(color: AppColors.statusRed),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                // ── Parallel Telemetry Status Card ───────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      // GPS Fix
                      _TelemetryRow(
                        icon: Icons.my_location_rounded,
                        iconColor: AppColors.statusGreen,
                        label: 'GPS Coordinates',
                        value: incident.latitude != null
                            ? '${incident.latitude!.toStringAsFixed(4)}° N, ${incident.longitude!.toStringAsFixed(4)}° E'
                            : 'Locking GPS position...',
                      ),
                      const Divider(color: AppColors.divider, height: 18),

                      // Audio Recording
                      _TelemetryRow(
                        icon: Icons.mic_rounded,
                        iconColor: incident.isAudioRecording
                            ? AppColors.statusRed
                            : AppColors.textTertiary,
                        label: 'Ambient Context Audio',
                        value: incident.isAudioRecording
                            ? 'Recording 30s clip (Encrypted, 30-day auto-purge)'
                            : (incident.localAudioPath != null
                                ? 'Audio clip captured'
                                : 'Audio ready'),
                      ),
                      const Divider(color: AppColors.divider, height: 18),

                      // Multi-channel Contacts
                      const _TelemetryRow(
                        icon: Icons.contact_emergency_rounded,
                        iconColor: AppColors.primary,
                        label: 'Emergency Contacts',
                        value: 'Queued in priority order (Push → SMS → Telegram)',
                      ),
                    ],
                  ),
                ),
                  // ── AI Automated Emergency Calls HUD (When Unresponsive) ─────────
                  if (isUnresponsive) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E0E0E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.statusRed),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.record_voice_over, color: AppColors.statusRed, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'AI SYNTHESIZED EMERGENCY CALLS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.statusRed,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Police Station 112 Card
                          _AiCallRow(
                            icon: Icons.local_police_rounded,
                            iconColor: AppColors.primary,
                            title: 'POLICE STATION (112)',
                            status: incident.policeDispatched ? 'CONNECTED & TRANSMITTED' : 'DIALING...',
                            statusColor: incident.policeDispatched ? AppColors.statusGreen : AppColors.brandOrange,
                            details: 'Delivered: Rider ${incident.riderName}, Blood Group ${incident.bloodGroup}, Exact GPS & Live Map',
                            transcript: incident.policeCallTranscript,
                          ),
                          const Divider(color: AppColors.divider, height: 18),
                          // Ambulance 108 Card
                          _AiCallRow(
                            icon: Icons.emergency_rounded,
                            iconColor: AppColors.statusRed,
                            title: 'AMBULANCE / EMS (108)',
                            status: incident.ambulanceDispatched ? 'DISPATCHED' : 'DIALING...',
                            statusColor: incident.ambulanceDispatched ? AppColors.statusGreen : AppColors.brandOrange,
                            details: 'Delivered: Trauma alert, Blood Group ${incident.bloodGroup}, GPS Coordinates',
                            transcript: incident.ambulanceCallTranscript,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),

                  // ── Local Emergency Dialing 112 Action ───────────────────────
                  // Unmistakable, high-contrast, glove-friendly trigger
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF260D0D),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.statusRed.withOpacity(0.6)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: AppColors.statusRed,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.call, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'NATIONAL EMERGENCY (112)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                orchestrator.dialerService.callActionLabel,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.statusRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            orchestrator.dialerService.initiateEmergencyCall();
                          },
                          child: const Text('DIAL NOW',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),

                // ── 1-Tap Cancel False Alarm Action ──────────────────────────
                if (isCountingDown)
                  RoadmateButton(
                    label: 'ABORT (FALSE ALARM)',
                    icon: Icons.cancel_outlined,
                    onPressed: () {
                      orchestrator.cancelIncident(
                        reason: 'Cancelled by rider within 10-second safety window',
                      );
                    },
                  )
                else
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.divider),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Return to Riding Screen'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TelemetryRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _TelemetryRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AiCallRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String status;
  final Color statusColor;
  final String details;
  final String? transcript;

  const _AiCallRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.status,
    required this.statusColor,
    required this.details,
    this.transcript,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.18),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: statusColor, width: 0.8),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Text(
            details,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1.25,
            ),
          ),
        ),
        if (transcript != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF140808),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.divider),
              ),
              child: Text(
                '🎙️ Speech: "$transcript"',
                style: const TextStyle(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textTertiary,
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

