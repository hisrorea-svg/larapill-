import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import '../database/database_helper.dart';
import '../services/notification_service.dart';
import '../features/notifications/models/notification.dart';

/// خدمة الإشعارات الذكية - تراقب الأحداث وتنشئ إشعارات تلقائياً
class SmartNotificationService {
  static final SmartNotificationService _instance =
      SmartNotificationService._internal();
  factory SmartNotificationService() => _instance;
  SmartNotificationService._internal();

  final NotificationService _notificationService = NotificationService();
  final DatabaseHelper _db = DatabaseHelper();

  Timer? _monitoringTimer;

  /// بدء مراقبة الأحداث
  void startMonitoring() {
    developer.log('🔔 بدء مراقبة الأحداث للإشعارات الذكية',
        name: 'SmartNotification');

    // فحص فوري عند البدء
    _checkAllEvents();

    // فحص دوري كل 5 دقائق
    _monitoringTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _checkAllEvents(),
    );
  }

  /// إيقاف المراقبة
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    developer.log('🔕 إيقاف مراقبة الإشعارات', name: 'SmartNotification');
  }

  /// فحص جميع الأحداث
  Future<void> _checkAllEvents() async {
    try {
      developer.log('🔍 فحص الأحداث...', name: 'SmartNotification');

      await Future.wait([
        _checkLowStockProducts(),
        _checkExpiringProducts(),
        _checkRecentSales(),
      ]);
    } catch (e) {
      developer.log('❌ خطأ في فحص الأحداث: $e', name: 'SmartNotification');
    }
  }

  /// 1️⃣ مراقبة المنتجات منخفضة المخزون
  Future<void> _checkLowStockProducts() async {
    try {
      final db = await _db.database;

      // جلب المنتجات التي وصلت للحد الأدنى أو أقل
      final result = await db.rawQuery('''
        SELECT p.id, p.name, p.current_stock, p.min_stock_level, p.base_unit
        FROM products p
        WHERE p.is_active = 1 
          AND p.current_stock <= p.min_stock_level
          AND p.min_stock_level > 0
        ORDER BY (p.current_stock / NULLIF(p.min_stock_level, 0)) ASC
        LIMIT 10
      ''');

      for (var product in result) {
        final productId = product['id'] as String;
        final productName = product['name'] as String;
        final currentStock = (product['current_stock'] as num).toDouble();
        final minStock = (product['min_stock_level'] as num).toDouble();
        final baseUnit = product['base_unit'] as String;

        // تحقق إذا لم يتم إرسال إشعار لهذا المنتج اليوم
        if (!await _wasNotifiedToday('low_stock_$productId')) {
          final priority = currentStock == 0
              ? NotificationPriority.urgent
              : currentStock < minStock / 2
                  ? NotificationPriority.high
                  : NotificationPriority.medium;

          final body = currentStock == 0
              ? 'المنتج "$productName" نفذ من المخزون! الحد الأدنى: ${minStock.toInt()} $baseUnit'
              : 'المنتج "$productName" وصل للحد الأدنى - متبقي ${currentStock.toInt()} $baseUnit (الحد الأدنى: ${minStock.toInt()})';

          await _notificationService.addNotification(
            AppNotification(
              id: 'low_stock_${productId}_${DateTime.now().millisecondsSinceEpoch}',
              title: currentStock == 0 ? '⚠️ نفاذ مخزون' : '📉 مخزون منخفض',
              body: body,
              type: NotificationType.inventory,
              priority: priority,
              createdAt: DateTime.now(),
              actionData: jsonEncode({
                'type': 'low_stock',
                'productId': productId,
                'currentStock': currentStock,
                'minStock': minStock,
              }),
            ),
          );

          await _markAsNotified('low_stock_$productId');
          developer.log('📦 إشعار مخزون منخفض: $productName',
              name: 'SmartNotification');
        }
      }
    } catch (e) {
      developer.log('❌ خطأ في فحص المخزون المنخفض: $e',
          name: 'SmartNotification');
    }
  }

  /// 2️⃣ مراقبة المنتجات قريبة الصلاحية
  Future<void> _checkExpiringProducts() async {
    try {
      final db = await _db.database;
      final now = DateTime.now();
      final warningDate = now.add(const Duration(days: 30)); // تحذير قبل 30 يوم

      final result = await db.rawQuery('''
        SELECT p.id, p.name, p.expiry_date, p.current_stock
        FROM products p
        WHERE p.is_active = 1 
          AND p.expiry_date IS NOT NULL
          AND p.expiry_date <= ?
          AND p.current_stock > 0
        ORDER BY p.expiry_date ASC
        LIMIT 10
      ''', [warningDate.toIso8601String()]);

      for (var product in result) {
        final productId = product['id'] as String;
        final productName = product['name'] as String;
        final expiryDateStr = product['expiry_date'] as String;
        final expiryDate = DateTime.parse(expiryDateStr);
        final stock = (product['current_stock'] as num).toDouble();

        final daysUntilExpiry = expiryDate.difference(now).inDays;

        // تحديد الأولوية حسب الأيام المتبقية
        final priority = daysUntilExpiry <= 0
            ? NotificationPriority.urgent
            : daysUntilExpiry <= 7
                ? NotificationPriority.high
                : daysUntilExpiry <= 14
                    ? NotificationPriority.medium
                    : NotificationPriority.low;

        // إرسال إشعار حسب الفترة
        final notificationKey =
            'expiry_${productId}_${daysUntilExpiry <= 7 ? 'urgent' : 'warning'}';

        if (!await _wasNotifiedToday(notificationKey)) {
          final body = daysUntilExpiry <= 0
              ? 'المنتج "$productName" انتهت صلاحيته! المخزون: ${stock.toInt()} وحدة'
              : daysUntilExpiry == 1
                  ? 'المنتج "$productName" ينتهي غداً! المخزون: ${stock.toInt()} وحدة'
                  : 'المنتج "$productName" ينتهي خلال $daysUntilExpiry يوم - المخزون: ${stock.toInt()}';

          await _notificationService.addNotification(
            AppNotification(
              id: 'expiry_${productId}_${DateTime.now().millisecondsSinceEpoch}',
              title: daysUntilExpiry <= 0
                  ? '🚫 منتج منتهي الصلاحية'
                  : '📅 انتهاء صلاحية قريب',
              body: body,
              type: NotificationType.inventory,
              priority: priority,
              createdAt: DateTime.now(),
              actionData: jsonEncode({
                'type': 'expiring',
                'productId': productId,
                'expiryDate': expiryDateStr,
                'daysRemaining': daysUntilExpiry,
                'stock': stock,
              }),
            ),
          );

          await _markAsNotified(notificationKey);
          developer.log(
              '📅 إشعار انتهاء صلاحية: $productName ($daysUntilExpiry يوم)',
              name: 'SmartNotification');
        }
      }
    } catch (e) {
      developer.log('❌ خطأ في فحص الصلاحية: $e', name: 'SmartNotification');
    }
  }

  /// 3️⃣ مراقبة المبيعات الحديثة
  Future<void> _checkRecentSales() async {
    try {
      final db = await _db.database;

      // جلب المبيعات في آخر 5 دقائق
      final fiveMinutesAgo =
          DateTime.now().subtract(const Duration(minutes: 5));

      final result = await db.rawQuery('''
        SELECT s.id, s.total, s.created_at, s.invoice_number
        FROM sales s
        WHERE s.created_at >= ?
        ORDER BY s.created_at DESC
        LIMIT 5
      ''', [fiveMinutesAgo.toIso8601String()]);

      for (var sale in result) {
        final saleId = sale['id'] as String;
        final totalAmount = (sale['total'] as num).toDouble();
        final invoiceNumber = sale['invoice_number'] as String;

        // تحقق إذا لم يتم إرسال إشعار لهذه المبيعة
        if (!await _wasNotifiedEver('sale_$saleId')) {
          final priority = totalAmount >= 100000
              ? NotificationPriority.high
              : NotificationPriority.medium;

          await _notificationService.addNotification(
            AppNotification(
              id: 'sale_${saleId}_${DateTime.now().millisecondsSinceEpoch}',
              title:
                  totalAmount >= 100000 ? '💰 مبيعة كبيرة!' : '✅ مبيعة جديدة',
              body:
                  'تم بيع منتجات بقيمة ${totalAmount.toStringAsFixed(0)} د.ع - فاتورة #$invoiceNumber',
              type: NotificationType.sales,
              priority: priority,
              createdAt: DateTime.now(),
              actionData: jsonEncode({
                'type': 'new_sale',
                'saleId': saleId,
                'invoiceNumber': invoiceNumber,
                'totalAmount': totalAmount,
              }),
            ),
          );

          await _markAsNotified('sale_$saleId');
          developer.log(
              '💰 إشعار مبيعة: $invoiceNumber (${totalAmount.toStringAsFixed(0)} د.ع)',
              name: 'SmartNotification');
        }
      }
    } catch (e) {
      developer.log('❌ خطأ في فحص المبيعات: $e', name: 'SmartNotification');
    }
  }

  /// فحص إذا تم الإشعار اليوم
  Future<bool> _wasNotifiedToday(String key) async {
    try {
      final db = await _db.database;
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final result = await db.rawQuery('''
        SELECT COUNT(*) as count
        FROM notification_tracking
        WHERE notification_key = ?
          AND created_at >= ?
      ''', [key, startOfDay.toIso8601String()]);

      final count = result.first['count'] as int;
      return count > 0;
    } catch (e) {
      // إذا الجدول غير موجود، نفترض أنه لم يتم الإشعار
      return false;
    }
  }

  /// فحص إذا تم الإشعار مطلقاً
  Future<bool> _wasNotifiedEver(String key) async {
    try {
      final db = await _db.database;

      final result = await db.rawQuery('''
        SELECT COUNT(*) as count
        FROM notification_tracking
        WHERE notification_key = ?
      ''', [key]);

      final count = result.first['count'] as int;
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  /// تسجيل أنه تم الإشعار
  Future<void> _markAsNotified(String key) async {
    try {
      final db = await _db.database;

      // إنشاء الجدول إذا لم يكن موجوداً
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notification_tracking (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          notification_key TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');

      await db.insert('notification_tracking', {
        'notification_key': key,
        'created_at': DateTime.now().toIso8601String(),
      });

      // تنظيف السجلات القديمة (أكثر من 30 يوم)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      await db.delete(
        'notification_tracking',
        where: 'created_at < ?',
        whereArgs: [thirtyDaysAgo.toIso8601String()],
      );
    } catch (e) {
      developer.log('❌ خطأ في تسجيل الإشعار: $e', name: 'SmartNotification');
    }
  }

  /// إنشاء إشعار مباشر للحدث
  Future<void> notifyEvent({
    required String title,
    required String body,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.medium,
    Map<String, dynamic>? actionData,
  }) async {
    try {
      await _notificationService.addNotification(
        AppNotification(
          id: 'event_${DateTime.now().millisecondsSinceEpoch}',
          title: title,
          body: body,
          type: type,
          priority: priority,
          createdAt: DateTime.now(),
          actionData: actionData != null ? jsonEncode(actionData) : null,
        ),
      );

      developer.log('🔔 إشعار: $title', name: 'SmartNotification');
    } catch (e) {
      developer.log('❌ خطأ في إنشاء الإشعار: $e', name: 'SmartNotification');
    }
  }

  /// مسح جميع الإشعارات القديمة (أكثر من 30 يوم)
  Future<void> cleanupOldNotifications() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final notifications = await _notificationService.getAllNotifications();

      int deletedCount = 0;
      for (var notification in notifications) {
        if (notification.createdAt.isBefore(thirtyDaysAgo)) {
          await _notificationService.deleteNotification(notification.id);
          deletedCount++;
        }
      }

      if (deletedCount > 0) {
        developer.log('🗑️ تم حذف $deletedCount إشعار قديم',
            name: 'SmartNotification');
      }
    } catch (e) {
      developer.log('❌ خطأ في تنظيف الإشعارات: $e', name: 'SmartNotification');
    }
  }
}
