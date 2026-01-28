import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../presentation/providers/notification_settings_notifier.dart';
import '../presentation/utils/error_handler.dart';

/// Dialog لإعدادات الإشعارات
/// 
/// يستخدم Riverpod StateNotifier لإدارة الحالة
class NotificationSettingsDialog extends ConsumerWidget {
  const NotificationSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const NotificationSettingsDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(notificationSettingsNotifierProvider.notifier);
    final state = ref.watch(notificationSettingsNotifierProvider);

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
      content: state.settings.when(
        data: (settings) => SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNotificationSetting(
                  title: 'تنبيهات انتهاء الصلاحية',
                  subtitle: 'إشعار عند قرب انتهاء صلاحية المنتجات',
                  value: settings.expiryAlerts,
                  onChanged: (value) => notifier.updateExpiryAlerts(value),
                  icon: Icons.calendar_today,
                  color: AppColors.warning,
                ),
                if (settings.expiryAlerts) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(right: 48),
                    child: Row(
                      children: [
                        Text('التنبيه قبل:',
                            style: GoogleFonts.tajawal(fontSize: 14)),
                        const SizedBox(width: 16),
                        DropdownButton<int>(
                          value: settings.expiryDays,
                          items: [3, 7, 14, 30, 60, 90]
                              .map((days) => DropdownMenuItem(
                                    value: days,
                                    child: Text('$days يوم',
                                        style: GoogleFonts.tajawal()),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              notifier.updateExpiryDays(value);
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
                  value: settings.lowStockAlerts,
                  onChanged: (value) => notifier.updateLowStockAlerts(value),
                  icon: Icons.inventory_2_outlined,
                  color: AppColors.error,
                ),
                const Divider(height: 24),
                _buildNotificationSetting(
                  title: 'إشعارات المبيعات',
                  subtitle: 'تنبيه عند إتمام العمليات البيعية',
                  value: settings.salesNotifications,
                  onChanged: (value) => notifier.updateSalesNotifications(value),
                  icon: Icons.shopping_cart,
                  color: AppColors.success,
                ),
                const Divider(height: 24),
                _buildNotificationSetting(
                  title: 'إشعارات النظام',
                  subtitle: 'تنبيهات النسخ الاحتياطي والتحديثات',
                  value: settings.systemNotifications,
                  onChanged: (value) => notifier.updateSystemNotifications(value),
                  icon: Icons.system_update,
                  color: AppColors.info,
                ),
                const Divider(height: 24),
                _buildNotificationSetting(
                  title: 'تفعيل الصوت',
                  subtitle: 'صوت تنبيه عند الإشعارات',
                  value: settings.soundEnabled,
                  onChanged: (value) => notifier.updateSoundEnabled(value),
                  icon: Icons.volume_up,
                  color: AppColors.secondary,
                ),
              ],
            ),
          ),
        ),
        loading: () => const SizedBox(
          width: 500,
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stackTrace) => SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'حدث خطأ في تحميل الإعدادات',
                style: GoogleFonts.tajawal(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                SettingsErrorHandler.getErrorMessage(error),
                style: GoogleFonts.tajawal(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(notificationSettingsNotifierProvider.notifier).refresh();
                },
                icon: const Icon(Icons.refresh),
                label: Text('إعادة المحاولة', style: GoogleFonts.tajawal()),
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
          onPressed: state.isSaving
              ? null
              : () async {
                  await notifier.saveSettings();
                  final currentState =
                      ref.read(notificationSettingsNotifierProvider);
                  
                  if (currentState.hasError) {
                    // الخطأ معروض بالفعل في state.settings
                    return;
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم حفظ الإعدادات',
                          style: GoogleFonts.tajawal(),
                        ),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: state.isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text('حفظ', style: GoogleFonts.tajawal(color: Colors.white)),
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
