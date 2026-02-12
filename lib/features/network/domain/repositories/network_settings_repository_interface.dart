// lib/features/network/domain/repositories/network_settings_repository_interface.dart
import '../entities/network_settings_entity.dart';

/// واجهة Repository لإعدادات الشبكة
abstract class NetworkSettingsRepositoryInterface {
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
