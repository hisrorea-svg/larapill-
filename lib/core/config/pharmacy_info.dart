import 'dart:developer' as developer;
import '../../database/database_helper.dart';

class PharmacyInfo {
  static String name = 'صيدلية LaRaPill';
  static String englishName = 'LaRaPill Pharmacy';
  static String address = '';
  static String phone = '';
  static String email = '';
  static String license = '';
  static String owner = '';

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
  static Future<void> loadFromDatabase() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      // قراءة من جدول pharmacy_settings
      final result = await db.query('pharmacy_settings', limit: 1);

      if (result.isNotEmpty) {
        final data = result.first;
        name = (data['name_ar'] as String?) ?? name;
        englishName = (data['name_en'] as String?) ?? englishName;
        address = (data['address'] as String?) ?? address;
        phone = (data['phone'] as String?) ?? phone;
        email = (data['email'] as String?) ?? email;
        license = (data['license_number'] as String?) ?? license;
        owner = (data['commercial_registration'] as String?) ?? owner;

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
