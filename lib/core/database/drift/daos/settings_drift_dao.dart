/// Settings Drift DAO - Type-safe database access for system and pharmacy settings
library settings_drift_dao;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_database.dart';
import '../database_provider.dart';

part 'settings_drift_dao.g.dart';

/// DAO for SystemSettings and PharmacySettings tables with type-safe queries
@DriftAccessor(tables: [SystemSettings, PharmacySettings])
class SettingsDriftDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDriftDaoMixin {
  SettingsDriftDao(super.db);

  // ─────────────────────────────────────────────────────────────────────────
  // SYSTEM SETTINGS (Key-Value Store)
  // ─────────────────────────────────────────────────────────────────────────

  /// Get a setting value by key
  Future<SystemSettingEntry?> getSetting(String key) {
    return (select(systemSettings)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
  }

  /// Get setting value as string (convenience)
  Future<String?> getSettingValue(String key) async {
    final entry = await getSetting(key);
    return entry?.value;
  }

  /// Save or update a setting
  Future<void> saveSetting({
    required String key,
    required String value,
    String? description,
    String category = 'general',
  }) async {
    await into(systemSettings).insertOnConflictUpdate(
      SystemSettingsCompanion.insert(
        key: key,
        value: value,
        description: Value(description),
        category: Value(category),
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Delete a setting
  Future<void> deleteSetting(String key) async {
    await (delete(systemSettings)..where((t) => t.key.equals(key))).go();
  }

  /// Get all settings in a category
  Future<List<SystemSettingEntry>> getSettingsByCategory(String category) {
    return (select(systemSettings)..where((t) => t.category.equals(category)))
        .get();
  }

  /// Get all settings as a map
  Future<Map<String, String>> getAllSettingsAsMap() async {
    final entries = await select(systemSettings).get();
    return {for (final e in entries) e.key: e.value};
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PHARMACY SETTINGS (Entity Storage)
  // ─────────────────────────────────────────────────────────────────────────

  /// Get pharmacy settings (single record)
  Future<PharmacySettingEntry?> getPharmacySettings() {
    return (select(pharmacySettings)..limit(1)).getSingleOrNull();
  }

  /// Watch pharmacy settings (reactive)
  Stream<PharmacySettingEntry?> watchPharmacySettings() {
    return (select(pharmacySettings)..limit(1)).watchSingleOrNull();
  }

  /// Save or update pharmacy settings
  Future<int> savePharmacySettings(PharmacySettingsCompanion settings) async {
    // Check if exists
    final existing = await getPharmacySettings();

    if (existing != null) {
      // Update existing record
      await (update(pharmacySettings)..where((t) => t.id.equals(existing.id)))
          .write(settings.copyWith(
        updatedAt: Value(DateTime.now()),
      ));
      return existing.id;
    } else {
      // Insert new record
      final now = DateTime.now();
      return await into(pharmacySettings).insert(
        settings.copyWith(
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    }
  }

  /// Create pharmacy settings with all fields
  Future<int> createPharmacySettings({
    required String nameAr,
    String? nameEn,
    String? licenseNumber,
    String? phone,
    String? mobile,
    String? email,
    String? website,
    String? address,
    String? city,
    String? taxNumber,
    String? commercialRegistration,
    String? logoPath,
  }) async {
    final now = DateTime.now();
    return await into(pharmacySettings).insert(
      PharmacySettingsCompanion.insert(
        nameAr: nameAr,
        nameEn: Value(nameEn),
        licenseNumber: Value(licenseNumber),
        phone: Value(phone),
        mobile: Value(mobile),
        email: Value(email),
        website: Value(website),
        address: Value(address),
        city: Value(city),
        taxNumber: Value(taxNumber),
        commercialRegistration: Value(commercialRegistration),
        logoPath: Value(logoPath),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}

/// Provider for SettingsDriftDao
final settingsDriftDaoProvider = Provider<SettingsDriftDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SettingsDriftDao(db);
});
