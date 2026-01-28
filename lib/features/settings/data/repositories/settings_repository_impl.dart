import '../../domain/entities/notification_settings_entity.dart';
import '../../domain/entities/pharmacy_settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/failures/settings_failure.dart';
import '../datasources/local/notification_settings_local_datasource.dart';
import '../datasources/local/pharmacy_settings_local_datasource.dart';
import '../datasources/local/system_settings_local_datasource.dart';
import '../models/notification_settings_model.dart';
import '../models/pharmacy_settings_model.dart';

/// Repository implementation for Settings.
///
/// Uses Either type for typed error handling
/// Never throws exceptions - always returns Either
class SettingsRepositoryImpl implements SettingsRepository {
  final NotificationSettingsLocalDataSource _notificationLocal;
  final PharmacySettingsLocalDataSource _pharmacyLocal;
  final SystemSettingsLocalDataSource _systemLocal;

  SettingsRepositoryImpl(
    this._notificationLocal,
    this._pharmacyLocal,
    this._systemLocal,
  );

  // ==================== Notification Settings ====================

  @override
  Future<Either<SettingsFailure, NotificationSettingsEntity>>
      getNotificationSettings() async {
    try {
      final model = await _notificationLocal.getSettings();
      return Either.right(model.toEntity());
    } catch (e) {
      return Either.left(
          DatabaseSettingsFailure('فشل في جلب إعدادات الإشعارات: $e'));
    }
  }

  @override
  Future<Either<SettingsFailure, NotificationSettingsEntity>>
      saveNotificationSettings(
    NotificationSettingsEntity settings,
  ) async {
    try {
      final model = NotificationSettingsModel.fromEntity(settings);
      await _notificationLocal.saveSettings(model);
      return Either.right(settings);
    } catch (e) {
      return Either.left(
          DatabaseSettingsFailure('فشل في حفظ إعدادات الإشعارات: $e'));
    }
  }

  // ==================== Pharmacy Settings ====================

  @override
  Future<Either<SettingsFailure, PharmacySettingsEntity?>>
      getPharmacySettings() async {
    try {
      final model = await _pharmacyLocal.getSettings();
      return Either.right(model?.toEntity());
    } catch (e) {
      return Either.left(
          DatabaseSettingsFailure('فشل في جلب إعدادات الصيدلية: $e'));
    }
  }

  @override
  Future<Either<SettingsFailure, PharmacySettingsEntity>> savePharmacySettings(
    PharmacySettingsEntity settings,
  ) async {
    try {
      // Validation
      if (settings.nameAr.isEmpty) {
        return const Either.left(
            ValidationSettingsFailure('اسم الصيدلية مطلوب'));
      }

      final model = PharmacySettingsModel.fromEntity(settings);
      final savedModel = await _pharmacyLocal.saveSettings(model);
      return Either.right(savedModel.toEntity());
    } catch (e) {
      return Either.left(
          DatabaseSettingsFailure('فشل في حفظ إعدادات الصيدلية: $e'));
    }
  }

  // ==================== System Settings ====================

  @override
  Future<Either<SettingsFailure, String?>> getSystemSetting(
    String key, {
    String? defaultValue,
  }) async {
    try {
      final model = await _systemLocal.getSetting(key);
      return Either.right(model?.value ?? defaultValue);
    } catch (e) {
      return Either.left(DatabaseSettingsFailure('فشل في جلب الإعداد: $e'));
    }
  }

  @override
  Future<Either<SettingsFailure, Unit>> setSystemSetting(
    String key,
    String value, {
    String? description,
    String? category,
  }) async {
    try {
      await _systemLocal.setSetting(
        key,
        value,
        description: description,
        category: category,
      );
      return const Either.right(Unit.unit);
    } catch (e) {
      return Either.left(DatabaseSettingsFailure('فشل في حفظ الإعداد: $e'));
    }
  }
}
