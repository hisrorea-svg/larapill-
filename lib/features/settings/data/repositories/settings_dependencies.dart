import '../../../../core/database/drift/daos/settings_drift_dao.dart';
import '../repositories/settings_repository_impl.dart';
import '../../domain/repositories/settings_repository.dart';

/// Factory class for creating Settings-related dependencies.
///
/// Architecture:
/// ```
/// UI → Controller → Repository → DAO/HiveStorage → Storage
/// ```
class SettingsDependencies {
  /// Create SettingsRepository using DAO and HiveStorage directly.
  ///
  /// - Pharmacy/System settings → Drift DAO → SQLite
  /// - Notification settings → HiveStorage → JSON
  static SettingsRepository createRepository(SettingsDriftDao dao) {
    return SettingsRepositoryImpl(dao);
  }
}
