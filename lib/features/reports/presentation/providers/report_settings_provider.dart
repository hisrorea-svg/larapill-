import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/models/report_settings.dart';
import 'dart:convert';

class ReportSettingsNotifier extends StateNotifier<ReportSettings> {
  ReportSettingsNotifier() : super(const ReportSettings()) {
    _loadSettings();
  }

  void _loadSettings() {
    final settingsJson = HiveStorage.getString('report_settings');
    if (settingsJson != null) {
      try {
        final map = json.decode(settingsJson) as Map<String, dynamic>;
        state = ReportSettings.fromJson(map);
      } catch (e) {
        // Use default settings if parsing fails
      }
    }
  }

  Future<void> updateSettings(ReportSettings newSettings) async {
    state = newSettings;
    await HiveStorage.setString(
        'report_settings', json.encode(newSettings.toJson()));
  }

  void toggleLogo() {
    updateSettings(state.copyWith(includeLogo: !state.includeLogo));
  }

  void toggleCharts() {
    updateSettings(state.copyWith(includeCharts: !state.includeCharts));
  }

  void toggleColoredReports() {
    updateSettings(state.copyWith(coloredReports: !state.coloredReports));
  }

  void setReportTheme(String theme) {
    updateSettings(state.copyWith(reportTheme: theme));
  }

  void setPaperSize(String size) {
    updateSettings(state.copyWith(paperSize: size));
  }

  void toggleAutoSave() {
    updateSettings(state.copyWith(autoSave: !state.autoSave));
  }
}

final reportSettingsProvider =
    StateNotifierProvider<ReportSettingsNotifier, ReportSettings>((ref) {
  return ReportSettingsNotifier();
});
