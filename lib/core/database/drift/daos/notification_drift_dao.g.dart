// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_drift_dao.dart';

// ignore_for_file: type=lint
mixin _$NotificationDriftDaoMixin on DatabaseAccessor<AppDatabase> {
  $NotificationsTable get notifications => attachedDatabase.notifications;
  NotificationDriftDaoManager get managers => NotificationDriftDaoManager(this);
}

class NotificationDriftDaoManager {
  final _$NotificationDriftDaoMixin _db;
  NotificationDriftDaoManager(this._db);
  $$NotificationsTableTableManager get notifications =>
      $$NotificationsTableTableManager(_db.attachedDatabase, _db.notifications);
}
