import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/report_settings.dart';
import '../../../providers/report_settings_provider.dart';

class ReportsSettingsDialog extends ConsumerStatefulWidget {
  const ReportsSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const ReportsSettingsDialog(),
    );
  }

  @override
  ConsumerState<ReportsSettingsDialog> createState() =>
      _ReportsSettingsDialogState();
}

class _ReportsSettingsDialogState extends ConsumerState<ReportsSettingsDialog> {
  late bool _includeLogo;
  late bool _includeCharts;
  late bool _coloredReports;
  late String _reportTheme;
  late String _paperSize;
  late bool _autoSave;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(reportSettingsProvider);
    _includeLogo = settings.includeLogo;
    _includeCharts = settings.includeCharts;
    _coloredReports = settings.coloredReports;
    _reportTheme = settings.reportTheme;
    _paperSize = settings.paperSize;
    _autoSave = settings.autoSave;
  }

  Future<void> _saveSettings() async {
    final newSettings = ReportSettings(
      includeLogo: _includeLogo,
      includeCharts: _includeCharts,
      coloredReports: _coloredReports,
      reportTheme: _reportTheme,
      paperSize: _paperSize,
      autoSave: _autoSave,
    );

    ref.read(reportSettingsProvider.notifier).updateSettings(newSettings);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('تم حفظ إعدادات التقارير', style: GoogleFonts.tajawal()),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.print, color: AppColors.info),
          ),
          const SizedBox(width: 12),
          Text('إعدادات التقارير', style: GoogleFonts.tajawal(fontSize: 18)),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('التنسيق العام',
                  style: GoogleFonts.tajawal(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              _buildSwitchSetting(
                title: 'تضمين الشعار',
                subtitle: 'إظهار شعار الصيدلية في التقارير',
                value: _includeLogo,
                onChanged: (value) => setState(() => _includeLogo = value),
                icon: Icons.image,
                color: AppColors.primary,
              ),
              const Divider(height: 24),
              _buildSwitchSetting(
                title: 'تضمين الرسوم البيانية',
                subtitle: 'إظهار المخططات والرسوم التوضيحية',
                value: _includeCharts,
                onChanged: (value) => setState(() => _includeCharts = value),
                icon: Icons.bar_chart,
                color: AppColors.success,
              ),
              const Divider(height: 24),
              _buildSwitchSetting(
                title: 'تقارير ملونة',
                subtitle: 'استخدام الألوان في التقارير',
                value: _coloredReports,
                onChanged: (value) => setState(() => _coloredReports = value),
                icon: Icons.palette,
                color: Colors.orange,
              ),
              const Divider(height: 24),
              Text('الإعدادات المتقدمة',
                  style: GoogleFonts.tajawal(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              _buildDropdownSetting(
                title: 'ثيم التقرير',
                value: _reportTheme,
                items: const ['Professional', 'Modern', 'Classic', 'Minimal'],
                onChanged: (value) => setState(() => _reportTheme = value!),
                icon: Icons.style,
              ),
              const SizedBox(height: 12),
              _buildDropdownSetting(
                title: 'حجم الورق',
                value: _paperSize,
                items: const ['A4', 'Letter', 'A5', 'Legal'],
                onChanged: (value) => setState(() => _paperSize = value!),
                icon: Icons.aspect_ratio,
              ),
              const Divider(height: 24),
              _buildSwitchSetting(
                title: 'الحفظ التلقائي',
                subtitle: 'حفظ التقارير تلقائياً عند إنشائها',
                value: _autoSave,
                onChanged: (value) => setState(() => _autoSave = value),
                icon: Icons.save,
                color: AppColors.warning,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('إلغاء', style: GoogleFonts.tajawal()),
        ),
        ElevatedButton(
          onPressed: _saveSettings,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: Text('حفظ', style: GoogleFonts.tajawal(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildSwitchSetting({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.tajawal(fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: GoogleFonts.tajawal(
                      fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: color,
        ),
      ],
    );
  }

  Widget _buildDropdownSetting({
    required String title,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.secondary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(title, style: GoogleFonts.tajawal(fontWeight: FontWeight.w600)),
        const Spacer(),
        DropdownButton<String>(
          value: value,
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item, style: GoogleFonts.tajawal()),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
