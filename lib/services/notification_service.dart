// lib/services/notification_service.dart - محدث للعمل مع النماذج الموجودة
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/notifications/models/notification.dart';

class NotificationService {
  static const String _notificationsKey = 'app_notifications';
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // جلب جميع الإشعارات
  Future<List<AppNotification>> getAllNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getStringList(_notificationsKey) ?? [];

    return notificationsJson.map((json) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return AppNotification.fromMap(map);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // إضافة إشعار جديد
  Future<void> addNotification(AppNotification notification) async {
    final notifications = await getAllNotifications();
    notifications.insert(0, notification);

    // احتفظ بآخر 100 إشعار فقط
    if (notifications.length > 100) {
      notifications.removeRange(100, notifications.length);
    }

    await _saveNotifications(notifications);
  }

  // تعين إشعار كمقروء
  Future<void> markAsRead(String notificationId) async {
    final notifications = await getAllNotifications();
    final index = notifications.indexWhere((n) => n.id == notificationId);

    if (index != -1) {
      notifications[index] = notifications[index].copyWith(isRead: true);
      await _saveNotifications(notifications);
    }
  }

  // تعين جميع الإشعارات كمقروءة
  Future<void> markAllAsRead() async {
    final notifications = await getAllNotifications();
    final updatedNotifications =
        notifications.map((n) => n.copyWith(isRead: true)).toList();

    await _saveNotifications(updatedNotifications);
  }

  // حذف إشعار
  Future<void> deleteNotification(String notificationId) async {
    final notifications = await getAllNotifications();
    notifications.removeWhere((n) => n.id == notificationId);
    await _saveNotifications(notifications);
  }

  // عدد الإشعارات غير المقروءة
  Future<int> getUnreadCount() async {
    final notifications = await getAllNotifications();
    return notifications.where((n) => !n.isRead).length;
  }

  // إنشاء إشعارات تجريبية
  Future<void> generateSampleNotifications() async {
    final sampleNotifications = [
      AppNotification(
        id: _generateId(),
        title: 'مخزون منخفض ⚠️',
        body: 'منتج "باراسيتامول 500" وصل للحد الأدنى - متبقي 5 وحدات فقط',
        type: NotificationType.inventory,
        priority: NotificationPriority.high,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        actionData: jsonEncode({'productId': 'prod_001', 'currentStock': 5}),
      ),
      AppNotification(
        id: _generateId(),
        title: 'انتهاء صلاحية قريب 📅',
        body: 'منتج "أموكسيسيلين 250" ينتهي خلال 7 أيام',
        type: NotificationType.inventory,
        priority: NotificationPriority.medium,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        actionData: jsonEncode({
          'productId': 'prod_002',
          'expiryDate':
              DateTime.now().add(const Duration(days: 7)).toIso8601String()
        }),
      ),
      AppNotification(
        id: _generateId(),
        title: 'مبيعة جديدة 💰',
        body: 'تم بيع منتجات بقيمة 150,000 د.ع - فاتورة رقم #INV-001',
        type: NotificationType.sales,
        priority: NotificationPriority.medium,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        actionData: jsonEncode({'invoiceId': 'INV-001', 'amount': 150000}),
      ),
      AppNotification(
        id: _generateId(),
        title: 'مشتريات جديدة 🛒',
        body: 'تم استلام شحنة بقيمة 500,000 د.ع من شركة الأدوية المحدودة',
        type: NotificationType.purchases,
        priority: NotificationPriority.low,
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        actionData: jsonEncode({'supplierId': 'sup_001', 'amount': 500000}),
      ),
      AppNotification(
        id: _generateId(),
        title: 'نسخة احتياطية 🔧',
        body: 'تم إنشاء النسخة الاحتياطية اليومية بنجاح - حجم الملف: 2.5 MB',
        type: NotificationType.system,
        priority: NotificationPriority.low,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      AppNotification(
        id: _generateId(),
        title: 'تذكير مهم ⏰',
        body: 'حان وقت مراجعة المخزون الشهرية - تأكد من جرد جميع المنتجات',
        type: NotificationType.reminder,
        priority: NotificationPriority.medium,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        actionData: jsonEncode({
          'reminderType': 'monthly_inventory',
          'dueDate': DateTime.now().toIso8601String()
        }),
      ),
      AppNotification(
        id: _generateId(),
        title: 'مستخدم جديد 👤',
        body: 'تم إضافة مستخدم جديد: أحمد محمد - دور: موظف مبيعات',
        type: NotificationType.user,
        priority: NotificationPriority.low,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        actionData:
            jsonEncode({'userId': 'user_005', 'role': 'sales_employee'}),
      ),
    ];

    for (var notification in sampleNotifications) {
      await addNotification(notification);
    }
  }

  // إنشاء إشعار لمخزون منخفض
  Future<void> createLowStockNotification(
      String productName, int currentStock, String productId) async {
    await addNotification(
      AppNotification(
        id: _generateId(),
        title: 'تحذير: مخزون منخفض ⚠️',
        body: 'المنتج "$productName" وصل إلى $currentStock وحدة فقط',
        type: NotificationType.inventory,
        priority: currentStock < 5
            ? NotificationPriority.urgent
            : NotificationPriority.high,
        createdAt: DateTime.now(),
        actionData: jsonEncode({
          'productName': productName,
          'currentStock': currentStock,
          'productId': productId,
        }),
      ),
    );
  }

  // إنشاء إشعار لانتهاء صلاحية قريب
  Future<void> createNearExpiryNotification(
      String productName, DateTime expiryDate, String productId) async {
    final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;

    await addNotification(
      AppNotification(
        id: _generateId(),
        title: 'تحذير: انتهاء صلاحية قريب 📅',
        body: 'المنتج "$productName" ينتهي خلال $daysUntilExpiry يوم',
        type: NotificationType.inventory,
        priority: daysUntilExpiry <= 7
            ? NotificationPriority.urgent
            : NotificationPriority.high,
        createdAt: DateTime.now(),
        actionData: jsonEncode({
          'productName': productName,
          'expiryDate': expiryDate.toIso8601String(),
          'productId': productId,
          'daysUntilExpiry': daysUntilExpiry,
        }),
      ),
    );
  }

  // إنشاء إشعار مبيعات
  Future<void> createSaleNotification(double amount, String invoiceId) async {
    await addNotification(
      AppNotification(
        id: _generateId(),
        title: 'مبيعة جديدة 💰',
        body: 'تم بيع منتجات بقيمة ${amount.toInt()} د.ع - فاتورة #$invoiceId',
        type: NotificationType.sales,
        priority: amount > 100000
            ? NotificationPriority.medium
            : NotificationPriority.low,
        createdAt: DateTime.now(),
        actionData: jsonEncode({
          'amount': amount,
          'invoiceId': invoiceId,
        }),
      ),
    );
  }

  // إنشاء إشعار نسخة احتياطية
  Future<void> createBackupNotification(bool success, {String? error}) async {
    await addNotification(
      AppNotification(
        id: _generateId(),
        title: success ? 'نسخة احتياطية 🔧' : 'فشل النسخة الاحتياطية ❌',
        body: success
            ? 'تم إنشاء النسخة الاحتياطية بنجاح'
            : 'فشل في إنشاء النسخة الاحتياطية: ${error ?? "خطأ غير معروف"}',
        type: NotificationType.system,
        priority:
            success ? NotificationPriority.low : NotificationPriority.high,
        createdAt: DateTime.now(),
        actionData: success ? null : jsonEncode({'error': error}),
      ),
    );
  }

  Future<void> _saveNotifications(List<AppNotification> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson =
        notifications.map((n) => jsonEncode(n.toMap())).toList();

    await prefs.setStringList(_notificationsKey, notificationsJson);
  }

  String _generateId() {
    return 'notif_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }
}
