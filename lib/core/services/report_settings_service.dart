import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../models/report_settings.dart';
import '../database/drift/daos/settings_drift_dao.dart';

/// Service موحد لإدارة جميع إعدادات التقارير
class ReportSettingsService extends StateNotifier<ReportSettings> {
  static const String _settingsKey = 'report_settings';
  final SettingsDriftDao _dao;

  ReportSettingsService(this._dao) : super(const ReportSettings()) {
    _loadSettings();
  }

  /// تحميل الإعدادات من قاعدة البيانات
  Future<void> _loadSettings() async {
    try {
      final settingsValue = await _dao.getSettingValue(_settingsKey);

      if (settingsValue != null) {
        final settings = ReportSettings.fromJson(json.decode(settingsValue));
        state = settings;
      }
    } catch (e) {
      // استخدام الإعدادات الافتراضية في حالة الخطأ
    }
  }

  /// حفظ الإعدادات
  Future<void> saveSettings(ReportSettings settings) async {
    try {
      await _dao.saveSetting(
        key: _settingsKey,
        value: json.encode(settings.toJson()),
        category: 'reports',
      );

      // حفظ وقت التحديث
      await _saveUpdateTime();

      state = settings;
    } catch (e) {
      throw Exception('فشل في حفظ إعدادات التقارير: $e');
    }
  }

  /// تحديث إعداد واحد
  Future<void> updateSetting<T>(String key, T value) async {
    final newSettings = switch (key) {
      'includeLogo' => state.copyWith(includeLogo: value as bool),
      'includeCharts' => state.copyWith(includeCharts: value as bool),
      'coloredReports' => state.copyWith(coloredReports: value as bool),
      'reportTheme' => state.copyWith(reportTheme: value as String),
      'paperSize' => state.copyWith(paperSize: value as String),
      'autoSave' => state.copyWith(autoSave: value as bool),
      _ => state,
    };

    await saveSettings(newSettings);
  }

  /// إعادة تعيين للإعدادات الافتراضية
  Future<void> resetToDefaults() async {
    await saveSettings(const ReportSettings());
  }

  /// الحصول على الطابعات المتاحة (يعتمد على النظام)
  Future<List<String>> getAvailablePrinters() async {
    try {
      // هنا يمكن ربطها مع API النظام للطابعات
      return [
        'طابعة النظام الافتراضية',
        'Microsoft Print to PDF',
        'HP LaserJet (إن وجدت)',
        'Canon PIXMA (إن وجدت)',
      ];
    } catch (e) {
      return ['طابعة النظام الافتراضية'];
    }
  }

  /// الحصول على مجلدات الحفظ المقترحة
  Future<List<String>> getSuggestedPaths() async {
    try {
      return [
        'المستندات/تقارير الصيدلية',
        'سطح المكتب/التقارير',
        'مجلد مخصص...',
      ];
    } catch (e) {
      return ['المستندات/تقارير الصيدلية'];
    }
  }

  /// الحصول على آخر تحديث للإعدادات
  Future<String?> getLastUpdateTime() async {
    try {
      return await _dao.getSettingValue('${_settingsKey}_updated');
    } catch (e) {
      return null;
    }
  }

  /// حفظ وقت آخر تحديث
  Future<void> _saveUpdateTime() async {
    try {
      await _dao.saveSetting(
        key: '${_settingsKey}_updated',
        value: DateTime.now().toIso8601String(),
        category: 'reports',
      );
    } catch (e) {
      // تجاهل الخطأ
    }
  }

  /// الحصول على إحصائيات الإعدادات
  Map<String, dynamic> getSettingsStats() {
    return {
      'includeLogo': state.includeLogo,
      'includeCharts': state.includeCharts,
      'coloredReports': state.coloredReports,
      'reportTheme': state.reportTheme,
      'paperSize': state.paperSize,
      'autoSave': state.autoSave,
      'lastUpdate': DateTime.now().toIso8601String(),
    };
  }

  /// إعادة تحميل الإعدادات من قاعدة البيانات
  Future<void> refreshSettings() async {
    await _loadSettings();
  }

  /// التحقق من صحة الإعدادات
  bool validateSettings(ReportSettings settings) {
    // التحقق من القيم المطلوبة
    if (settings.reportTheme.isEmpty || settings.paperSize.isEmpty) {
      return false;
    }

    // التحقق من القيم المسموحة
    const allowedThemes = ['Professional', 'Modern', 'Classic', 'Minimal'];
    const allowedPaperSizes = ['A4', 'A5', 'Letter', 'Legal'];

    if (!allowedThemes.contains(settings.reportTheme) ||
        !allowedPaperSizes.contains(settings.paperSize)) {
      return false;
    }

    return true;
  }
}

/// Provider للوصول للخدمة - يحتاج SettingsDriftDao من DI
final reportSettingsProvider =
    StateNotifierProvider<ReportSettingsService, ReportSettings>((ref) {
  // This will be overridden in the main app with actual DAO
  throw UnimplementedError('reportSettingsProvider must be overridden');
});
