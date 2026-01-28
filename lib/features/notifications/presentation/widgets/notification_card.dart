import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_spacing.dart';
import '../../../../core/navigation/notification_router.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/notification_type.dart';
import '../providers/notification_providers.dart';

/// بطاقة إشعار واحدة
class NotificationCard extends ConsumerWidget {
  final NotificationEntity notification;

  const NotificationCard({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priorityColor =
        NotificationRouter.getColorForPriority(notification.priority);
    final typeIcon = NotificationRouter.getIconForType(notification.type);

    return Container(
      margin: EdgeInsets.only(bottom: context.spacing12),
      decoration: BoxDecoration(
        color: notification.isRead
            ? AppColors.surface
            : AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(context.radius12),
        border: Border.all(
          color: notification.isRead
              ? AppColors.border
              : AppColors.primary.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _onNotificationTap(context, ref),
        borderRadius: BorderRadius.circular(context.radius12),
        child: Padding(
          padding: EdgeInsets.all(context.spacing16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الأيقونة
              Container(
                padding: EdgeInsets.all(context.spacing10),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(context.radius10),
                ),
                child: Icon(
                  typeIcon,
                  color: priorityColor,
                  size: context.iconSize22,
                ),
              ),
              SizedBox(width: context.spacing16),

              // المحتوى
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // العنوان
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.tajawal(
                              fontSize: context.fontSize15,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: context.spacing6),

                    // الوصف
                    Text(
                      notification.body,
                      style: GoogleFonts.tajawal(
                        fontSize: context.fontSize13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: context.spacing8),

                    // الوقت والنوع
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: context.fontSize14,
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                        ),
                        SizedBox(width: context.spacing4),
                        Text(
                          _formatTime(notification.createdAt),
                          style: GoogleFonts.tajawal(
                            fontSize: context.fontSize12,
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                        const Spacer(),

                        // شريحة النوع
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.spacing8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(context.radius6),
                          ),
                          child: Text(
                            _getTypeLabel(notification.type),
                            style: GoogleFonts.tajawal(
                              fontSize: context.fontSize11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onNotificationTap(BuildContext context, WidgetRef ref) {
    // تعليم كمقروء
    if (!notification.isRead) {
      ref
          .read(notificationControllerProvider.notifier)
          .markAsRead(notification.id);
    }
    // التنقل للصفحة المناسبة
    NotificationRouter.navigate(context, notification);
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _getTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.inventory:
        return 'المخزون';
      case NotificationType.sales:
        return 'المبيعات';
      case NotificationType.purchases:
        return 'المشتريات';
      case NotificationType.user:
        return 'المستخدمين';
      case NotificationType.reminder:
        return 'تذكير';
      case NotificationType.system:
        return 'النظام';
    }
  }
}
