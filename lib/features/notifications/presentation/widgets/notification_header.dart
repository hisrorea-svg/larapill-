import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_spacing.dart';
import '../providers/notification_providers.dart';

/// رأس صفحة الإشعارات
class NotificationHeader extends ConsumerWidget {
  const NotificationHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationControllerProvider);
    final unreadCount = state.unreadCount;

    return Container(
      padding: EdgeInsets.all(context.spacing20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // أيقونة الإشعارات
          Container(
            padding: EdgeInsets.all(context.spacing10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(context.radius12),
            ),
            child: Icon(
              Icons.notifications,
              color: AppColors.primary,
              size: context.iconSize28,
            ),
          ),
          SizedBox(width: context.spacing16),

          // معلومات الإشعارات
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الإشعارات',
                  style: GoogleFonts.tajawal(
                    fontSize: context.fontSize24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: context.spacing4),
                Text(
                  unreadCount > 0
                      ? '$unreadCount إشعار غير مقروء'
                      : 'جميع الإشعارات مقروءة',
                  style: GoogleFonts.tajawal(
                    fontSize: context.fontSize14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // أزرار الإجراءات
          if (unreadCount > 0) ...[
            TextButton.icon(
              onPressed: () {
                ref
                    .read(notificationControllerProvider.notifier)
                    .markAllAsRead();
              },
              icon: Icon(Icons.done_all, size: context.iconSize18),
              label: Text(
                'تعليم الكل كمقروء',
                style: GoogleFonts.tajawal(fontSize: context.fontSize13),
              ),
            ),
            SizedBox(width: context.spacing8),
          ],

          TextButton.icon(
            onPressed: () {
              ref
                  .read(notificationControllerProvider.notifier)
                  .clearReadNotifications();
            },
            icon: Icon(Icons.delete_sweep, size: context.iconSize18),
            label: Text(
              'حذف المقروءة',
              style: GoogleFonts.tajawal(fontSize: context.fontSize13),
            ),
          ),
        ],
      ),
    );
  }
}
