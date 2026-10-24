import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/hazard_pin.dart';

/// State of the viewport-based hazard and coverage layer.
class HazardLayerState {
  final List<HazardPin> pins;
  final DateTime? lastSuccessfulFetch;
  final int updatedSecondsAgo;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final LatLng? lastFetchCenter;

  const HazardLayerState({
    this.pins = const [],
    this.lastSuccessfulFetch,
    this.updatedSecondsAgo = 0,
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
    this.lastFetchCenter,
  });

  /// Formatted freshness string (e.g. "Updated 12s ago", "Updated 2m ago").
  String get freshnessLabel {
    if (lastSuccessfulFetch == null) return "Never updated";
    final sec = updatedSecondsAgo;
    if (sec < 60) return "Updated ${sec}s ago";
    final min = sec ~/ 60;
    return "Updated ${min}m ago";
  }

  HazardLayerState copyWith({
    List<HazardPin>? pins,
    DateTime? lastSuccessfulFetch,
    int? updatedSecondsAgo,
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
    LatLng? lastFetchCenter,
  }) {
    return HazardLayerState(
      pins: pins ?? this.pins,
      lastSuccessfulFetch: lastSuccessfulFetch ?? this.lastSuccessfulFetch,
      updatedSecondsAgo: updatedSecondsAgo ?? this.updatedSecondsAgo,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      lastFetchCenter: lastFetchCenter ?? this.lastFetchCenter,
    );
  }
}

/// Viewport-based Hazard Fetcher.
///
/// Rules:
/// - 60-90s polling interval (never a tight 5s loop).
/// - 200m movement threshold before re-querying, or manual map pan/zoom.
/// - Queries viewport bounding center + 5km buffer radius, not entire DB.
/// - Instant client-side pin auto-expiry: purges the exact second `expires_at` passes.
/// - Explicit error state displayed on UI if network or server fails.
class ViewportHazardService extends ChangeNotifier {
  final Dio dio;
  final double bufferRadiusMeters;
  final Duration pollInterval;

  Timer? _pollingTimer;
  Timer? _autoExpiryTimer;
  Timer? _freshnessTicker;

  HazardLayerState _state = const HazardLayerState();
  LatLng? _currentViewportCenter;

  ViewportHazardService({
    required this.dio,
    this.bufferRadiusMeters = 5000.0,
    this.pollInterval = const Duration(seconds: 75), // 60-90s window
  });

  HazardLayerState get state => _state;

  /// Start the service when map is mounted.
  void start() {
    _startTimers();
  }

  void _startTimers() {
    // 1. Regular 60-90s polling timer
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(pollInterval, (_) {
      if (_currentViewportCenter != null) {
        fetchViewportHazards(_currentViewportCenter!, force: false);
      }
    });

    // 2. High-precision 1-second auto-expiry ticker
    _autoExpiryTimer?.cancel();
    _autoExpiryTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _purgeExpiredPins();
    });

    // 3. Freshness counter ticker
    _freshnessTicker?.cancel();
    _freshnessTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_state.lastSuccessfulFetch != null) {
        final sec = DateTime.now().difference(_state.lastSuccessfulFetch!).inSeconds;
        _state = _state.copyWith(updatedSecondsAgo: sec);
        notifyListeners();
      }
    });
  }

  /// Called on rider position update or map pan/zoom.
  void onViewportChanged(LatLng newCenter, {bool isManualPanZoom = false}) {
    _currentViewportCenter = newCenter;

    if (_state.lastFetchCenter == null) {
      // First fetch
      fetchViewportHazards(newCenter, force: true);
      return;
    }

    if (isManualPanZoom) {
      // Manual pan/zoom: re-fetch immediately for the new bounding area
      fetchViewportHazards(newCenter, force: true);
      return;
    }

    // Check 200m movement threshold
    final distanceMoved = Geolocator.distanceBetween(
      _state.lastFetchCenter!.latitude,
      _state.lastFetchCenter!.longitude,
      newCenter.latitude,
      newCenter.longitude,
    );

    if (distanceMoved >= 200.0) {
      debugPrint('[HazardRadar] Rider moved ${distanceMoved.toStringAsFixed(0)}m (>200m). Polling viewport hazards.');
      fetchViewportHazards(newCenter, force: false);
    }
  }

  /// Polls the REST endpoint for hazards within viewport + buffer radius.
  Future<void> fetchViewportHazards(LatLng center, {bool force = false}) async {
    if (_state.isLoading && !force) return;

    _state = _state.copyWith(isLoading: true, hasError: false, errorMessage: null);
    notifyListeners();

    try {
      final response = await dio.get(
        '/api/v1/hazards/nearby',
        queryParameters: {
          'lat': center.latitude,
          'lng': center.longitude,
          'radius': bufferRadiusMeters,
        },
      ).timeout(const Duration(seconds: 8));

      final data = response.data as Map<String, dynamic>;
      final rawItems = data['items'] as List<dynamic>? ?? [];

      final now = DateTime.now();
      final freshPins = rawItems
          .map((item) => HazardPin.fromJson(item as Map<String, dynamic>))
          .where((pin) => !pin.isExpired) // Purge already expired
          .toList();

      _state = _state.copyWith(
        pins: freshPins,
        lastSuccessfulFetch: now,
        updatedSecondsAgo: 0,
        isLoading: false,
        hasError: false,
        errorMessage: null,
        lastFetchCenter: center,
      );
      notifyListeners();
    } on DioException catch (dioErr) {
      final errMsg = dioErr.type == DioExceptionType.connectionTimeout ||
              dioErr.type == DioExceptionType.connectionError
          ? "Network offline: Cannot refresh road hazards"
          : "Server error (${dioErr.response?.statusCode ?? '500'})";

      debugPrint('[HazardRadar] Hazard fetch error: $errMsg');
      _state = _state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: errMsg,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('[HazardRadar] Unexpected error: $e');
      _state = _state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: "Unable to refresh hazard radar",
      );
      notifyListeners();
    }
  }

  /// Purges any pins whose `expires_at` has passed client-side.
  void _purgeExpiredPins() {
    if (_state.pins.isEmpty) return;

    final beforeCount = _state.pins.length;
    final activePins = _state.pins.where((p) => !p.isExpired).toList();

    if (activePins.length != beforeCount) {
      final purged = beforeCount - activePins.length;
      debugPrint('[HazardRadar] Client-side auto-expired $purged hazard pin(s) in real time.');
      _state = _state.copyWith(pins: activePins);
      notifyListeners();
    }
  }

  void stop() {
    _pollingTimer?.cancel();
    _autoExpiryTimer?.cancel();
    _freshnessTicker?.cancel();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
