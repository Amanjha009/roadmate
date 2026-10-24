import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/roadmate_button.dart';
import '../../../core/widgets/roadmate_card.dart';
import '../providers/sos_provider.dart';

/// Opt-in onboarding explainer screen for hands-free Voice SOS.
///
/// Designed with transparent privacy disclosures, wind noise limitations,
/// audio recording consent, and OS-compliant calling terms.
class VoiceSOSSetupScreen extends ConsumerStatefulWidget {
  const VoiceSOSSetupScreen({super.key});

  @override
  ConsumerState<VoiceSOSSetupScreen> createState() =>
      _VoiceSOSSetupScreenState();
}

class _VoiceSOSSetupScreenState extends ConsumerState<VoiceSOSSetupScreen> {
  late final TextEditingController _phraseController;

  @override
  void initState() {
    super.initState();
    final currentPhrase = ref.read(voiceSOSSettingsProvider).wakePhrase;
    _phraseController = TextEditingController(text: currentPhrase);
  }

  @override
  void dispose() {
    _phraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(voiceSOSSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hands-Free Voice SOS'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Badge
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: const Icon(
                    Icons.mic_none_rounded,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Hands-Free Voice SOS',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),

              Text(
                'Trigger emergency dispatch when fallen, injured, or unable to reach your phone mount.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 28),

              // ── 1. Privacy & Zero-Streaming Commitment ───────────────────
              RoadmateCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined,
                        color: AppColors.statusGreen, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '100% On-Device Wake Detection',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This listens only for your trigger phrase while Riding Mode is active. '
                            'It does not record, stream, or transmit audio to any cloud server '
                            'until the wake phrase triggers.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── 2. Honest Wind-Noise Limitation Disclosure ────────────────
              RoadmateCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.air_rounded,
                        color: AppColors.statusAmber, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wind Noise & Sensor Fallback',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'At high touring speeds, helmet wind noise can reduce microphone accuracy. '
                            'Because of this, automatic hard-fall sensor detection runs simultaneously '
                            'as your primary trigger. Voice serves as a deliberate backup when you are conscious but pinned.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── 3. Ambient Audio Clip Consent (30-day Retention) ───────────
              RoadmateCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_clock_outlined,
                        color: AppColors.primary, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '30-Second Context Recording',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'When triggered, the app records ~30 seconds of ambient audio to provide vital '
                            'auditory context (breathing, speech) to your emergency contacts. This audio is stored '
                            'encrypted and automatically purged after 30 days unless you choose to preserve it.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── 4. Trigger Phrase Configuration ───────────────────────────
              Text(
                'WAKE PHRASE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiary,
                      letterSpacing: 1.2,
                    ),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: _phraseController,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  prefixIcon:
                      const Icon(Icons.record_voice_over, color: AppColors.primary),
                  hintText: 'e.g. Hey RoadMate, I need help',
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── 5. Action Buttons ──────────────────────────────────────────
              RoadmateButton(
                label: settings.isVoiceOptedIn
                    ? 'Save Settings & Keep Active'
                    : 'Enable Hands-Free Voice SOS',
                icon: Icons.check_circle_outline,
                onPressed: () {
                  final notifier = ref.read(voiceSOSSettingsProvider.notifier);
                  notifier.setWakePhrase(_phraseController.text);
                  notifier.setVoiceOptIn(true);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '✓ Hands-Free Voice SOS enabled. Active only during Riding Mode.',
                      ),
                      backgroundColor: AppColors.surface,
                    ),
                  );
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 12),

              if (settings.isVoiceOptedIn)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.statusRed,
                    side: const BorderSide(color: AppColors.statusRed),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    ref
                        .read(voiceSOSSettingsProvider.notifier)
                        .setVoiceOptIn(false);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Disable Hands-Free Voice SOS'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
