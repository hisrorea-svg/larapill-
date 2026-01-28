// lib/core/navigation/notification_router.dart
// 🔔 نظام التوجيه الذكي للإشعارات

import 'package:flutter/material.dart';
import '../../features/notifications/domain/entities/notification_entity.dart';
import '../../features/notifications/domain/entities/notification_type.dart';
import '../../features/notifications/domain/entities/notification_priority.dart';

/// يوجه المستخدم للصفحة المناسبة حسب نوع الإشعار
class NotificationRouter {
  /// التوجيه حسب نوع الإشعار
  static void navigate(BuildContext context, NotificationEntity notification) {
    final actionData = notification.actionData;

    switch (notification.type) {
      case NotificationType.inventory:
        _navigateToInventory(context, actionData);
        break;

      case NotificationType.sales:
        _navigateToSales(context, actionData);
        break;

      case NotificationType.purchases:
        _navigateToPurchases(context, actionData);
        break;

      case NotificationType.user:
        _navigateToUsers(context, actionData);
        break;

      case NotificationType.reminder:
        _navigateToReminder(context, actionData);
        break;

      case NotificationType.system:
        _navigateToSystem(context, actionData);
        break;
    }
  }

  /// التوجيه لصفحة المخزون
  static void _navigateToInventory(
      BuildContext context, Map<String, dynamic>? data) {
    if (data != null && data.containsKey('productId')) {
      // فتح تفاصيل المنتج
      Navigator.pushNamed(
        context,
        '/inventory/product',
        arguments: {'productId': data['productId']},
      );
    } else {
      // فتح صفحة المخزون العامة
      Navigator.pushNamed(context, '/inventory');
    }
  }

  /// التوجيه لصفحة المبيعات
  static void _navigateToSales(
      BuildContext context, Map<String, dynamic>? data) {
    if (data != null && data.containsKey('invoiceId')) {
      // فتح تفاصيل الفاتورة
      Navigator.pushNamed(
        context,
        '/pos/invoice',
        arguments: {'invoiceId': data['invoiceId']},
      );
    } else {
      // فتح نقطة البيع
      Navigator.pushNamed(context, '/pos');
    }
  }

  /// التوجيه لصفحة المشتريات
  static void _navigateToPurchases(
      BuildContext context, Map<String, dynamic>? data) {
    Navigator.pushNamed(context, '/purchases');
  }

  /// التوجيه لصفحة المستخدمين
  static void _navigateToUsers(
      BuildContext context, Map<String, dynamic>? data) {
    Navigator.pushNamed(context, '/users');
  }

  /// التوجيه للتذكيرات
  static void _navigateToReminder(
      BuildContext context, Map<String, dynamic>? data) {
    // يمكن فتح صفحة التذكيرات أو الإعدادات
    Navigator.pushNamed(context, '/settings');
  }

  /// التوجيه لإعدادات النظام
  static void _navigateToSystem(
      BuildContext context, Map<String, dynamic>? data) {
    Navigator.pushNamed(context, '/settings');
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
