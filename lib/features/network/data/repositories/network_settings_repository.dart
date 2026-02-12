// lib/features/network/data/repositories/network_settings_repository.dart
import 'dart:convert';
import '../../../../core/storage/hive_storage.dart';
import '../../domain/entities/network_settings_entity.dart';
import '../../domain/repositories/network_settings_repository_interface.dart';

/// تنفيذ Repository باستخدام HiveStorage
class NetworkSettingsRepositoryImpl
    implements NetworkSettingsRepositoryInterface {
  static const String _settingsKey = 'network_settings';
  static const String _firstLaunchKey = 'network_first_launch';

  // Singleton pattern
  static final NetworkSettingsRepositoryImpl _instance =
      NetworkSettingsRepositoryImpl._internal();
  factory NetworkSettingsRepositoryImpl() => _instance;
  NetworkSettingsRepositoryImpl._internal();

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
