import 'package:drift/drift.dart';

/// Stores trip plans downloaded for offline access.
class CachedTrips extends Table {
  /// Unique trip identifier from the backend.
  TextColumn get id => text()();

  /// Full trip plan JSON payload.
  TextColumn get jsonData => text()();

  /// When this trip was cached locally.
  DateTimeColumn get downloadedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
