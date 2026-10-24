import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/roadmate_button.dart';
import '../../../core/widgets/roadmate_text_field.dart';
import '../providers/auth_provider.dart';
import '../widgets/otp_input_field.dart';

/// Phone number + OTP verification screen.
///
/// Flow:
/// 1. User enters phone number with +91 prefix.
/// 2. Taps "Send OTP" → shows 6-digit OTP input.
/// 3. Enters OTP → auto-submits on 6th digit, or taps "Verify".
/// 4. On success → navigates to /home.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _phoneController = TextEditingController();
  String _otpValue = '';
  Timer? _resendTimer;
  int _resendCountdown = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendCountdown = 30;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) return;
    await ref.read(authProvider.notifier).sendOtp('+91$phone');
    _startResendTimer();
  }

  Future<void> _verifyOtp() async {
    if (_otpValue.length != 6) return;
    final phone = '+91${_phoneController.text.trim()}';
    await ref.read(authProvider.notifier).verifyOtp(phone, _otpValue);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Navigate to home on successful auth.
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go('/home');
      }
    });

    final isOtpSent = authState.status == AuthStatus.otpSent;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo / title.
                const Icon(
                  Icons.two_wheeler_rounded,
                  size: 72,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'RoadMate India',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ride safe, ride together.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 48),

                // ── Phone Input ──────────────────────────────────
                RoadmateTextField(
                  controller: _phoneController,
                  hintText: '10-digit mobile number',
                  labelText: 'Phone Number',
                  prefixIcon: Icons.phone_android,
                  keyboardType: TextInputType.phone,
                  readOnly: isOtpSent,
                  suffix: isOtpSent
                      ? IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () {
                            ref.read(authProvider.notifier).logout();
                          },
                        )
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  '+91 will be added automatically',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),

                if (!isOtpSent) ...[
                  // ── Send OTP Button ────────────────────────────
                  RoadmateButton(
                    label: 'Send OTP',
                    onPressed: _sendOtp,
                    isLoading: authState.isLoading,
                  ),
                ],

                if (isOtpSent) ...[
                  // ── OTP Input ──────────────────────────────────
                  const SizedBox(height: 16),
                  Text(
                    'Enter the 6-digit code sent to\n+91 ${_phoneController.text}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 24),
                  OtpInputField(
                    onCompleted: (code) {
                      _otpValue = code;
                      _verifyOtp();
                    },
                    onChanged: (value) => _otpValue = value,
                  ),
                  const SizedBox(height: 24),

                  // ── Verify Button ──────────────────────────────
                  RoadmateButton(
                    label: 'Verify',
                    onPressed: _verifyOtp,
                    isLoading: authState.isLoading,
                  ),
                  const SizedBox(height: 16),

                  // ── Resend ─────────────────────────────────────
                  Center(
                    child: _resendCountdown > 0
                        ? Text(
                            'Resend in $_resendCountdown s',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.textTertiary),
                          )
                        : TextButton(
                            onPressed: _sendOtp,
                            child: const Text('Resend OTP'),
                          ),
                  ),
                ],

                // ── Error ────────────────────────────────────────
                if (authState.error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    authState.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
