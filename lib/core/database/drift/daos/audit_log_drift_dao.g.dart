// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_log_drift_dao.dart';

// ignore_for_file: type=lint
mixin _$AuditLogDriftDaoMixin on DatabaseAccessor<AppDatabase> {
  $AuditLogsTable get auditLogs => attachedDatabase.auditLogs;
  AuditLogDriftDaoManager get managers => AuditLogDriftDaoManager(this);
}

class AuditLogDriftDaoManager {
  final _$AuditLogDriftDaoMixin _db;
  AuditLogDriftDaoManager(this._db);
  $$AuditLogsTableTableManager get auditLogs =>
      $$AuditLogsTableTableManager(_db.attachedDatabase, _db.auditLogs);
}
