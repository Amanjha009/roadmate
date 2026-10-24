import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/rider_telemetry.dart';

/// Connection states for the Ride Room WebSocket.
enum RideRoomConnectionState {
  connecting,
  connected,
  reconnecting,
  disconnected,
}

/// Callback types for events
typedef OnPeerTelemetry = void Function(RiderTelemetry telemetry);
typedef OnPeerStatusChange = void Function(String riderId, RiderConnectionState status, DateTime? lastSeen);
typedef OnConnectionStateChange = void Function(RideRoomConnectionState state);
typedef OnGapRecovered = void Function(int queuedPointsCount);

/// Manages real-time WebSocket connection to `/ws/rides/:id`.
///
/// Features:
/// - Offline queueing during dead zones/tunnels.
/// - Flushes queued updates with gap indication on reconnection.
/// - Peer rider status tracking: displays "reconnecting..." rather than frozen stale dots.
/// - Exponential backoff auto-reconnect.
class LiveRideConnectionManager {
  final String baseWsUrl;
  final String rideRoomId;
  final String myRiderId;
  final String myRiderName;

  WebSocket? _webSocket;
  RideRoomConnectionState _state = RideRoomConnectionState.disconnected;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  Timer? _stalePeerWatchdogTimer;
  int _reconnectAttempts = 0;

  // Local offline queue for dead zone telemetry
  final List<Map<String, dynamic>> _offlineQueue = [];

  // Active peer members in the ride room
  final Map<String, RiderTelemetry> _peerMembers = {};

  // Event callbacks
  OnPeerTelemetry? onPeerTelemetry;
  OnPeerStatusChange? onPeerStatusChange;
  OnConnectionStateChange? onConnectionStateChange;
  OnGapRecovered? onGapRecovered;

  LiveRideConnectionManager({
    required this.baseWsUrl,
    required this.rideRoomId,
    required this.myRiderId,
    required this.myRiderName,
  });

  RideRoomConnectionState get state => _state;
  Map<String, RiderTelemetry> get peerMembers => Map.unmodifiable(_peerMembers);
  int get queuedPointsCount => _offlineQueue.length;

  /// Connect to the ride room WebSocket.
  Future<void> connect() async {
    if (_state == RideRoomConnectionState.connected || _state == RideRoomConnectionState.connecting) {
      return;
    }

    _updateState(RideRoomConnectionState.connecting);

    final cleanUrl = baseWsUrl.endsWith('/')
        ? '${baseWsUrl}ws/rides/$rideRoomId'
        : '$baseWsUrl/ws/rides/$rideRoomId';

    try {
      debugPrint('[LiveRideWS] Connecting to $cleanUrl...');
      _webSocket = await WebSocket.connect(cleanUrl).timeout(const Duration(seconds: 5));
      _reconnectAttempts = 0;
      _updateState(RideRoomConnectionState.connected);

      _listenToSocket();
      _startPingKeepalive();
      _startStalePeerWatchdog();

      // Flush offline queue if returning from dead zone
      _flushOfflineQueue();
    } catch (e) {
      debugPrint('[LiveRideWS] Connection failed: $e. Initiating reconnect...');
      _handleDisconnect();
    }
  }

  void _listenToSocket() {
    _webSocket?.listen(
      (data) {
        try {
          final Map<String, dynamic> msg = jsonDecode(data as String);
          _handleIncomingMessage(msg);
        } catch (e) {
          debugPrint('[LiveRideWS] JSON decode error: $e');
        }
      },
      onDone: () {
        debugPrint('[LiveRideWS] Socket closed by server or network loss.');
        _handleDisconnect();
      },
      onError: (err) {
        debugPrint('[LiveRideWS] Socket error: $err');
        _handleDisconnect();
      },
      cancelOnError: true,
    );
  }

