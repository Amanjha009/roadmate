import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/cached_hazards.dart';
import 'tables/cached_profiles.dart';
import 'tables/cached_trips.dart';
import 'tables/offline_queue.dart';

part 'app_database.g.dart';

/// Provides the singleton [AppDatabase] instance.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// RoadMate India local SQLite database.
///
/// Tables:
/// * [CachedTrips] — downloaded trip plans.
/// * [CachedHazards] — nearby hazard reports.
/// * [OfflineQueue] — actions queued while offline.
/// * [CachedProfiles] — rider profile snapshots.
@DriftDatabase(
  tables: [CachedTrips, CachedHazards, OfflineQueue, CachedProfiles],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ── CachedTrips DAO ────────────────────────────────────────────

  /// Inserts or replaces a cached trip.
  Future<void> upsertTrip(CachedTrip trip) {
    return into(cachedTrips).insertOnConflictUpdate(trip);
  }

  /// Returns all locally cached trips.
  Future<List<CachedTrip>> getAllTrips() {
    return select(cachedTrips).get();
  }

  /// Deletes a cached trip by [tripId].
  Future<int> deleteTrip(String tripId) {
    return (delete(cachedTrips)..where((t) => t.id.equals(tripId))).go();
  }

  // ── CachedHazards DAO ──────────────────────────────────────────

  /// Inserts or replaces a cached hazard.
  Future<void> upsertHazard(CachedHazard hazard) {
    return into(cachedHazards).insertOnConflictUpdate(hazard);
  }

  /// Returns all non-expired cached hazards.
  Future<List<CachedHazard>> getActiveHazards() {
    return (select(cachedHazards)
          ..where((h) => h.expiresAt.isBiggerThanValue(DateTime.now())))
        .get();
  }

  /// Removes expired hazards from the local cache.
  Future<int> purgeExpiredHazards() {
    return (delete(cachedHazards)
          ..where((h) => h.expiresAt.isSmallerThanValue(DateTime.now())))
        .go();
  }

  // ── OfflineQueue DAO ───────────────────────────────────────────

  /// Enqueues an offline action.
  Future<int> enqueueAction({
    required String actionType,
    required String payloadJson,
  }) {
    return into(offlineQueue).insert(
      OfflineQueueCompanion.insert(
        actionType: actionType,
        payloadJson: payloadJson,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Returns all un-synced queue items, ordered oldest first.
  Future<List<OfflineQueueData>> getPendingActions() {
    return (select(offlineQueue)
          ..where((q) => q.synced.equals(false))
          ..orderBy([(q) => OrderingTerm.asc(q.createdAt)]))
        .get();
  }

  /// Marks a queue item as synced.
  Future<void> markSynced(int queueId) {
    return (update(offlineQueue)..where((q) => q.id.equals(queueId))).write(
      const OfflineQueueCompanion(synced: Value(true)),
    );
  }

  // ── CachedProfiles DAO ─────────────────────────────────────────

  /// Inserts or replaces a cached profile.
  Future<void> upsertProfile(CachedProfile profile) {
    return into(cachedProfiles).insertOnConflictUpdate(profile);
  }

  /// Reads a cached profile by rider [profileId].
  Future<CachedProfile?> getProfile(String profileId) {
    return (select(cachedProfiles)..where((p) => p.id.equals(profileId)))
        .getSingleOrNull();
  }
}

/// Opens (or creates) the database file in the app's documents directory.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'roadmate.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
