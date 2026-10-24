import 'package:go_router/go_router.dart';

import '../features/auth/screens/otp_screen.dart';
import '../features/auth/screens/verification_screen.dart';
import '../features/sos/screens/active_emergency_screen.dart';
import '../features/sos/screens/voice_sos_setup_screen.dart';

/// Top-level application router configuration using [GoRouter].
final GoRouter appRouter = GoRouter(
  initialLocation: '/otp',
  routes: [
    GoRoute(
      path: '/otp',
      name: 'otp',
      builder: (context, state) => const OtpScreen(),
    ),
    GoRoute(
      path: '/verification',
      name: 'verification',
      builder: (context, state) => const VerificationScreen(),
    ),
    GoRoute(
      path: '/sos/setup',
      name: 'voice-sos-setup',
      builder: (context, state) => const VoiceSOSSetupScreen(),
    ),
    GoRoute(
      path: '/sos/active',
      name: 'active-emergency',
      builder: (context, state) => const ActiveEmergencyScreen(),
    ),
  ],
);
