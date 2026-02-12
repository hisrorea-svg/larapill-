// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_logs_drift_dao.dart';

// ignore_for_file: type=lint
mixin _$SystemLogsDriftDaoMixin on DatabaseAccessor<AppDatabase> {
  $SystemLogsTable get systemLogs => attachedDatabase.systemLogs;
  SystemLogsDriftDaoManager get managers => SystemLogsDriftDaoManager(this);
}

class SystemLogsDriftDaoManager {
  final _$SystemLogsDriftDaoMixin _db;
  SystemLogsDriftDaoManager(this._db);
  $$SystemLogsTableTableManager get systemLogs =>
      $$SystemLogsTableTableManager(_db.attachedDatabase, _db.systemLogs);
}
