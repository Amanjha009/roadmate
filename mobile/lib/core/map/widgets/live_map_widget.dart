import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/hazard_pin.dart';
import '../models/rider_telemetry.dart';
import '../services/live_location_service.dart';
import '../services/live_ride_connection_manager.dart';
import '../services/position_interpolator.dart';
import '../services/viewport_hazard_service.dart';

/// Reusable Real-Time Live Map Component.
///
/// Shared across:
/// 1. Home Hub mini-map (relaxed 15-30s location tracking, compact HUD).
/// 2. Full-screen Ride Room / Convoy mode (tight 3-5s location tracking, squad avatars with reconnecting states).
class LiveMapWidget extends StatefulWidget {
  final bool isMiniMap;
  final LatLng initialCenter;
  final double initialZoom;
  final LiveLocationService? locationService;
  final LiveRideConnectionManager? connectionManager;
  final ViewportHazardService? hazardService;
  final VoidCallback? onExpandPressed;
  final VoidCallback? onReportHazardPressed;

  const LiveMapWidget({
    super.key,
    this.isMiniMap = false,
    this.initialCenter = const LatLng(32.2432, 77.1892), // Manali Rohtang Pass default
    this.initialZoom = 13.0,
    this.locationService,
    this.connectionManager,
    this.hazardService,
    this.onExpandPressed,
    this.onReportHazardPressed,
  });

  @override
  State<LiveMapWidget> createState() => _LiveMapWidgetState();
}

class _LiveMapWidgetState extends State<LiveMapWidget> {
  late final MapController _mapController;
  late final PositionInterpolatorManager _interpolatorManager;

  // Local rider state
  RiderTelemetry? _myTelemetry;
  final Map<String, RiderTelemetry> _peerTelemetry = {};

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _interpolatorManager = PositionInterpolatorManager();

