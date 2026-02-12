// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_drift_dao.dart';

// ignore_for_file: type=lint
mixin _$SyncDriftDaoMixin on DatabaseAccessor<AppDatabase> {
  $SyncQueueTable get syncQueue => attachedDatabase.syncQueue;
  $SystemSettingsTable get systemSettings => attachedDatabase.systemSettings;
  SyncDriftDaoManager get managers => SyncDriftDaoManager(this);
}

class SyncDriftDaoManager {
  final _$SyncDriftDaoMixin _db;
  SyncDriftDaoManager(this._db);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db.attachedDatabase, _db.syncQueue);
  $$SystemSettingsTableTableManager get systemSettings =>
      $$SystemSettingsTableTableManager(
          _db.attachedDatabase, _db.systemSettings);
}
