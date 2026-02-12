// lib/core/navigation/notification_router.dart
// 🔔 نظام التوجيه الذكي للإشعارات

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/notifications/domain/entities/notification_entity.dart';
import '../../features/notifications/domain/entities/notification_type.dart';
import '../../features/notifications/domain/entities/notification_priority.dart';
import '../providers/navigation_providers.dart';

/// يوجه المستخدم للصفحة المناسبة حسب نوع الإشعار
/// ✅ نسخة محدثة: تستخدم selectedIndexProvider للتنقل داخل MainLayout
class NotificationRouter {
  /// التوجيه حسب نوع الإشعار - يغير الـ selectedIndex في MainLayout
  static void navigate(
      BuildContext context, WidgetRef ref, NotificationEntity notification) {
    final int targetIndex = _getIndexForType(notification.type);

    // تغيير الصفحة المختارة في MainLayout
    ref.read(selectedIndexProvider.notifier).state = targetIndex;

    // إغلاق أي dialog أو menu مفتوح
    Navigator.of(context).popUntil((route) => route.isFirst || !route.isActive);
  }

  /// الحصول على index الصفحة حسب نوع الإشعار
  static int _getIndexForType(NotificationType type) {
    switch (type) {
      case NotificationType.inventory:
        return 2; // InventoryScreen
      case NotificationType.sales:
        return 1; // PosScreen
      case NotificationType.purchases:
        return 3; // PurchasesDashboardScreen
      case NotificationType.user:
        return 7; // SettingsScreen
      case NotificationType.reminder:
        return 0; // DashboardScreen
      case NotificationType.system:
        return 7; // SettingsScreen
    }
  }

  /// الحصول على أيقونة حسب النوع
  static IconData getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.inventory:
        return Icons.inventory_2_outlined;
      case NotificationType.sales:
        return Icons.point_of_sale;
      case NotificationType.purchases:
        return Icons.shopping_cart_outlined;
      case NotificationType.user:
        return Icons.person_outline;
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.system:
        return Icons.settings_outlined;
    }
  }

  /// الحصول على لون حسب الأولوية
  static Color getColorForPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.urgent:
        return Colors.red;
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.medium:
        return Colors.blue;
      case NotificationPriority.low:
        return Colors.grey;
    }
  }

  /// الحصول على لون حسب النوع
  static Color getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.inventory:
        return Colors.amber.shade700;
      case NotificationType.sales:
        return Colors.green.shade600;
      case NotificationType.purchases:
        return Colors.blue.shade600;
      case NotificationType.user:
        return Colors.purple.shade600;
      case NotificationType.reminder:
        return Colors.orange.shade600;
      case NotificationType.system:
        return Colors.grey.shade600;
    }
  }
}
