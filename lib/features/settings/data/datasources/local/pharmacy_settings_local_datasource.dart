import '../../../../../database/database_helper.dart';
import '../../../../../core/exceptions/app_exceptions.dart';
import '../../models/pharmacy_settings_model.dart';

/// Local data source for pharmacy settings using SQLite database.
///
/// Responsible for:
/// - Reading/writing pharmacy settings from/to database
/// - Converting database rows to models
/// - Handling database errors
abstract class PharmacySettingsLocalDataSource {
  /// Fetch pharmacy settings from database.
  ///
  /// Returns [PharmacySettingsModel] or null if not found.
  /// Throws [DatabaseException] on database failures.
  Future<PharmacySettingsModel?> getSettings();

  /// Save or update pharmacy settings in database.
  ///
  /// Returns the saved [PharmacySettingsModel] with id and timestamps.
  /// Throws [DatabaseException] on database failures.
  Future<PharmacySettingsModel> saveSettings(PharmacySettingsModel settings);
}

/// Implementation of PharmacySettingsLocalDataSource.
class PharmacySettingsLocalDataSourceImpl
    implements PharmacySettingsLocalDataSource {
  final DatabaseHelper _databaseHelper;

  PharmacySettingsLocalDataSourceImpl(this._databaseHelper);

  @override
  Future<PharmacySettingsModel?> getSettings() async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.query(
        'pharmacy_settings',
        limit: 1,
      );

      if (result.isEmpty) {
        return null;
      }

      return PharmacySettingsModel.fromMap(result.first);
    } catch (e, stackTrace) {
      throw DatabaseException(
        'Failed to load pharmacy settings',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<PharmacySettingsModel> saveSettings(
    PharmacySettingsModel settings,
  ) async {
    try {
      final db = await _databaseHelper.database;
      final now = DateTime.now();

      final data = settings.toMap();
      data['updated_at'] = now.toIso8601String();

      if (settings.id != null) {
        // Update existing record
        await db.update(
          'pharmacy_settings',
          data,
          where: 'id = ?',
          whereArgs: [settings.id],
        );
        return settings.copyWith(updatedAt: now);
      } else {
        // Insert new record
        data['created_at'] = now.toIso8601String();
        final id = await db.insert('pharmacy_settings', data);
        return settings.copyWith(
          id: id,
          createdAt: now,
          updatedAt: now,
        );
      }
    } catch (e, stackTrace) {
      throw DatabaseException(
        'Failed to save pharmacy settings',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}
