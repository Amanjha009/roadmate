import 'package:drift/drift.dart';

/// Locally cached hazard reports for offline map overlays.
class CachedHazards extends Table {
  /// Unique hazard identifier.
  TextColumn get id => text()();

  /// Latitude of the hazard location.
  RealColumn get lat => real()();

  /// Longitude of the hazard location.
  RealColumn get lng => real()();

  /// Hazard type (e.g. "pothole", "landslide", "flood").
  TextColumn get type => text()();

  /// Severity: "low", "medium", "high".
  TextColumn get severity => text()();

  /// When this hazard report expires and should be purged.
  DateTimeColumn get expiresAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
