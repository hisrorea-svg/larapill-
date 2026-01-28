import 'dart:math';
import '../entities/notification_entity.dart';
import '../entities/notification_type.dart';
import '../entities/notification_priority.dart';
import '../repositories/notification_repository.dart';

/// UseCase: إنشاء إشعار مخزون منخفض
class CreateLowStockNotificationUseCase {
  final NotificationRepository _repository;

  const CreateLowStockNotificationUseCase(this._repository);

  /// تنفيذ UseCase
  Future<void> call({
    required String productName,
    required int currentStock,
    required String productId,
  }) async {
    // التحقق من الصحة
    if (productName.isEmpty) {
      throw ArgumentError('Product name cannot be empty');
    }
    if (currentStock < 0) {
      throw ArgumentError('Current stock cannot be negative');
    }
    if (productId.isEmpty) {
      throw ArgumentError('Product ID cannot be empty');
    }

    // قاعدة العمل: تحديد الأولوية بناءً على المخزون
    final priority = _determinePriority(currentStock);

    // إنشاء الإشعار
    final notification = NotificationEntity(
      id: _generateId(),
      title: 'تحذير: مخزون منخفض ⚠️',
      body: 'المنتج "$productName" وصل إلى $currentStock وحدة فقط',
      type: NotificationType.inventory,
      priority: priority,
      createdAt: DateTime.now(),
      actionData: {
        'productName': productName,
        'currentStock': currentStock,
        'productId': productId,
      },
    );

    await _repository.add(notification);
  }

  /// قاعدة العمل: تحديد الأولوية
  NotificationPriority _determinePriority(int stock) {
    if (stock < 5) return NotificationPriority.urgent;
    if (stock < 10) return NotificationPriority.high;
    return NotificationPriority.medium;
  }

  String _generateId() {
    return 'notif_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }
}
