import 'dart:developer' as developer;
import '../storage/hive_storage.dart';

class PaymentSettings {
  // 💳 مفاتيح طرق الدفع
  static const String _paymentCash = 'payment_cash';
  static const String _paymentCard = 'payment_card';
  static const String _paymentBank = 'payment_bank';
  static const String _paymentCredit = 'payment_credit';

  // 🎛️ مفاتيح إعدادات الواجهة
  static const String _printAuto = 'print_auto';
  static const String _soundEffects = 'sound_effects';
  static const String _notifications = 'notifications';
  static const String _darkMode = 'dark_mode';
  static const String _language = 'language';

  // ✅ حفظ طريقة دفع
  static Future<void> setPaymentMethod(String method, bool enabled) async {
    try {
      final key = _getPaymentKey(method);
      await HiveStorage.setBool(key, enabled);

      developer.log('✅ تم حفظ طريقة الدفع: $method = $enabled',
          name: 'PaymentSettings');
    } catch (e) {
      developer.log('❌ خطأ في حفظ طريقة الدفع: $e', name: 'PaymentSettings');
    }
  }

  // 📖 قراءة طريقة دفع
  static bool isPaymentEnabled(String method) {
    try {
      final key = _getPaymentKey(method);

      // القيم الافتراضية
      switch (method) {
        case 'نقداً':
        case 'بطاقة ائتمانية':
        case 'دفع آجل':
          return HiveStorage.getBool(key, defaultValue: true);
        case 'حوالة بنكية':
          return HiveStorage.getBool(key, defaultValue: false);
        default:
          return HiveStorage.getBool(key, defaultValue: true);
      }
    } catch (e) {
      developer.log('❌ خطأ في قراءة طريقة الدفع: $e', name: 'PaymentSettings');
      return true;
    }
  }

  // 📋 جميع طرق الدفع المفعلة
  static List<String> getEnabledPaymentMethods() {
    final methods = <String>[];

    if (isPaymentEnabled('نقداً')) methods.add('نقداً');
    if (isPaymentEnabled('بطاقة ائتمانية')) methods.add('بطاقة ائتمانية');
    if (isPaymentEnabled('حوالة بنكية')) methods.add('حوالة بنكية');
    if (isPaymentEnabled('دفع آجل')) methods.add('دفع آجل');

    return methods;
  }

  // 🎛️ حفظ إعدادات الواجهة
  static Future<void> setPrintAuto(bool enabled) async {
    await HiveStorage.setBool(_printAuto, enabled);
  }

  static Future<void> setSoundEffects(bool enabled) async {
    await HiveStorage.setBool(_soundEffects, enabled);
  }

  static Future<void> setNotifications(bool enabled) async {
    await HiveStorage.setBool(_notifications, enabled);
  }

  static Future<void> setDarkMode(bool enabled) async {
    await HiveStorage.setBool(_darkMode, enabled);
  }

  static Future<void> setLanguage(String language) async {
    await HiveStorage.setString(_language, language);
  }

  // 📖 قراءة إعدادات الواجهة
  static bool getPrintAuto() {
    return HiveStorage.getBool(_printAuto, defaultValue: false);
  }

  static bool getSoundEffects() {
    return HiveStorage.getBool(_soundEffects, defaultValue: true);
  }

  static bool getNotifications() {
    return HiveStorage.getBool(_notifications, defaultValue: true);
  }

  static bool getDarkMode() {
    return HiveStorage.getBool(_darkMode, defaultValue: false);
  }

  static String getLanguage() {
    return HiveStorage.getString(_language) ?? 'العربية';
  }

  // 🔧 دالة مساعدة لتحويل اسم الطريقة إلى مفتاح
  static String _getPaymentKey(String method) {
    switch (method) {
      case 'نقداً':
        return _paymentCash;
      case 'بطاقة ائتمانية':
        return _paymentCard;
      case 'حوالة بنكية':
        return _paymentBank;
      case 'دفع آجل':
        return _paymentCredit;
      default:
        return 'payment_other';
    }
  }

  // 🔄 تحميل جميع الإعدادات (للاستخدام السريع)
  static Map<String, dynamic> getAllSettings() {
    return {
      // طرق الدفع
      'payment_cash': isPaymentEnabled('نقداً'),
      'payment_card': isPaymentEnabled('بطاقة ائتمانية'),
      'payment_bank': isPaymentEnabled('حوالة بنكية'),
      'payment_credit': isPaymentEnabled('دفع آجل'),

      // إعدادات الواجهة
      'print_auto': getPrintAuto(),
      'sound_effects': getSoundEffects(),
      'notifications': getNotifications(),
      'dark_mode': getDarkMode(),
      'language': getLanguage(),
    };
  }

  // 🗑️ مسح جميع الإعدادات (للاختبار)
  static Future<void> clearAllSettings() async {
    await Future.wait([
      HiveStorage.remove(_paymentCash),
      HiveStorage.remove(_paymentCard),
      HiveStorage.remove(_paymentBank),
      HiveStorage.remove(_paymentCredit),
      HiveStorage.remove(_printAuto),
      HiveStorage.remove(_soundEffects),
      HiveStorage.remove(_notifications),
      HiveStorage.remove(_darkMode),
      HiveStorage.remove(_language),
    ]);
    developer.log('🗑️ تم مسح جميع إعدادات الدفع', name: 'PaymentSettings');
  }
}
