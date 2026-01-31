import 'package:hive_flutter/hive_flutter.dart';
import 'dart:developer' as developer;

/// 🗄️ HiveStorage - خدمة التخزين المحلي باستخدام Hive
/// بديل احترافي لـ SharedPreferences مع أداء أفضل
class HiveStorage {
  static late Box _settingsBox;
  static late Box _securityBox;
  static late Box _cacheBox;
  static bool _initialized = false;

  /// تهيئة Hive - يجب استدعاؤها مرة واحدة في AppBootstrap
  static Future<void> init() async {
    if (_initialized) return;

    try {
      await Hive.initFlutter();

      // فتح الصناديق المختلفة
      _settingsBox = await Hive.openBox('settings');
      _securityBox = await Hive.openBox('security');
      _cacheBox = await Hive.openBox('cache');

      _initialized = true;
      developer.log('✅ HiveStorage تم تهيئتها بنجاح', name: 'HiveStorage');
    } catch (e, stack) {
      developer.log('❌ فشل تهيئة HiveStorage: $e',
          name: 'HiveStorage', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// التأكد من التهيئة
  static void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
          'HiveStorage لم يتم تهيئتها! استدعِ HiveStorage.init() أولاً');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 📦 Settings Box - الإعدادات العامة
  // ════════════════════════════════════════════════════════════════════════════

  /// قراءة String
  static String? getString(String key) {
    _ensureInitialized();
    return _settingsBox.get(key);
  }

  /// كتابة String
  static Future<void> setString(String key, String value) async {
    _ensureInitialized();
    await _settingsBox.put(key, value);
  }

  /// قراءة Bool
  static bool getBool(String key, {bool defaultValue = false}) {
    _ensureInitialized();
    return _settingsBox.get(key, defaultValue: defaultValue) ?? defaultValue;
  }

  /// كتابة Bool
  static Future<void> setBool(String key, bool value) async {
    _ensureInitialized();
    await _settingsBox.put(key, value);
  }

  /// قراءة Int
  static int getInt(String key, {int defaultValue = 0}) {
    _ensureInitialized();
    return _settingsBox.get(key, defaultValue: defaultValue) ?? defaultValue;
  }

  /// كتابة Int
  static Future<void> setInt(String key, int value) async {
    _ensureInitialized();
    await _settingsBox.put(key, value);
  }

  /// قراءة Double
  static double getDouble(String key, {double defaultValue = 0.0}) {
    _ensureInitialized();
    return _settingsBox.get(key, defaultValue: defaultValue) ?? defaultValue;
  }

  /// كتابة Double
  static Future<void> setDouble(String key, double value) async {
    _ensureInitialized();
    await _settingsBox.put(key, value);
  }

  /// قراءة List<String>
  static List<String>? getStringList(String key) {
    _ensureInitialized();
    final value = _settingsBox.get(key);
    if (value == null) return null;
    return (value as List).cast<String>();
  }

  /// كتابة List<String>
  static Future<void> setStringList(String key, List<String> value) async {
    _ensureInitialized();
    await _settingsBox.put(key, value);
  }

  /// حذف مفتاح
  static Future<void> remove(String key) async {
    _ensureInitialized();
    await _settingsBox.delete(key);
  }

  /// التحقق من وجود مفتاح
  static bool containsKey(String key) {
    _ensureInitialized();
    return _settingsBox.containsKey(key);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🔐 Security Box - بيانات الأمان (Rate Limiter, Session, etc.)
  // ════════════════════════════════════════════════════════════════════════════

  /// قراءة من Security Box
  static T? getSecure<T>(String key) {
    _ensureInitialized();
    return _securityBox.get(key);
  }

  /// كتابة في Security Box
  static Future<void> setSecure<T>(String key, T value) async {
    _ensureInitialized();
    await _securityBox.put(key, value);
  }

  /// حذف من Security Box
  static Future<void> removeSecure(String key) async {
    _ensureInitialized();
    await _securityBox.delete(key);
  }

  /// مسح Security Box بالكامل
  static Future<void> clearSecure() async {
    _ensureInitialized();
    await _securityBox.clear();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 💾 Cache Box - التخزين المؤقت
  // ════════════════════════════════════════════════════════════════════════════

  /// قراءة من Cache
  static T? getCache<T>(String key) {
    _ensureInitialized();
    return _cacheBox.get(key);
  }

  /// كتابة في Cache
  static Future<void> setCache<T>(String key, T value) async {
    _ensureInitialized();
    await _cacheBox.put(key, value);
  }

  /// مسح Cache بالكامل
  static Future<void> clearCache() async {
    _ensureInitialized();
    await _cacheBox.clear();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🧹 صيانة
  // ════════════════════════════════════════════════════════════════════════════

  /// مسح جميع البيانات
  static Future<void> clearAll() async {
    _ensureInitialized();
    await _settingsBox.clear();
    await _securityBox.clear();
    await _cacheBox.clear();
    developer.log('🧹 تم مسح جميع بيانات Hive', name: 'HiveStorage');
  }

  /// إغلاق Hive (عند إنهاء التطبيق)
  static Future<void> close() async {
    if (_initialized) {
      await Hive.close();
      _initialized = false;
    }
  }
}
