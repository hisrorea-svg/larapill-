import '../storage/hive_storage.dart';

/// ⚙️ إعدادات الطباعة
class PrintSettings {
  static const String _keyAutoPrint = 'auto_print_enabled';
  static const String _keyPaperSize = 'paper_size';
  static const String _keyShowPreview = 'show_print_preview';
  static const String _keyDefaultPrinter = 'default_printer_name';

  /// هل الطباعة التلقائية مفعلة؟
  static bool isAutoPrintEnabled() {
    return HiveStorage.getBool(_keyAutoPrint, defaultValue: false);
  }

  /// تفعيل/تعطيل الطباعة التلقائية
  static Future<void> setAutoPrint(bool enabled) async {
    await HiveStorage.setBool(_keyAutoPrint, enabled);
  }

  /// الحصول على حجم الورق
  static PaperSize getPaperSize() {
    final sizeStr = HiveStorage.getString(_keyPaperSize) ?? 'roll80';
    return PaperSize.values.firstWhere(
      (e) => e.name == sizeStr,
      orElse: () => PaperSize.roll80,
    );
  }

  /// تعيين حجم الورق
  static Future<void> setPaperSize(PaperSize size) async {
    await HiveStorage.setString(_keyPaperSize, size.name);
  }

  /// هل يتم عرض المعاينة قبل الطباعة؟
  static bool shouldShowPreview() {
    return HiveStorage.getBool(_keyShowPreview, defaultValue: true);
  }

  /// تفعيل/تعطيل المعاينة
  static Future<void> setShowPreview(bool show) async {
    await HiveStorage.setBool(_keyShowPreview, show);
  }

  /// الحصول على اسم الطابعة الافتراضية
  static String? getDefaultPrinter() {
    return HiveStorage.getString(_keyDefaultPrinter);
  }

  /// تعيين الطابعة الافتراضية
  static Future<void> setDefaultPrinter(String? printerName) async {
    if (printerName != null) {
      await HiveStorage.setString(_keyDefaultPrinter, printerName);
    } else {
      await HiveStorage.remove(_keyDefaultPrinter);
    }
  }

  /// إعادة تعيين جميع الإعدادات للقيم الافتراضية
  static Future<void> resetToDefaults() async {
    await HiveStorage.remove(_keyAutoPrint);
    await HiveStorage.remove(_keyPaperSize);
    await HiveStorage.remove(_keyShowPreview);
    await HiveStorage.remove(_keyDefaultPrinter);
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
