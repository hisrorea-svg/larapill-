/// نموذج موحد لإعدادات التقارير والطباعة
class ReportConfig {
  // إعدادات الشكل
  final bool includeLogo;
  final bool includeCharts;
  final bool coloredReports;
  final String theme;

  // إعدادات الطباعة (اعتماداً على النظام)
  final String paperSize;
  final bool autoSave;
  final Set<String> exportFormats;

  const ReportConfig({
    this.includeLogo = true,
    this.includeCharts = true,
    this.coloredReports = false,
    this.theme = 'Professional',
    this.paperSize = 'A4',
    this.autoSave = true,
    this.exportFormats = const {'PDF', 'Excel'},
  });

  ReportConfig copyWith({
    bool? includeLogo,
    bool? includeCharts,
    bool? coloredReports,
    String? theme,
    String? paperSize,
    bool? autoSave,
    Set<String>? exportFormats,
  }) {
    return ReportConfig(
      includeLogo: includeLogo ?? this.includeLogo,
      includeCharts: includeCharts ?? this.includeCharts,
      coloredReports: coloredReports ?? this.coloredReports,
      theme: theme ?? this.theme,
      paperSize: paperSize ?? this.paperSize,
      autoSave: autoSave ?? this.autoSave,
      exportFormats: exportFormats ?? this.exportFormats,
    );
  }

  Map<String, dynamic> toJson() => {
        'includeLogo': includeLogo,
        'includeCharts': includeCharts,
        'coloredReports': coloredReports,
        'theme': theme,
        'paperSize': paperSize,
        'autoSave': autoSave,
        'exportFormats': exportFormats.toList(),
      };

  factory ReportConfig.fromJson(Map<String, dynamic> json) => ReportConfig(
        includeLogo: json['includeLogo'] ?? true,
        includeCharts: json['includeCharts'] ?? true,
        coloredReports: json['coloredReports'] ?? false,
        theme: json['theme'] ?? 'Professional',
        paperSize: json['paperSize'] ?? 'A4',
        autoSave: json['autoSave'] ?? true,
        exportFormats:
            Set<String>.from(json['exportFormats'] ?? ['PDF', 'Excel']),
      );
}
