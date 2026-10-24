import 'package:drift/drift.dart';

/// Cached rider profile data for offline access.
class CachedProfiles extends Table {
  /// Rider identifier.
  TextColumn get id => text()();

  /// Full profile JSON payload.
  TextColumn get jsonData => text()();

  /// Last time this profile cache was refreshed.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
