import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_constants.dart';
import 'api_interceptor.dart';

/// Provides a configured [Dio] instance as a Riverpod provider.
final apiClientProvider = Provider<Dio>((ref) {
  return ApiClient.create(ref);
});

/// Factory for the app-wide [Dio] HTTP client.
///
/// Pre-configured with:
/// * [ApiConstants.baseUrl] as the base URL.
/// * Timeouts for connect and receive.
/// * [AuthInterceptor] for automatic JWT injection.
/// * Logging interceptor (debug builds only).
class ApiClient {
  ApiClient._();

  /// Creates and configures a new [Dio] instance.
  static Dio create(Ref ref) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Auth token injection.
    dio.interceptors.add(AuthInterceptor(ref));

    // Debug logging.
    assert(() {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => print('[DIO] $obj'), // ignore: avoid_print
        ),
      );
      return true;
    }());

    return dio;
  }
}
