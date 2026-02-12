// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'users_drift_dao.dart';

// ignore_for_file: type=lint
mixin _$UsersDriftDaoMixin on DatabaseAccessor<AppDatabase> {
  $UsersTable get users => attachedDatabase.users;
  $UserSessionsTable get userSessions => attachedDatabase.userSessions;
  $UserActivitiesTable get userActivities => attachedDatabase.userActivities;
  UsersDriftDaoManager get managers => UsersDriftDaoManager(this);
}

class UsersDriftDaoManager {
  final _$UsersDriftDaoMixin _db;
  UsersDriftDaoManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db.attachedDatabase, _db.users);
  $$UserSessionsTableTableManager get userSessions =>
      $$UserSessionsTableTableManager(_db.attachedDatabase, _db.userSessions);
  $$UserActivitiesTableTableManager get userActivities =>
      $$UserActivitiesTableTableManager(
          _db.attachedDatabase, _db.userActivities);
}
