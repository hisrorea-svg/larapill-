/// Sync Queue Drift DAO - Type-safe database access for sync operations
library sync_drift_dao;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_database.dart';
import '../database_provider.dart';

part 'sync_drift_dao.g.dart';

/// Status constants for sync queue
class SyncStatus {
  static const int pending = 0;
  static const int synced = 1;
  static const int failed = 2;
}

/// DAO for SyncQueue table with type-safe queries
@DriftAccessor(tables: [SyncQueue, SystemSettings])
class SyncDriftDao extends DatabaseAccessor<AppDatabase>
    with _$SyncDriftDaoMixin {
  SyncDriftDao(super.db);

  // ─────────────────────────────────────────────────────────────────────────
  // SYNC QUEUE OPERATIONS
  // ─────────────────────────────────────────────────────────────────────────

  /// Enqueue an item for sync
  Future<void> enqueue({
    required String id,
    required String action,
    required String payload,
  }) async {
    await into(syncQueue).insert(SyncQueueCompanion.insert(
      id: id,
      action: action,
      payload: payload,
      status: const Value(SyncStatus.pending),
      retryCount: const Value(0),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  /// Get pending items (status = 0)
  Future<List<SyncQueueEntry>> getPending({int limit = 50}) {
    return (select(syncQueue)
          ..where((t) => t.status.equals(SyncStatus.pending))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Watch pending items count (reactive)
  Stream<int> watchPendingCount() {
    final query = selectOnly(syncQueue)
      ..addColumns([syncQueue.id.count()])
      ..where(syncQueue.status.equals(SyncStatus.pending));
    return query
        .map((row) => row.read(syncQueue.id.count()) ?? 0)
        .watchSingle();
  }

  /// Get failed items that can be retried (retry_count < 5)
  Future<List<SyncQueueEntry>> getFailed({int maxRetries = 5}) {
    return (select(syncQueue)
          ..where((t) =>
              t.status.equals(SyncStatus.failed) &
              t.retryCount.isSmallerThanValue(maxRetries))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Mark item as synced
  Future<void> markSynced(String id) async {
    await (update(syncQueue)..where((t) => t.id.equals(id))).write(
      SyncQueueCompanion(
        status: const Value(SyncStatus.synced),
        lastAttemptAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// Mark item as failed with error message
  Future<void> markFailed(String id, String errorMessage) async {
    final entry = await (select(syncQueue)..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (entry != null) {
      await (update(syncQueue)..where((t) => t.id.equals(id))).write(
        SyncQueueCompanion(
          status: const Value(SyncStatus.failed),
          retryCount: Value(entry.retryCount + 1),
          errorMessage: Value(errorMessage),
          lastAttemptAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
    }
  }

  /// Get pending count
  Future<int> getPendingCount() async {
    final query = selectOnly(syncQueue)
      ..addColumns([syncQueue.id.count()])
      ..where(syncQueue.status.equals(SyncStatus.pending));
    final result = await query.getSingle();
    return result.read(syncQueue.id.count()) ?? 0;
  }

  /// Cleanup old synced items
  Future<int> cleanupSyncedItems({int olderThanDays = 7}) async {
    final cutoff = DateTime.now()
        .subtract(Duration(days: olderThanDays))
        .millisecondsSinceEpoch;

    return await (delete(syncQueue)
          ..where((t) =>
              t.status.equals(SyncStatus.synced) &
              t.lastAttemptAt.isSmallerThanValue(cutoff)))
        .go();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TERMINAL CONFIG (using SystemSettings)
  // ─────────────────────────────────────────────────────────────────────────

  /// Get a setting value by key
  Future<String?> getSetting(String key) async {
    final result = await (select(systemSettings)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return result?.value;
  }

  /// Save a setting
  Future<void> saveSetting(String key, String value,
      {String? description}) async {
    await into(systemSettings).insertOnConflictUpdate(
      SystemSettingsCompanion.insert(
        key: key,
        value: value,
        description: Value(description),
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Get terminal config as a map
  Future<Map<String, String>> getTerminalConfig() async {
    final results = await (select(systemSettings)
          ..where((t) => t.category.equals('terminal')))
        .get();

    return {for (final row in results) row.key: row.value};
  }

  /// Save terminal config from a map
  Future<void> saveTerminalConfig(Map<String, String> config) async {
    await transaction(() async {
      for (final entry in config.entries) {
        await into(systemSettings).insertOnConflictUpdate(
          SystemSettingsCompanion.insert(
            key: entry.key,
            value: entry.value,
            category: const Value('terminal'),
            updatedAt: DateTime.now(),
          ),
        );
      }
    });
  }
}

/// Provider for SyncDriftDao
final syncDriftDaoProvider = Provider<SyncDriftDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SyncDriftDao(db);
});
