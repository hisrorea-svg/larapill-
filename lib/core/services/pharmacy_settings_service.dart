import '../database/drift/daos/settings_drift_dao.dart';

class PharmacySettingsService {
  static PharmacySettingsService? _instance;
  static SettingsDriftDao? _dao;

  PharmacySettingsService._();

  factory PharmacySettingsService() {
    return instance;
  }

  /// Static getter for backward compatibility
  static PharmacySettingsService get instance {
    _instance ??= PharmacySettingsService._();
    return _instance!;
  }

  /// Initialize with DAO from DI
  static void init(SettingsDriftDao dao) {
    _dao = dao;
  }

  Map<String, dynamic>? _cachedSettings;

  // جلب إعدادات الصيدلية
  Future<Map<String, dynamic>> getPharmacySettings() async {
    if (_cachedSettings != null) {
      return _cachedSettings!;
    }

    if (_dao == null) {
      return _getDefaultSettings();
    }

    final entry = await _dao!.getPharmacySettings();

    if (entry != null) {
      _cachedSettings = {
        'id': entry.id,
        'name_ar': entry.nameAr,
        'name_en': entry.nameEn,
        'license_number': entry.licenseNumber,
        'phone': entry.phone,
        'mobile': entry.mobile,
        'email': entry.email,
        'website': entry.website,
        'address': entry.address,
        'city': entry.city,
        'tax_number': entry.taxNumber,
        'commercial_registration': entry.commercialRegistration,
        'logo_path': entry.logoPath,
        'created_at': entry.createdAt.toIso8601String(),
        'updated_at': entry.updatedAt.toIso8601String(),
      };
      return _cachedSettings!;
    }

    return _getDefaultSettings();
  }

  Map<String, dynamic> _getDefaultSettings() {
    return {
      'name_ar': 'صيدلية فارماكليك',
      'name_en': 'LaRaPill Pharmacy',
      'license_number': '',
      'phone': '',
      'mobile': '',
      'email': '',
      'website': '',
      'address': '',
      'city': '',
      'tax_number': '',
      'commercial_registration': '',
    };
  }

  // الحصول على الاسم بالعربية
  Future<String> getPharmacyNameAr() async {
    final settings = await getPharmacySettings();
    return settings['name_ar'] ?? 'صيدلية فارماكليك';
  }

  // الحصول على الاسم بالإنجليزية
  Future<String> getPharmacyNameEn() async {
    final settings = await getPharmacySettings();
    return settings['name_en'] ?? 'LaRaPill Pharmacy';
  }

  // مسح الكاش عند تحديث الإعدادات
  void clearCache() {
    _cachedSettings = null;
  }
}
