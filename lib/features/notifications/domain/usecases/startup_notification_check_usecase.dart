import 'dart:developer' as developer;
import '../../../../features/inventory/data/repositories/product_repository.dart';
import 'create_low_stock_notification_usecase.dart';
import 'create_near_expiry_notification_usecase.dart';

/// UseCase: فحص الإشعارات عند بدء التطبيق
/// يقوم بفحص المخزون المنخفض والصلاحيات القريبة وإنشاء إشعارات تلقائياً
class StartupNotificationCheckUseCase {
  final ProductRepository _productRepository;
  final CreateLowStockNotificationUseCase _createLowStockNotification;
  final CreateNearExpiryNotificationUseCase _createNearExpiryNotification;

  const StartupNotificationCheckUseCase({
    required ProductRepository productRepository,
    required CreateLowStockNotificationUseCase createLowStockNotification,
    required CreateNearExpiryNotificationUseCase createNearExpiryNotification,
  })  : _productRepository = productRepository,
        _createLowStockNotification = createLowStockNotification,
        _createNearExpiryNotification = createNearExpiryNotification;

  /// تنفيذ الفحص الشامل
  Future<NotificationCheckResult> call() async {
    developer.log('🔔 بدء فحص الإشعارات التلقائي...',
        name: 'NotificationCheck');

    int lowStockCount = 0;
    int nearExpiryCount = 0;

    try {
      // 1. فحص المخزون المنخفض
      final lowStockProducts = await _productRepository.getLowStockProducts();
      for (final product in lowStockProducts) {
        try {
          await _createLowStockNotification(
            productName: product.name,
            currentStock: product.currentStock.toInt(),
            productId: product.id,
          );
          lowStockCount++;
        } catch (e) {
          developer.log('⚠️ خطأ في إنشاء إشعار مخزون: $e',
              name: 'NotificationCheck');
        }
      }

      // 2. فحص الصلاحيات القريبة (30 يوم)
      final expiringProducts =
          await _productRepository.getExpiringProducts(daysThreshold: 30);
      for (final product in expiringProducts) {
        if (product.expiryDate != null) {
          try {
            await _createNearExpiryNotification(
              productName: product.name,
              expiryDate: product.expiryDate!,
              productId: product.id,
            );
            nearExpiryCount++;
          } catch (e) {
            developer.log('⚠️ خطأ في إنشاء إشعار صلاحية: $e',
                name: 'NotificationCheck');
          }
        }
      }

      developer.log(
        '✅ تم إنشاء $lowStockCount إشعار مخزون و $nearExpiryCount إشعار صلاحية',
        name: 'NotificationCheck',
      );

      return NotificationCheckResult(
        lowStockNotifications: lowStockCount,
        nearExpiryNotifications: nearExpiryCount,
        success: true,
      );
    } catch (e) {
      developer.log('❌ خطأ في فحص الإشعارات: $e', name: 'NotificationCheck');
      return NotificationCheckResult(
        lowStockNotifications: lowStockCount,
        nearExpiryNotifications: nearExpiryCount,
        success: false,
        error: e.toString(),
      );
    }
  }
}

/// نتيجة فحص الإشعارات
class NotificationCheckResult {
  final int lowStockNotifications;
  final int nearExpiryNotifications;
  final bool success;
  final String? error;

  const NotificationCheckResult({
    required this.lowStockNotifications,
    required this.nearExpiryNotifications,
    required this.success,
    this.error,
  });

  int get totalNotifications => lowStockNotifications + nearExpiryNotifications;
}
