import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/storage/hive_storage.dart';
import '../../../../database/database_helper.dart';
import '../datasources/local/notification_settings_local_datasource.dart';
import '../datasources/local/pharmacy_settings_local_datasource.dart';
import '../datasources/local/system_settings_local_datasource.dart';
import '../repositories/settings_repository_impl.dart';
import '../../domain/repositories/settings_repository.dart';

/// Factory class for creating Settings-related dependencies.
///
/// This centralizes all dependency creation for the Settings feature,
/// making it easy to:
/// - Mock dependencies in tests
/// - Swap implementations
/// - Manage lifecycles
class SettingsDependencies {
  /// Create NotificationSettingsLocalDataSource instance (SharedPreferences).
  static NotificationSettingsLocalDataSource createNotificationDataSource(
    SharedPreferences prefs,
  ) {
    return NotificationSettingsLocalDataSourceImpl(prefs);
  }

  /// Create NotificationSettingsLocalDataSource using HiveStorage.
  static NotificationSettingsLocalDataSource
      createNotificationDataSourceFromHive() {
    return NotificationSettingsHiveDataSourceImpl(HiveStorage);
  }

  /// Create PharmacySettingsLocalDataSource instance.
  static PharmacySettingsLocalDataSource createPharmacyDataSource(
    DatabaseHelper databaseHelper,
  ) {
    return PharmacySettingsLocalDataSourceImpl(databaseHelper);
  }

  /// Create SystemSettingsLocalDataSource instance.
  static SystemSettingsLocalDataSource createSystemDataSource(
    DatabaseHelper databaseHelper,
  ) {
    return SystemSettingsLocalDataSourceImpl(databaseHelper);
  }

  /// Create SettingsRepository instance (SharedPreferences).
  static SettingsRepository createRepository(
    SharedPreferences prefs,
    DatabaseHelper databaseHelper,
  ) {
    final notificationLocal = createNotificationDataSource(prefs);
    final pharmacyLocal = createPharmacyDataSource(databaseHelper);
    final systemLocal = createSystemDataSource(databaseHelper);

    return SettingsRepositoryImpl(
      notificationLocal,
      pharmacyLocal,
      systemLocal,
    );
  }

  /// Create SettingsRepository using HiveStorage.
  static SettingsRepository createRepositoryFromHive(
    DatabaseHelper databaseHelper,
  ) {
    final notificationLocal = createNotificationDataSourceFromHive();
    final pharmacyLocal = createPharmacyDataSource(databaseHelper);
    final systemLocal = createSystemDataSource(databaseHelper);

    return SettingsRepositoryImpl(
      notificationLocal,
      pharmacyLocal,
      systemLocal,
    );
  }
}
