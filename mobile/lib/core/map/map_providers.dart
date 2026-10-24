import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_constants.dart';
import '../network/api_client.dart';
import 'services/live_location_service.dart';
import 'services/live_ride_connection_manager.dart';
import 'services/viewport_hazard_service.dart';

/// App-wide Live Location Service (singleton).
final liveLocationServiceProvider = Provider<LiveLocationService>((ref) {
  final service = LiveLocationService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Parameter for the ride room connection manager.
class RideRoomParams {
  final String rideRoomId;
  final String riderId;
  final String riderName;

  const RideRoomParams({
    required this.rideRoomId,
    required this.riderId,
    required this.riderName,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RideRoomParams &&
          runtimeType == other.runtimeType &&
          rideRoomId == other.rideRoomId &&
          riderId == other.riderId;

  @override
  int get hashCode => rideRoomId.hashCode ^ riderId.hashCode;
}

/// Ride Room WebSocket connection manager family.
final liveRideConnectionManagerProvider =
    Provider.family<LiveRideConnectionManager, RideRoomParams>((ref, params) {
  // Compute WebSocket URL from API base URL (http -> ws, https -> wss)
  final apiBase = ApiConstants.baseUrl;
  final wsBase = apiBase.startsWith('https://')
      ? apiBase.replaceFirst('https://', 'wss://')
      : apiBase.replaceFirst('http://', 'ws://');

  final manager = LiveRideConnectionManager(
    baseWsUrl: wsBase,
    rideRoomId: params.rideRoomId,
    myRiderId: params.riderId,
    myRiderName: params.riderName,
  );

  ref.onDispose(() => manager.dispose());
  return manager;
});

/// Viewport-based hazard radar service provider.
final viewportHazardServiceProvider = ChangeNotifierProvider<ViewportHazardService>((ref) {
  final dio = ref.watch(apiClientProvider);
  final service = ViewportHazardService(dio: dio);
  ref.onDispose(() => service.dispose());
  return service;
});