    _setupListeners();
  }

  void _setupListeners() {
    // 1. My GPS location stream
    widget.locationService?.telemetryStream.listen((telemetry) {
      if (!mounted) return;
      setState(() {
        _myTelemetry = telemetry;
      });

      // Push target to smooth interpolator
      _interpolatorManager.updateTarget(
        'me',
        telemetry.position,
        telemetry.headingDegrees,
        durationMs: widget.isMiniMap ? 15000 : 3500,
      );

      // Notify WebSocket of new position
      widget.connectionManager?.sendTelemetry(telemetry);

      // Check 200m movement for hazard radar
      widget.hazardService?.onViewportChanged(telemetry.position, isManualPanZoom: false);
    });

    // 2. Peer group ride members stream
    if (widget.connectionManager != null) {
      widget.connectionManager!.onPeerTelemetry = (telemetry) {
        if (!mounted) return;
        setState(() {
          _peerTelemetry[telemetry.riderId] = telemetry;
        });

        _interpolatorManager.updateTarget(
          telemetry.riderId,
          telemetry.position,
          telemetry.headingDegrees,
          durationMs: 3500,
        );
      };

      widget.connectionManager!.onPeerStatusChange = (riderId, status, lastSeen) {
        if (!mounted) return;
        setState(() {
          if (_peerTelemetry.containsKey(riderId)) {
            _peerTelemetry[riderId] = _peerTelemetry[riderId]!.copyWith(
              connectionState: status,
              lastSeen: lastSeen,
            );
          }
        });
      };
    }
  }

  @override
  void dispose() {
    _interpolatorManager.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hazardState = widget.hazardService?.state;
    final connState = widget.connectionManager?.state;
    final isReconnecting = connState == RideRoomConnectionState.reconnecting;
    final queuedPoints = widget.connectionManager?.queuedPointsCount ?? 0;

    return ClipRRect(
      borderRadius: widget.isMiniMap ? BorderRadius.circular(16) : BorderRadius.zero,
      child: Stack(
        children: [
          // FlutterMap Canvas
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialCenter,
              initialZoom: widget.initialZoom,
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture && pos.center != null) {
                  widget.hazardService?.onViewportChanged(pos.center!, isManualPanZoom: true);
                }
              },
            ),
            children: [
              // OpenStreetMap Standard Tiles for Motorcycle Touring
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.roadmate.india',
              ),

              // Hazard Pins Layer
              if (hazardState != null)
                MarkerLayer(
                  markers: hazardState.pins.map((pin) => _buildHazardMarker(pin)).toList(),
                ),

              // Peer Squad Members Markers (with independent smooth lerp animation)
              MarkerLayer(
                markers: _peerTelemetry.values.map((peer) => _buildPeerMarker(peer)).toList(),
              ),

              // My Own Rider Marker (Smooth lerp animation)
              if (_myTelemetry != null)
                MarkerLayer(
                  markers: [_buildMyMarker(_myTelemetry!)],
                ),
            ],
          ),

          // TOP STATUS BAR: Freshness timestamp & Network alert banner
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Network Alert or Reconnecting Banner
                if (isReconnecting)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE65100).withOpacity(0.92), // Deep touring amber
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6)],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Reconnecting to Ride Room... ${queuedPoints > 0 ? '($queuedPoints telemetry frames queued)' : ''}",
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (hazardState != null && hazardState.hasError)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC62828).withOpacity(0.92), // Alert red
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6)],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_off, size: 16, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            hazardState.errorMessage ?? "Hazard layer offline: Showing cached data",
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Layer Freshness Badge
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E232A).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF2C323D)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hazardState != null && !hazardState.hasError
                                ? const Color(0xFF00E676) // Vivid green
                                : const Color(0xFFFFB300), // Amber
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          hazardState != null ? hazardState.freshnessLabel : "Radar Active",
                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // FLOATING CONTROLS: Recenter & Hazard Report
          Positioned(
            bottom: 16,
            right: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isMiniMap && widget.onExpandPressed != null)
                  FloatingActionButton.small(
                    heroTag: 'map_expand_btn',
                    backgroundColor: const Color(0xFF1E232A),
                    onPressed: widget.onExpandPressed,
                    child: const Icon(Icons.fullscreen, color: Colors.white),
                  ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'map_recenter_btn',
                  backgroundColor: const Color(0xFF1E232A),
                  onPressed: () {
                    if (_myTelemetry != null) {
                      _mapController.move(_myTelemetry!.position, widget.initialZoom);
                    }
                  },
                  child: const Icon(Icons.my_location, color: Color(0xFFFF5722)),
                ),
                if (!widget.isMiniMap && widget.onReportHazardPressed != null) ...[
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'map_add_hazard_btn',
                    backgroundColor: const Color(0xFFFF5722),
                    onPressed: widget.onReportHazardPressed,
                    child: const Icon(Icons.add_alert, color: Colors.white),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds rider's own animated marker using native translation.
  Marker _buildMyMarker(RiderTelemetry telemetry) {
    final state = _interpolatorManager.getOrCreate('me', telemetry.position, telemetry.headingDegrees);

    return Marker(
      point: state.position,
      width: 50,
      height: 50,
      child: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          return Transform.rotate(
            angle: state.heading * (3.1415926535 / 180.0),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF5722),
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5722).withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.navigation, color: Colors.white, size: 24),
            ),
          );
        },
      ),
    );
  }

  /// Builds a squad member's marker with smooth interpolation and "reconnecting..." tag.
  Marker _buildPeerMarker(RiderTelemetry peer) {
    final state = _interpolatorManager.getOrCreate(peer.riderId, peer.position, peer.headingDegrees);

    return Marker(
      point: state.position,
      width: 72,
      height: 64,
      child: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar circle with connection ring
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2196F3),
                  border: Border.all(
                    color: peer.isReconnecting ? const Color(0xFFFFB300) : Colors.white,
                    width: 2,
                  ),
                  boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
                ),
                child: Center(
                  child: Text(
                    peer.riderName.isNotEmpty ? peer.riderName[0].toUpperCase() : 'R',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),

              // Reconnecting pill or Rider Name
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: peer.isReconnecting ? const Color(0xFFE65100) : Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  peer.isReconnecting ? "reconnecting..." : peer.riderName,
                  style: TextStyle(
                    color: peer.isReconnecting ? Colors.white : Colors.white70,
                    fontSize: 9,
                    fontWeight: peer.isReconnecting ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Builds a hazard radar pin with severity indicator.
  Marker _buildHazardMarker(HazardPin pin) {
    Color getBorderColor() {
      switch (pin.severity) {
        case HazardSeverity.critical:
        case HazardSeverity.high:
          return const Color(0xFFFF1744);
        case HazardSeverity.medium:
          return const Color(0xFFFF9100);
        case HazardSeverity.low:
          return const Color(0xFF2979FF);
      }
    }

    return Marker(
      point: pin.position,
      width: 38,
      height: 38,
      child: GestureDetector(
        onTap: () {
          _showHazardDetailSheet(pin);
        },
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E232A),
            shape: BoxShape.circle,
            border: Border.all(color: getBorderColor(), width: 2),
            boxShadow: [
              BoxShadow(
                color: getBorderColor().withOpacity(0.4),
                blurRadius: 6,
              ),
            ],
          ),
          child: Center(
            child: Text(pin.displayIcon, style: const TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }

  void _showHazardDetailSheet(HazardPin pin) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16191E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(pin.displayIcon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      pin.type.name.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      pin.severity.name.toUpperCase(),
                      style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                pin.description ?? "Road hazard reported by fellow touring rider.",
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "📍 ${pin.position.latitude.toStringAsFixed(4)}°, ${pin.position.longitude.toStringAsFixed(4)}°",
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  Text(
                    "👍 ${pin.upvotes} confirmations",
                    style: const TextStyle(color: Color(0xFF00E676), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
