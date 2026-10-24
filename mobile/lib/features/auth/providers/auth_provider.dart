import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/auth_service.dart';

/// Possible authentication states.
enum AuthStatus {
  /// No user session.
  unauthenticated,

  /// OTP has been sent, awaiting verification.
  otpSent,

  /// User is fully authenticated.
  authenticated,
}

/// Holds the current auth status and optional phone number.
class AuthState {
  final AuthStatus status;
  final String? phone;
  final String? error;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.phone,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? phone,
    String? error,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      phone: phone ?? this.phone,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Global auth state provider.
final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

/// Manages authentication flow: OTP send → verify → session.
///
/// Currently uses mocked API responses with a 2-second simulated
/// network delay. Replace the `_mock*` methods with real API calls
/// once the backend is wired.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _checkExistingSession();
  }

  /// On startup, check if we already have a stored token.
  Future<void> _checkExistingSession() async {
    final isAuth = await _authService.isAuthenticated;
    if (isAuth) {
      state = state.copyWith(status: AuthStatus.authenticated);
    }
  }

  /// Sends an OTP to [phone].
  ///
  /// Mock: always succeeds after 2 seconds.
  Future<void> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, error: null, phone: phone);

    try {
      // TODO(backend): Replace with actual API call.
      await Future<void>.delayed(const Duration(seconds: 2));

      state = state.copyWith(
        status: AuthStatus.otpSent,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to send OTP. Please try again.',
      );
    }
  }

  /// Verifies the [code] for the previously supplied phone number.
  ///
  /// Mock: any 6-digit code is accepted after 2 seconds.
  Future<void> verifyOtp(String phone, String code) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // TODO(backend): Replace with actual API call.
      await Future<void>.delayed(const Duration(seconds: 2));

      if (code.length != 6) {
        state = state.copyWith(
          isLoading: false,
          error: 'Please enter a valid 6-digit OTP.',
        );
        return;
      }

      // Mock token storage.
      await _authService.saveTokens(
        accessToken: 'mock_access_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'mock_refresh_${DateTime.now().millisecondsSinceEpoch}',
      );

      state = state.copyWith(
        status: AuthStatus.authenticated,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Verification failed. Please try again.',
      );
    }
  }

  /// Clears the session and returns to unauthenticated state.
  Future<void> logout() async {
    await _authService.clearTokens();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Whether the user is currently authenticated.
  bool get isAuthenticated => state.status == AuthStatus.authenticated;
}
