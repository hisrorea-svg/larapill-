// lib/features/network/data/repositories/network_settings_repository.dart
import 'dart:convert';
import '../../../../core/storage/hive_storage.dart';
import '../../domain/entities/network_settings_entity.dart';

/// واجهة Repository لإعدادات الشبكة
abstract class NetworkSettingsRepository {
  /// جلب الإعدادات الحالية
  NetworkSettingsEntity getSettings();

  /// حفظ الإعدادات
  Future<void> saveSettings(NetworkSettingsEntity settings);

  /// هل هذا أول إطلاق؟
  bool isFirstLaunch();

  /// تحديد أنه تم الإطلاق
  Future<void> markAsLaunched();

  /// مسح الإعدادات
  Future<void> clearSettings();
}

/// تنفيذ Repository باستخدام HiveStorage
class NetworkSettingsRepositoryImpl implements NetworkSettingsRepository {
  static const String _settingsKey = 'network_settings';
  static const String _firstLaunchKey = 'network_first_launch';

  const NetworkSettingsRepositoryImpl();

  @override
  NetworkSettingsEntity getSettings() {
    final jsonString = HiveStorage.getString(_settingsKey);
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
    await HiveStorage.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  @override
  bool isFirstLaunch() {
    return HiveStorage.getBool(_firstLaunchKey, defaultValue: true);
  }

  @override
  Future<void> markAsLaunched() async {
    await HiveStorage.setBool(_firstLaunchKey, false);
  }

  @override
  Future<void> clearSettings() async {
    await HiveStorage.remove(_settingsKey);
    await HiveStorage.remove(_firstLaunchKey);
  }
}
