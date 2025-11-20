import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';

class NotificationSettingsDialog extends StatefulWidget {
  const NotificationSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const NotificationSettingsDialog(),
    );
  }

  @override
  State<NotificationSettingsDialog> createState() =>
      _NotificationSettingsDialogState();
}

class _NotificationSettingsDialogState
    extends State<NotificationSettingsDialog> {
  bool _expiryAlerts = true;
  bool _lowStockAlerts = true;
  bool _salesNotifications = true;
  bool _systemNotifications = true;
  bool _soundEnabled = true;
  int _expiryDays = 30;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _expiryAlerts = prefs.getBool('expiry_alerts') ?? true;
      _lowStockAlerts = prefs.getBool('low_stock_alerts') ?? true;
      _salesNotifications = prefs.getBool('sales_notifications') ?? true;
      _systemNotifications = prefs.getBool('system_notifications') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _expiryDays = prefs.getInt('expiry_days') ?? 30;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('expiry_alerts', _expiryAlerts);
    await prefs.setBool('low_stock_alerts', _lowStockAlerts);
    await prefs.setBool('sales_notifications', _salesNotifications);
    await prefs.setBool('system_notifications', _systemNotifications);
    await prefs.setBool('sound_enabled', _soundEnabled);
    await prefs.setInt('expiry_days', _expiryDays);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ الإعدادات', style: GoogleFonts.tajawal()),
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
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.notifications, color: Colors.orange),
          ),
          const SizedBox(width: 12),
          Text('إعدادات الإشعارات', style: GoogleFonts.tajawal(fontSize: 18)),
        ],
      ),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildNotificationSetting(
                      title: 'تنبيهات انتهاء الصلاحية',
                      subtitle: 'إشعار عند قرب انتهاء صلاحية المنتجات',
                      value: _expiryAlerts,
                      onChanged: (value) =>
                          setState(() => _expiryAlerts = value),
                      icon: Icons.calendar_today,
                      color: AppColors.warning,
                    ),
                    if (_expiryAlerts) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(right: 48),
                        child: Row(
                          children: [
                            Text('التنبيه قبل:',
                                style: GoogleFonts.tajawal(fontSize: 14)),
                            const SizedBox(width: 16),
                            DropdownButton<int>(
                              value: _expiryDays,
                              items: [3, 7, 14, 30, 60, 90]
                                  .map((days) => DropdownMenuItem(
                                        value: days,
                                        child: Text('$days يوم',
                                            style: GoogleFonts.tajawal()),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _expiryDays = value);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Divider(height: 24),
                    _buildNotificationSetting(
                      title: 'تنبيهات نقص المخزون',
                      subtitle: 'إشعار عند نقص كمية المنتجات',
                      value: _lowStockAlerts,
                      onChanged: (value) =>
                          setState(() => _lowStockAlerts = value),
                      icon: Icons.inventory_2_outlined,
                      color: AppColors.error,
                    ),
                    const Divider(height: 24),
                    _buildNotificationSetting(
                      title: 'إشعارات المبيعات',
                      subtitle: 'تنبيه عند إتمام العمليات البيعية',
                      value: _salesNotifications,
                      onChanged: (value) =>
                          setState(() => _salesNotifications = value),
                      icon: Icons.shopping_cart,
                      color: AppColors.success,
                    ),
                    const Divider(height: 24),
                    _buildNotificationSetting(
                      title: 'إشعارات النظام',
                      subtitle: 'تنبيهات النسخ الاحتياطي والتحديثات',
                      value: _systemNotifications,
                      onChanged: (value) =>
                          setState(() => _systemNotifications = value),
                      icon: Icons.system_update,
                      color: AppColors.info,
                    ),
                    const Divider(height: 24),
                    _buildNotificationSetting(
                      title: 'تفعيل الصوت',
                      subtitle: 'صوت تنبيه عند الإشعارات',
                      value: _soundEnabled,
                      onChanged: (value) =>
                          setState(() => _soundEnabled = value),
                      icon: Icons.volume_up,
                      color: AppColors.secondary,
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

  Widget _buildNotificationSetting({
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
}
