import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Provides the singleton [AuthService].
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Manages JWT tokens in secure storage and exposes login state helpers.
///
/// Tokens are stored via [FlutterSecureStorage] so they survive
/// app restarts and are protected by the OS keychain.
class AuthService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Reads the persisted access token, or `null` if none.
  Future<String?> getAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  /// Reads the persisted refresh token, or `null` if none.
  Future<String?> getRefreshToken() {
    return _storage.read(key: _refreshTokenKey);
  }

  /// Persists a new token pair.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  /// Removes all stored tokens (logout).
  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  /// Returns `true` if an access token exists.
  Future<bool> get isAuthenticated async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
