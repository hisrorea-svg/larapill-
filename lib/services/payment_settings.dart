import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

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
      final prefs = await SharedPreferences.getInstance();
      final key = _getPaymentKey(method);
      await prefs.setBool(key, enabled);

      developer.log('✅ تم حفظ طريقة الدفع: $method = $enabled',
          name: 'PaymentSettings');
    } catch (e) {
      developer.log('❌ خطأ في حفظ طريقة الدفع: $e', name: 'PaymentSettings');
    }
  }

  // 📖 قراءة طريقة دفع
  static Future<bool> isPaymentEnabled(String method) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getPaymentKey(method);

      // القيم الافتراضية
      switch (method) {
        case 'نقداً':
        case 'بطاقة ائتمانية':
        case 'دفع آجل':
          return prefs.getBool(key) ?? true; // مفعل افتراضياً
        case 'حوالة بنكية':
          return prefs.getBool(key) ?? false; // معطل افتراضياً
        default:
          return prefs.getBool(key) ?? true;
      }
    } catch (e) {
      developer.log('❌ خطأ في قراءة طريقة الدفع: $e', name: 'PaymentSettings');
      return true;
    }
  }

  // 📋 جميع طرق الدفع المفعلة
  static Future<List<String>> getEnabledPaymentMethods() async {
    final methods = <String>[];

    if (await isPaymentEnabled('نقداً')) methods.add('نقداً');
    if (await isPaymentEnabled('بطاقة ائتمانية')) methods.add('بطاقة ائتمانية');
    if (await isPaymentEnabled('حوالة بنكية')) methods.add('حوالة بنكية');
    if (await isPaymentEnabled('دفع آجل')) methods.add('دفع آجل');

    return methods;
  }

  // 🎛️ حفظ إعدادات الواجهة
  static Future<void> setPrintAuto(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_printAuto, enabled);
  }

  static Future<void> setSoundEffects(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEffects, enabled);
  }

  static Future<void> setNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifications, enabled);
  }

  static Future<void> setDarkMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkMode, enabled);
  }

  static Future<void> setLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_language, language);
  }

  // 📖 قراءة إعدادات الواجهة
  static Future<bool> getPrintAuto() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_printAuto) ?? false;
  }

  static Future<bool> getSoundEffects() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundEffects) ?? true;
  }

  static Future<bool> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notifications) ?? true;
  }

  static Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkMode) ?? false;
  }

  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_language) ?? 'العربية';
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
  static Future<Map<String, dynamic>> getAllSettings() async {
    return {
      // طرق الدفع
      'payment_cash': await isPaymentEnabled('نقداً'),
      'payment_card': await isPaymentEnabled('بطاقة ائتمانية'),
      'payment_bank': await isPaymentEnabled('حوالة بنكية'),
      'payment_credit': await isPaymentEnabled('دفع آجل'),

      // إعدادات الواجهة
      'print_auto': await getPrintAuto(),
      'sound_effects': await getSoundEffects(),
      'notifications': await getNotifications(),
      'dark_mode': await getDarkMode(),
      'language': await getLanguage(),
    };
  }

  // 🗑️ مسح جميع الإعدادات (للاختبار)
  static Future<void> clearAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_paymentCash),
      prefs.remove(_paymentCard),
      prefs.remove(_paymentBank),
      prefs.remove(_paymentCredit),
      prefs.remove(_printAuto),
      prefs.remove(_soundEffects),
      prefs.remove(_notifications),
      prefs.remove(_darkMode),
      prefs.remove(_language),
    ]);
    developer.log('🗑️ تم مسح جميع إعدادات SharedPreferences',
        name: 'PaymentSettings');
  }
}
