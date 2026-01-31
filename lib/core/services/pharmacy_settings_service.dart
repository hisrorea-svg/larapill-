import '../../database/database_helper.dart';

class PharmacySettingsService {
  static final PharmacySettingsService instance = PharmacySettingsService._();
  PharmacySettingsService._();

  Map<String, dynamic>? _cachedSettings;

  // جلب إعدادات الصيدلية
  Future<Map<String, dynamic>> getPharmacySettings() async {
    if (_cachedSettings != null) {
      return _cachedSettings!;
    }

    final db = await DatabaseHelper().database;
    final result = await db.query('pharmacy_settings', limit: 1);

    if (result.isNotEmpty) {
      _cachedSettings = result.first;
      return _cachedSettings!;
    }

    // القيم الافتراضية إذا لم تكن موجودة
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
