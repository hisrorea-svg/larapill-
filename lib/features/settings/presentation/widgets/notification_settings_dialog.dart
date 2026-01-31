import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/notification_settings_notifier.dart';
import '../utils/error_handler.dart';

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
          const Text('إعدادات الإشعارات',
              style: TextStyle(fontFamily: 'Tajawal', fontSize: 18)),
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
                        const Text('التنبيه قبل:',
                            style:
                                TextStyle(fontFamily: 'Tajawal', fontSize: 14)),
                        const SizedBox(width: 16),
                        DropdownButton<int>(
                          value: settings.expiryDays,
                          items: [3, 7, 14, 30, 60, 90]
                              .map((days) => DropdownMenuItem(
                                    value: days,
                                    child: Text('$days يوم',
                                        style: const TextStyle(
                                          fontFamily: 'Tajawal',
                                        )),
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
                  onChanged: (value) =>
                      notifier.updateSalesNotifications(value),
                  icon: Icons.shopping_cart,
                  color: AppColors.success,
                ),
                const Divider(height: 24),
                _buildNotificationSetting(
                  title: 'إشعارات النظام',
                  subtitle: 'تنبيهات النسخ الاحتياطي والتحديثات',
                  value: settings.systemNotifications,
                  onChanged: (value) =>
                      notifier.updateSystemNotifications(value),
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
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                SettingsErrorHandler.getErrorMessage(error),
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref
                      .read(notificationSettingsNotifierProvider.notifier)
                      .refresh();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                    )),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء',
              style: TextStyle(
                fontFamily: 'Tajawal',
              )),
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
                      const SnackBar(
                        content: Text(
                          'تم حفظ الإعدادات',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                          ),
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
              : const Text('حفظ',
                  style: TextStyle(fontFamily: 'Tajawal', color: Colors.white)),
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
                  style: const TextStyle(
                      fontFamily: 'Tajawal', fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      color: Colors.grey[600])),
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
