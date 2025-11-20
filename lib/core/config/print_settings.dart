import 'package:shared_preferences/shared_preferences.dart';

/// ⚙️ إعدادات الطباعة
class PrintSettings {
  static const String _keyAutoPrint = 'auto_print_enabled';
  static const String _keyPaperSize = 'paper_size';
  static const String _keyShowPreview = 'show_print_preview';
  static const String _keyDefaultPrinter = 'default_printer_name';

  /// هل الطباعة التلقائية مفعلة؟
  static Future<bool> isAutoPrintEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoPrint) ?? false;
  }

  /// تفعيل/تعطيل الطباعة التلقائية
  static Future<void> setAutoPrint(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoPrint, enabled);
  }

  /// الحصول على حجم الورق
  static Future<PaperSize> getPaperSize() async {
    final prefs = await SharedPreferences.getInstance();
    final sizeStr = prefs.getString(_keyPaperSize) ?? 'roll80';
    return PaperSize.values.firstWhere(
      (e) => e.name == sizeStr,
      orElse: () => PaperSize.roll80,
    );
  }

  /// تعيين حجم الورق
  static Future<void> setPaperSize(PaperSize size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPaperSize, size.name);
  }

  /// هل يتم عرض المعاينة قبل الطباعة؟
  static Future<bool> shouldShowPreview() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowPreview) ?? true;
  }

  /// تفعيل/تعطيل المعاينة
  static Future<void> setShowPreview(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowPreview, show);
  }

  /// الحصول على اسم الطابعة الافتراضية
  static Future<String?> getDefaultPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDefaultPrinter);
  }

  /// تعيين الطابعة الافتراضية
  static Future<void> setDefaultPrinter(String? printerName) async {
    final prefs = await SharedPreferences.getInstance();
    if (printerName != null) {
      await prefs.setString(_keyDefaultPrinter, printerName);
    } else {
      await prefs.remove(_keyDefaultPrinter);
    }
  }

  /// إعادة تعيين جميع الإعدادات للقيم الافتراضية
  static Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAutoPrint);
    await prefs.remove(_keyPaperSize);
    await prefs.remove(_keyShowPreview);
    await prefs.remove(_keyDefaultPrinter);
  }
}

/// أحجام الورق المدعومة
enum PaperSize {
  roll80('80mm حراري', '80mm Thermal'),
  a4('A4 عادي', 'A4 Standard');

  final String arabicName;
  final String englishName;

  const PaperSize(this.arabicName, this.englishName);
}
