import 'package:latlong2/latlong.dart';

/// Supported motorcycle-critical hazard categories on Indian highways and mountain passes.
enum HazardType {
  blackIce,
  waterCrossing,
  looseGravel,
  landslide,
  roadClosure,
  construction,
  pothole,
  dangerousBend,
  // Legacy / fallbacks
  flood,
  accident,
  roadblock,
  animalCrossing,
  poorVisibility,
  other,
}

/// Category-specific server-enforced TTLs in hours.
const Map<HazardType, int> hazardTtlHours = {
  HazardType.blackIce: 8,
  HazardType.waterCrossing: 12,
  HazardType.looseGravel: 48,
  HazardType.landslide: 72,
  HazardType.roadClosure: 168,
  HazardType.construction: 336,
  HazardType.pothole: 720,
  HazardType.dangerousBend: 2160,
  HazardType.flood: 12,
  HazardType.accident: 6,
  HazardType.roadblock: 72,
  HazardType.animalCrossing: 24,
  HazardType.poorVisibility: 8,
  HazardType.other: 24,
};

/// Hazard lifecycle state machine
enum HazardLifecycle {
  reported,
  underReview,
  confirmed,
  disputed,
  resolved,
  expired,
}

enum HazardSeverity {
  low,
  medium,
  high,
  critical,
}

/// Represents a verified hazard pin on the map with client-side auto-expiry.
class HazardPin {
  final String id;
  final HazardType type;
  final HazardLifecycle lifecycle;
  final HazardSeverity severity;
  final LatLng position;
  final String? description;
  final String? photoUrl;
  final double confidenceScore;
  final String sourceType; // BRO_POLICE, VERIFIED_RIDER, COMMUNITY
  final DateTime? expiresAt;
  final DateTime? lastConfirmedAt;
  final DateTime createdAt;
  final int upvotes;
  final int downvotes;

  const HazardPin({
    required this.id,
    required this.type,
    this.lifecycle = HazardLifecycle.reported,
    required this.severity,
    required this.position,
    this.description,
    this.photoUrl,
    this.confidenceScore = 0.5,
    this.sourceType = 'COMMUNITY',
    this.expiresAt,
    this.lastConfirmedAt,
    required this.createdAt,
    this.upvotes = 0,
    this.downvotes = 0,
  });

  /// Client-side auto-expiry: returns true the instant `expiresAt` passes,
  /// without waiting for the next server poll.
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Whether the hazard is confirmed by BRO/Police or multiple verified riders.
  bool get isHighTrust =>
      sourceType == 'BRO_POLICE' || (confidenceScore >= 0.8 && upvotes >= 2);

  /// Human-readable icon or emoji for this hazard type.
  String get displayIcon {
    switch (type) {
      case HazardType.blackIce:
        return '🧊';
      case HazardType.waterCrossing:
        return '🌊';
      case HazardType.looseGravel:
        return '🪨';
      case HazardType.landslide:
        return '🚨';
      case HazardType.roadClosure:
        return '🛑';
      case HazardType.construction:
        return '🚧';
      case HazardType.pothole:
        return '⚠️';
      case HazardType.dangerousBend:
        return '↩️';
      case HazardType.flood:
        return '🌊';
      case HazardType.accident:
        return '💥';
      case HazardType.roadblock:
        return '🛑';
      case HazardType.animalCrossing:
        return '🐂';
      case HazardType.poorVisibility:
        return '🌫️';
      case HazardType.other:
        return '⚠️';
    }
  }

  factory HazardPin.fromJson(Map<String, dynamic> json) {
    HazardType parseType(String? val) {
      switch (val) {
        case 'black_ice':
          return HazardType.blackIce;
        case 'water_crossing':
          return HazardType.waterCrossing;
        case 'loose_gravel':
          return HazardType.looseGravel;
        case 'landslide':
          return HazardType.landslide;
        case 'road_closure':
          return HazardType.roadClosure;
        case 'construction':
          return HazardType.construction;
        case 'pothole':
          return HazardType.pothole;
        case 'dangerous_bend':
          return HazardType.dangerousBend;
        case 'flood':
          return HazardType.flood;
        case 'accident':
          return HazardType.accident;
        case 'roadblock':
          return HazardType.roadblock;
        case 'animal_crossing':
          return HazardType.animalCrossing;
        case 'poor_visibility':
          return HazardType.poorVisibility;
        default:
          return HazardType.other;
      }
    }

    HazardLifecycle parseLifecycle(String? val) {
      switch (val) {
        case 'confirmed':
          return HazardLifecycle.confirmed;
        case 'disputed':
          return HazardLifecycle.disputed;
        case 'resolved':
          return HazardLifecycle.resolved;
        case 'expired':
          return HazardLifecycle.expired;
        case 'under_review':
          return HazardLifecycle.underReview;
        default:
          return HazardLifecycle.reported;
      }
    }

    HazardSeverity parseSeverity(String? val) {
      switch (val) {
        case 'low':
          return HazardSeverity.low;
        case 'high':
          return HazardSeverity.high;
        case 'critical':
          return HazardSeverity.critical;
        case 'medium':
        default:
          return HazardSeverity.medium;
      }
    }

    return HazardPin(
      id: json['id'] as String? ?? '',
      type: parseType(json['hazard_type'] as String?),
      lifecycle: parseLifecycle(json['lifecycle_status'] as String?),
      severity: parseSeverity(json['severity'] as String?),
      position: LatLng(
        (json['latitude'] as num?)?.toDouble() ?? 0.0,
        (json['longitude'] as num?)?.toDouble() ?? 0.0,
      ),
      description: json['description'] as String?,
      photoUrl: json['photo_url'] as String?,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.5,
      sourceType: json['source_type'] as String? ?? 'COMMUNITY',
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : null,
      lastConfirmedAt: json['last_confirmed_at'] != null
          ? DateTime.tryParse(json['last_confirmed_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      upvotes: (json['upvotes'] as num?)?.toInt() ?? 0,
      downvotes: (json['downvotes'] as num?)?.toInt() ?? 0,
    );
  }
}
