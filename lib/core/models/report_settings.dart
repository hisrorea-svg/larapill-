/// نموذج إعدادات التقارير
class ReportSettings {
  final bool includeLogo;
  final bool includeCharts;
  final bool coloredReports;
  final String reportTheme;
  final String paperSize;
  final bool autoSave;

  const ReportSettings({
    this.includeLogo = true,
    this.includeCharts = true,
    this.coloredReports = false,
    this.reportTheme = 'Professional',
    this.paperSize = 'A4',
    this.autoSave = true,
  });

  ReportSettings copyWith({
    bool? includeLogo,
    bool? includeCharts,
    bool? coloredReports,
    String? reportTheme,
    String? paperSize,
    bool? autoSave,
  }) {
    return ReportSettings(
      includeLogo: includeLogo ?? this.includeLogo,
      includeCharts: includeCharts ?? this.includeCharts,
      coloredReports: coloredReports ?? this.coloredReports,
      reportTheme: reportTheme ?? this.reportTheme,
      paperSize: paperSize ?? this.paperSize,
      autoSave: autoSave ?? this.autoSave,
    );
  }

  Map<String, dynamic> toJson() => {
        'includeLogo': includeLogo,
        'includeCharts': includeCharts,
        'coloredReports': coloredReports,
        'reportTheme': reportTheme,
        'paperSize': paperSize,
        'autoSave': autoSave,
      };

  factory ReportSettings.fromJson(Map<String, dynamic> json) => ReportSettings(
        includeLogo: json['includeLogo'] ?? true,
        includeCharts: json['includeCharts'] ?? true,
        coloredReports: json['coloredReports'] ?? false,
        reportTheme: json['reportTheme'] ?? 'Professional',
        paperSize: json['paperSize'] ?? 'A4',
        autoSave: json['autoSave'] ?? true,
      );
}
