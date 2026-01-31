import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/exceptions/app_exceptions.dart';
import '../../models/notification_settings_model.dart';

/// Local data source for notification settings using SharedPreferences.
///
/// Responsible for:
/// - Reading/writing notification settings from SharedPreferences
/// - Serializing/deserializing settings to/from JSON
/// - Handling local storage errors
abstract class NotificationSettingsLocalDataSource {
  /// Fetch notification settings from local storage.
  ///
  /// Returns [NotificationSettingsModel] with default values if not found.
  /// Throws [CacheException] on storage failures.
  Future<NotificationSettingsModel> getSettings();

  /// Save notification settings to local storage.
  ///
  /// Throws [CacheException] on storage failures.
  Future<void> saveSettings(NotificationSettingsModel settings);

  /// Clear notification settings from local storage.
  ///
  /// Throws [CacheException] on storage failures.
  Future<void> clearSettings();
}

/// Implementation of NotificationSettingsLocalDataSource.
class NotificationSettingsLocalDataSourceImpl
    implements NotificationSettingsLocalDataSource {
  static const String _settingsKey = 'notification_settings';

  final SharedPreferences? _prefs;

  NotificationSettingsLocalDataSourceImpl(this._prefs);

  @override
  Future<NotificationSettingsModel> getSettings() async {
    try {
      // If prefs not initialized, return defaults
      if (_prefs == null) {
        return const NotificationSettingsModel();
      }

      final jsonString = _prefs!.getString(_settingsKey);

      if (jsonString == null) {
        return const NotificationSettingsModel();
      }

      final decodedMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return NotificationSettingsModel.fromMap(decodedMap);
    } on FormatException catch (e, stackTrace) {
      throw CacheException(
        'Invalid notification settings format',
        originalError: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      throw CacheException(
        'Failed to load notification settings',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> saveSettings(NotificationSettingsModel settings) async {
    try {
      if (_prefs == null) return; // Silently ignore if not initialized
      final map = settings.toMap();
      final jsonString = jsonEncode(map);
      await _prefs!.setString(_settingsKey, jsonString);
    } catch (e, stackTrace) {
      throw CacheException(
        'Failed to save notification settings',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> clearSettings() async {
    try {
      if (_prefs == null) return; // Silently ignore if not initialized
      await _prefs!.remove(_settingsKey);
    } catch (e, stackTrace) {
      throw CacheException(
        'Failed to clear notification settings',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Hive-based implementation of NotificationSettingsLocalDataSource.
class NotificationSettingsHiveDataSourceImpl
    implements NotificationSettingsLocalDataSource {
  static const String _settingsKey = 'notification_settings';

  // Using HiveStorage import from core
  final dynamic _hiveStorage;

  NotificationSettingsHiveDataSourceImpl(this._hiveStorage);

  @override
  Future<NotificationSettingsModel> getSettings() async {
    try {
      // استخدام HiveStorage.getString مباشرة
      // ignore: avoid_dynamic_calls
      final jsonString = _hiveStorage.getString(_settingsKey);

      if (jsonString == null) {
        return const NotificationSettingsModel();
      }

      final decodedMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return NotificationSettingsModel.fromMap(decodedMap);
    } on FormatException catch (e, stackTrace) {
      throw CacheException(
        'Invalid notification settings format',
        originalError: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      throw CacheException(
        'Failed to load notification settings',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> saveSettings(NotificationSettingsModel settings) async {
    try {
      final map = settings.toMap();
      final jsonString = jsonEncode(map);
      // ignore: avoid_dynamic_calls
      await _hiveStorage.setString(_settingsKey, jsonString);
    } catch (e, stackTrace) {
      throw CacheException(
        'Failed to save notification settings',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> clearSettings() async {
    try {
      // ignore: avoid_dynamic_calls
      await _hiveStorage.remove(_settingsKey);
    } catch (e, stackTrace) {
      throw CacheException(
        'Failed to clear notification settings',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}
