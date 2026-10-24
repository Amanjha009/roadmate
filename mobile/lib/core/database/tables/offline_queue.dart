import 'package:drift/drift.dart';

/// Queue for user actions performed while offline.
///
/// Items are synced to the server when connectivity is restored,
/// then marked as [synced].
class OfflineQueue extends Table {
  /// Auto-incrementing local identifier.
  IntColumn get id => integer().autoIncrement()();

  /// Type of queued action (e.g. "report_hazard", "save_trip").
  TextColumn get actionType => text()();

  /// JSON payload for the action.
  TextColumn get payloadJson => text()();

  /// When the action was queued.
  DateTimeColumn get createdAt => dateTime()();

  /// Whether this item has been successfully synced.
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
}
