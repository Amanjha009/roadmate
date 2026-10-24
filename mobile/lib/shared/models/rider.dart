import 'package:json_annotation/json_annotation.dart';

part 'rider.g.dart';

/// Represents a registered rider on the platform.
@JsonSerializable()
class Rider {
  /// Unique identifier.
  final String id;

  /// Full display name.
  final String name;

  /// Phone number with country code (e.g. "+919876543210").
  final String phone;

  /// URL to the rider's avatar image, if any.
  final String? avatarUrl;

  /// Trust / reputation score from 0–100.
  final int trustScore;

  /// Verification level: 1 = phone only, 2 = ID verified, 3 = fully verified.
  final int verificationLevel;

  /// Total kilometres ridden on the platform.
  final double totalKmRidden;

  /// When the account was created.
  final DateTime createdAt;

  const Rider({
    required this.id,
    required this.name,
    required this.phone,
    this.avatarUrl,
    this.trustScore = 0,
    this.verificationLevel = 1,
    this.totalKmRidden = 0,
    required this.createdAt,
  });

  factory Rider.fromJson(Map<String, dynamic> json) => _$RiderFromJson(json);

  Map<String, dynamic> toJson() => _$RiderToJson(this);
}
