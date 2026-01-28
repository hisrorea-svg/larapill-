// lib/features/network/data/repositories/network_settings_repository.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/network_settings_entity.dart';

/// واجهة Repository لإعدادات الشبكة
abstract class NetworkSettingsRepository {
  /// جلب الإعدادات الحالية
  Future<NetworkSettingsEntity> getSettings();

  /// حفظ الإعدادات
  Future<void> saveSettings(NetworkSettingsEntity settings);

  /// هل هذا أول إطلاق؟
  Future<bool> isFirstLaunch();

  /// تحديد أنه تم الإطلاق
  Future<void> markAsLaunched();

  /// مسح الإعدادات
  Future<void> clearSettings();
}

/// تنفيذ Repository باستخدام SharedPreferences
class NetworkSettingsRepositoryImpl implements NetworkSettingsRepository {
  static const String _settingsKey = 'network_settings';
  static const String _firstLaunchKey = 'network_first_launch';

  final SharedPreferences _prefs;

  const NetworkSettingsRepositoryImpl(this._prefs);

  @override
  Future<NetworkSettingsEntity> getSettings() async {
    final jsonString = _prefs.getString(_settingsKey);
    if (jsonString == null) {
      // أول إطلاق - افترض السيرفر
      return NetworkSettingsEntity.serverDefaults();
    }
    try {
      return NetworkSettingsEntity.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>,
      );
    } catch (e) {
      // في حالة خطأ في القراءة، أعد الافتراضي
      return NetworkSettingsEntity.serverDefaults();
    }
  }

  @override
  Future<void> saveSettings(NetworkSettingsEntity settings) async {
    await _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  @override
  Future<bool> isFirstLaunch() async {
    return _prefs.getBool(_firstLaunchKey) ?? true;
  }

  @override
  Future<void> markAsLaunched() async {
    await _prefs.setBool(_firstLaunchKey, false);
  }

  @override
  Future<void> clearSettings() async {
    await _prefs.remove(_settingsKey);
    await _prefs.remove(_firstLaunchKey);
  }
}
