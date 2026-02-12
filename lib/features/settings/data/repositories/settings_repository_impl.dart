import 'dart:convert';
import 'package:drift/drift.dart';

import '../../../../core/database/drift/daos/settings_drift_dao.dart';
import '../../../../core/database/drift/app_database.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../data/models/notification_settings_model.dart';
import '../../domain/entities/notification_settings_entity.dart';
import '../../domain/entities/pharmacy_settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/failures/settings_failure.dart';

/// Repository implementation for Settings.
///
/// Uses Drift DAOs and HiveStorage directly.
/// Uses Either type for typed error handling - never throws exceptions.
///
/// Architecture:
/// ```
/// UI → Controller → Repository → DAO/HiveStorage → Storage
/// ```
class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsDriftDao _dao;

  /// Hive settings key for notifications
  static const String _notificationSettingsKey = 'notification_settings';

  SettingsRepositoryImpl(this._dao);

  // ==================== Notification Settings ====================
  // Uses HiveStorage directly

  @override
  Future<Either<SettingsFailure, NotificationSettingsEntity>>
      getNotificationSettings() async {
    try {
      final jsonString = HiveStorage.getString(_notificationSettingsKey);

      if (jsonString == null) {
        return Either.right(const NotificationSettingsModel().toEntity());
      }

      final decodedMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final model = NotificationSettingsModel.fromMap(decodedMap);
      return Either.right(model.toEntity());
    } on FormatException catch (e) {
      return Either.left(
          DatabaseSettingsFailure('Invalid notification settings format: $e'));
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
      final jsonString = jsonEncode(model.toMap());
      await HiveStorage.setString(_notificationSettingsKey, jsonString);
      return Either.right(settings);
    } catch (e) {
      return Either.left(
          DatabaseSettingsFailure('فشل في حفظ إعدادات الإشعارات: $e'));
    }
  }

  // ==================== Pharmacy Settings ====================
  // Uses DAO directly

  @override
  Future<Either<SettingsFailure, PharmacySettingsEntity?>>
      getPharmacySettings() async {
    try {
      final entry = await _dao.getPharmacySettings();
      if (entry == null) return const Either.right(null);
      return Either.right(_mapPharmacyEntryToEntity(entry));
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
      // Business Logic: Validation
      if (settings.nameAr.isEmpty) {
        return const Either.left(
            ValidationSettingsFailure('اسم الصيدلية مطلوب'));
      }

      final id = await _dao.savePharmacySettings(
        PharmacySettingsCompanion(
          nameAr: Value(settings.nameAr),
          nameEn: Value(settings.nameEn),
          licenseNumber: Value(settings.licenseNumber),
          phone: Value(settings.phone),
          mobile: Value(settings.mobile),
          email: Value(settings.email),
          website: Value(settings.website),
          address: Value(settings.address),
          city: Value(settings.city),
          taxNumber: Value(settings.taxNumber),
          commercialRegistration: Value(settings.commercialRegistration),
          logoPath: Value(settings.logoPath),
        ),
      );

      return Either.right(settings.copyWith(id: id));
    } catch (e) {
      return Either.left(
          DatabaseSettingsFailure('فشل في حفظ إعدادات الصيدلية: $e'));
    }
  }

  // ==================== System Settings ====================
  // Uses DAO directly

  @override
  Future<Either<SettingsFailure, String?>> getSystemSetting(
    String key, {
    String? defaultValue,
  }) async {
    try {
      final value = await _dao.getSettingValue(key);
      return Either.right(value ?? defaultValue);
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
      await _dao.saveSetting(
        key: key,
        value: value,
        description: description,
        category: category ?? 'general',
      );
      return const Either.right(Unit.unit);
    } catch (e) {
      return Either.left(DatabaseSettingsFailure('فشل في حفظ الإعداد: $e'));
    }
  }

  // ==================== Private Mappers ====================

  PharmacySettingsEntity _mapPharmacyEntryToEntity(PharmacySettingEntry entry) {
    return PharmacySettingsEntity(
      id: entry.id,
      nameAr: entry.nameAr,
      nameEn: entry.nameEn,
      licenseNumber: entry.licenseNumber,
      phone: entry.phone,
      mobile: entry.mobile,
      email: entry.email,
      website: entry.website,
      address: entry.address,
      city: entry.city,
      taxNumber: entry.taxNumber,
      commercialRegistration: entry.commercialRegistration,
      logoPath: entry.logoPath,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }
}
