/// API base URL and endpoint constants.
///
/// All paths are relative to [baseUrl]. Switch [baseUrl] between
/// staging and production via environment variables at build time.
class ApiConstants {
  ApiConstants._();

  /// Base URL for the RoadMate India backend.
  static const String baseUrl = 'https://api.roadmate.in/v1';

  // ── Auth ─────────────────────────────────────────────────────────
  static const String sendOtp = '/auth/otp/send';
  static const String verifyOtp = '/auth/otp/verify';
  static const String refreshToken = '/auth/token/refresh';

  // ── Profile ──────────────────────────────────────────────────────
  static const String profile = '/profile';
  static const String verifyIdentity = '/profile/verify';

  // ── Trips ────────────────────────────────────────────────────────
  static const String planTrip = '/trips/plan';
  static const String savedTrips = '/trips';

  // ── Hazards ──────────────────────────────────────────────────────
  static const String hazards = '/hazards';
  static const String reportHazard = '/hazards/report';
  static const String nearbyHazards = '/hazards/nearby';

  // ── Group Rides ──────────────────────────────────────────────────
  static const String groupRides = '/group-rides';
  static const String joinRide = '/group-rides/join';

  // ── Garage ───────────────────────────────────────────────────────
  static const String bikes = '/garage/bikes';

  // ── SOS ──────────────────────────────────────────────────────────
  static const String sos = '/sos';
  static const String sosTrigger = '/sos/trigger';
  static const String sosConfirm = '/sos/confirm';
  static const String sosCancel = '/sos/cancel';

  // ── Women Circle ─────────────────────────────────────────────────
  static const String womenCircle = '/women-circle';

  /// Default request timeout.
  static const Duration connectTimeout = Duration(seconds: 15);

  /// Default receive timeout.
  static const Duration receiveTimeout = Duration(seconds: 30);
}
