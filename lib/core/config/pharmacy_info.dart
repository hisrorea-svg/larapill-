import 'dart:developer' as developer;
import '../../core/database/drift/app_database.dart';

class PharmacyInfo {
  static String name = 'صيدلية LaRaPill';
  static String englishName = 'LaRaPill Pharmacy';
  static String address = '';
  static String phone = '';
  static String email = '';
  static String license = '';
  static String owner = '';

  // ✅ Reference to the global database used in loadFromDatabase
  static AppDatabase? _db;

  /// Set the database reference (called during app initialization)
  static void setDatabase(AppDatabase db) {
    _db = db;
  }

  // ✅ دالة تحديث المعلومات
  static void updateInfo({
    String? name,
    String? englishName,
    String? address,
    String? phone,
    String? email,
    String? license,
    String? owner,
  }) {
    if (name != null) PharmacyInfo.name = name;
    if (englishName != null) PharmacyInfo.englishName = englishName;
    if (address != null) PharmacyInfo.address = address;
    if (phone != null) PharmacyInfo.phone = phone;
    if (email != null) PharmacyInfo.email = email;
    if (license != null) PharmacyInfo.license = license;
    if (owner != null) PharmacyInfo.owner = owner;
  }

  // ✅ تحميل المعلومات من قاعدة البيانات عند بدء التطبيق
  /// Load pharmacy info from the Drift database
  /// Requires setDatabase() to be called first, or pass db directly
  static Future<void> loadFromDatabase([AppDatabase? db]) async {
    try {
      // Use provided db or the static _db reference
      final database = db ?? _db;
      if (database == null) {
        developer.log('⚠️ لم يتم تهيئة قاعدة البيانات بعد',
            name: 'PharmacyInfo');
        return;
      }

      // Use Drift query
      final result = await (database.select(database.pharmacySettings)
            ..limit(1))
          .getSingleOrNull();

      if (result != null) {
        name = result.nameAr;
        englishName = result.nameEn ?? englishName;
        address = result.address ?? address;
        phone = result.phone ?? phone;
        email = result.email ?? email;
        license = result.licenseNumber ?? license;
        owner = result.commercialRegistration ?? owner;

        developer.log('✅ تم تحميل معلومات الصيدلية: $name',
            name: 'PharmacyInfo');
      } else {
        developer.log('⚠️ لا توجد بيانات صيدلية محفوظة', name: 'PharmacyInfo');
      }
    } catch (e) {
      developer.log('❌ خطأ في تحميل معلومات الصيدلية: $e',
          name: 'PharmacyInfo');
    }
  }

  // ✅ دالة للحصول على معلومات كاملة
  static Map<String, String> getAllInfo() {
    return {
      'name': name,
      'englishName': englishName,
      'address': address,
      'phone': phone,
      'email': email,
      'license': license,
      'owner': owner,
    };
  }

  // ✅ دالة للتحقق من اكتمال المعلومات
  static bool isComplete() {
    return name.isNotEmpty &&
        englishName.isNotEmpty &&
        address.isNotEmpty &&
        phone.isNotEmpty;
  }
}
