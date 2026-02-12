// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_drift_dao.dart';

// ignore_for_file: type=lint
mixin _$SettingsDriftDaoMixin on DatabaseAccessor<AppDatabase> {
  $SystemSettingsTable get systemSettings => attachedDatabase.systemSettings;
  $PharmacySettingsTable get pharmacySettings =>
      attachedDatabase.pharmacySettings;
  SettingsDriftDaoManager get managers => SettingsDriftDaoManager(this);
}

class SettingsDriftDaoManager {
  final _$SettingsDriftDaoMixin _db;
  SettingsDriftDaoManager(this._db);
  $$SystemSettingsTableTableManager get systemSettings =>
      $$SystemSettingsTableTableManager(
          _db.attachedDatabase, _db.systemSettings);
  $$PharmacySettingsTableTableManager get pharmacySettings =>
      $$PharmacySettingsTableTableManager(
          _db.attachedDatabase, _db.pharmacySettings);
}
