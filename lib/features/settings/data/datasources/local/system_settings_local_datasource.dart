import '../../../../../database/database_helper.dart';
import '../../../../../core/exceptions/app_exceptions.dart';
import '../../models/system_settings_model.dart';

/// Local data source for system settings using SQLite database.
///
/// Responsible for:
/// - Reading/writing system settings from/to database
/// - Key-value pair management
/// - Handling database errors
abstract class SystemSettingsLocalDataSource {
  /// Fetch system setting by key.
  ///
  /// Returns [SystemSettingsModel] or null if not found.
  /// Throws [DatabaseException] on database failures.
  Future<SystemSettingsModel?> getSetting(String key);

  /// Save or update system setting.
  ///
  /// Returns the saved [SystemSettingsModel] with timestamps.
  /// Throws [DatabaseException] on database failures.
  Future<SystemSettingsModel> setSetting(
    String key,
    String value, {
    String? description,
    String? category,
  });

  /// Delete system setting by key.
  ///
  /// Throws [DatabaseException] on database failures.
  Future<void> deleteSetting(String key);
}

/// Implementation of SystemSettingsLocalDataSource.
class SystemSettingsLocalDataSourceImpl
    implements SystemSettingsLocalDataSource {
  final DatabaseHelper _databaseHelper;

  SystemSettingsLocalDataSourceImpl(this._databaseHelper);

  @override
  Future<SystemSettingsModel?> getSetting(String key) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.query(
        'system_settings',
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );

      if (result.isEmpty) {
        return null;
      }

      return SystemSettingsModel.fromMap(result.first);
    } catch (e, stackTrace) {
      throw DatabaseException(
        'Failed to load system setting: $key',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<SystemSettingsModel> setSetting(
    String key,
    String value, {
    String? description,
    String? category,
  }) async {
    try {
      final db = await _databaseHelper.database;
      final now = DateTime.now();

      final data = {
        'key': key,
        'value': value,
        'description': description,
        'category': category,
        'updated_at': now.toIso8601String(),
      };

      // Try to update first
      final updateCount = await db.update(
        'system_settings',
        data,
        where: 'key = ?',
        whereArgs: [key],
      );

      // If no record was updated, insert new one
      if (updateCount == 0) {
        data['created_at'] = now.toIso8601String();
        await db.insert('system_settings', data);
      }

      return SystemSettingsModel(
        key: key,
        value: value,
        description: description,
        category: category,
        createdAt: now,
        updatedAt: now,
      );
    } catch (e, stackTrace) {
      throw DatabaseException(
        'Failed to save system setting: $key',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> deleteSetting(String key) async {
    try {
      final db = await _databaseHelper.database;
      await db.delete(
        'system_settings',
        where: 'key = ?',
        whereArgs: [key],
      );
    } catch (e, stackTrace) {
      throw DatabaseException(
        'Failed to delete system setting: $key',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}