  void _handleIncomingMessage(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;

    if (type == 'member_position') {
      final riderId = msg['rider_id'] as String?;
      if (riderId == null || riderId == myRiderId) return;

      final telemetry = RiderTelemetry(
        riderId: riderId,
        riderName: msg['rider_name'] as String? ?? 'Rider',
        position: LatLng(
          (msg['lat'] as num?)?.toDouble() ?? 0.0,
          (msg['lng'] as num?)?.toDouble() ?? 0.0,
        ),
        speedKmh: (msg['speed'] as num?)?.toDouble() ?? 0.0,
        headingDegrees: (msg['heading'] as num?)?.toDouble() ?? 0.0,
        altitudeMeters: (msg['altitude'] as num?)?.toDouble() ?? 0.0,
        timestamp: msg['timestamp'] != null
            ? DateTime.tryParse(msg['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
        connectionState: RiderConnectionState.online,
        lastSeen: DateTime.now(),
      );

      _peerMembers[riderId] = telemetry;
      onPeerTelemetry?.call(telemetry);
    } else if (type == 'rider_status') {
      final riderId = msg['rider_id'] as String?;
      final statusStr = msg['status'] as String?;
      if (riderId == null || riderId == myRiderId) return;

      final status = statusStr == 'online'
          ? RiderConnectionState.online
          : RiderConnectionState.reconnecting;

      final lastSeen = msg['last_seen'] != null
          ? DateTime.tryParse(msg['last_seen'] as String)
          : DateTime.now();

      if (_peerMembers.containsKey(riderId)) {
        _peerMembers[riderId] = _peerMembers[riderId]!.copyWith(
          connectionState: status,
          lastSeen: lastSeen,
        );
      }

      onPeerStatusChange?.call(riderId, status, lastSeen);
    }
  }

  /// Pushes current rider's live position update.
  /// If disconnected/dead-zone, queues update locally.
  void sendTelemetry(RiderTelemetry telemetry) {
    final payload = {
      'type': 'telemetry',
      'rider_id': myRiderId,
      'rider_name': myRiderName,
      'lat': telemetry.position.latitude,
      'lng': telemetry.position.longitude,
      'speed': telemetry.speedKmh,
      'heading': telemetry.headingDegrees,
      'altitude': telemetry.altitudeMeters,
      'timestamp': telemetry.timestamp.toIso8601String(),
    };

    if (_state == RideRoomConnectionState.connected && _webSocket != null) {
      try {
        _webSocket!.add(jsonEncode(payload));
      } catch (e) {
        debugPrint('[LiveRideWS] Send failed: $e, queuing locally.');
        _queueLocalUpdate(payload);
        _handleDisconnect();
      }
    } else {
      // Dead zone / tunnel: queue locally
      _queueLocalUpdate(payload);
    }
  }

  void _queueLocalUpdate(Map<String, dynamic> payload) {
    // Limit queue size to last 150 points (~10 mins at 4s intervals)
    if (_offlineQueue.length >= 150) {
      _offlineQueue.removeAt(0);
    }
    _offlineQueue.add(payload);
  }

  /// Flushes locally queued points upon reconnecting.
  void _flushOfflineQueue() {
    if (_offlineQueue.isEmpty) return;

    final queuedCount = _offlineQueue.length;
    debugPrint('[LiveRideWS] Reconnected! Flushing $queuedCount queued points...');

    final flushMsg = {
      'type': 'queue_flush',
      'rider_id': myRiderId,
      'rider_name': myRiderName,
      'points': List<Map<String, dynamic>>.from(_offlineQueue),
    };

    try {
      _webSocket?.add(jsonEncode(flushMsg));
      _offlineQueue.clear();
      onGapRecovered?.call(queuedCount);
    } catch (e) {
      debugPrint('[LiveRideWS] Queue flush failed: $e');
    }
  }

  void _handleDisconnect() {
    _webSocket = null;
    _pingTimer?.cancel();
    _updateState(RideRoomConnectionState.reconnecting);

    // Schedule exponential backoff reconnect
    _reconnectTimer?.cancel();
    _reconnectAttempts++;
    final backoffSecs = (_reconnectAttempts * 2).clamp(2, 20);

    debugPrint('[LiveRideWS] Will reconnect in $backoffSecs seconds (attempt #$_reconnectAttempts)...');
    _reconnectTimer = Timer(Duration(seconds: backoffSecs), () {
      connect();
    });
  }

  void _startPingKeepalive() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (_state == RideRoomConnectionState.connected && _webSocket != null) {
        try {
          _webSocket!.add(jsonEncode({'type': 'ping'}));
        } catch (_) {
          _handleDisconnect();
        }
      }
    });
  }

  /// Watchdog: If a peer rider sends no updates for > 15s (3x standard 4s interval),
  /// proactively mark them as "reconnecting..." rather than presenting a stale dot as current.
  void _startStalePeerWatchdog() {
    _stalePeerWatchdogTimer?.cancel();
    _stalePeerWatchdogTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final now = DateTime.now();
      _peerMembers.forEach((id, member) {
        if (member.connectionState == RiderConnectionState.online) {
          if (now.difference(member.timestamp).inSeconds > 15) {
            _peerMembers[id] = member.copyWith(
              connectionState: RiderConnectionState.reconnecting,
              lastSeen: member.timestamp,
            );
            onPeerStatusChange?.call(id, RiderConnectionState.reconnecting, member.timestamp);
          }
        }
      });
    });
  }

  void _updateState(RideRoomConnectionState newState) {
    if (_state != newState) {
      _state = newState;
      onConnectionStateChange?.call(_state);
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _stalePeerWatchdogTimer?.cancel();
    try {
      _webSocket?.close();
    } catch (_) {}
    _webSocket = null;
    _updateState(RideRoomConnectionState.disconnected);
  }

  void dispose() {
    disconnect();
  }
}
